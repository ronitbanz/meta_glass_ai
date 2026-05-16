import Foundation
import SwiftUI
import Vision
import Combine
import Photos
import MWDATCamera
import MWDATCore

@MainActor
final class WearablesViewModel: ObservableObject {
    @Published var registrationStateText: String = "Not registered"
    @Published var devicesText: String = "No devices"
    @Published var permissionText: String = "Unknown"
    @Published var streamStateText: String = "Stopped"
    @Published var recognizedText: String = ""
    @Published var previewImage: UIImage?
    @Published var capturedImage: UIImage?
    @Published var photoStatusText: String = ""
    @Published var lastError: String = ""
    @Published var selectedDeviceIndex: Int = -1

    private let wearables = Wearables.shared
    private var streamSession: StreamSession?
    private var stateToken: Any?
    private var frameToken: Any?
    private var photoToken: Any?
    private var isObserving = false

    private var isRecognizing = false
    private var lastRecognitionTime = Date.distantPast
    private var devices: [DeviceIdentifier] = []

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        Task {
            for await state in wearables.registrationStateStream() {
                registrationStateText = String(describing: state)
            }
        }

        Task {
            for await devices in wearables.devicesStream() {
                self.devices = devices
                if devices.isEmpty {
                    devicesText = "No devices"
                } else {
                    devicesText = "Devices: \(devices.count)"
                }
            }
        }
    }

    func startRegistration() {
        Task {
            do {
                try await wearables.startRegistration()
            } catch {
                lastError = "Registration failed: \(error)"
            }
        }
    }

    func startUnregistration() {
        Task {
            do {
                try await wearables.startUnregistration()
            } catch {
                lastError = "Unregistration failed: \(error)"
            }
        }
    }

    func handleWearablesCallback(_ url: URL) async {
        do {
            _ = try await wearables.handleUrl(url)
        } catch {
            lastError = "Callback handling failed: \(error)"
        }
    }

    func requestCameraPermission() {
        Task {
            do {
                let current = try await wearables.checkPermissionStatus(.camera)
                if current == .granted {
                    permissionText = "Granted"
                    return
                }

                let updated = try await wearables.requestPermission(.camera)
                permissionText = statusText(updated)
            } catch {
                lastError = "Permission failed: \(error)"
            }
        }
    }

    func startStreaming() {
        let deviceSelector: DeviceSelector
        if let selectedDevice = selectedDevice {
            deviceSelector = SpecificDeviceSelector(device: selectedDevice)
        } else {
            deviceSelector = AutoDeviceSelector(wearables: wearables)
        }
        let config = StreamSessionConfig(
            videoCodec: VideoCodec.raw,
            resolution: StreamingResolution.low,
            frameRate: 24
        )

        let session = StreamSession(streamSessionConfig: config, deviceSelector: deviceSelector)
        streamSession = session

        stateToken = session.statePublisher.listen { [weak self] state in
            Task { @MainActor [weak self] in
                self?.streamStateText = String(describing: state)
            }
        }

        frameToken = session.videoFramePublisher.listen { [weak self] frame in
            guard let image = frame.makeUIImage() else { return }
            Task { @MainActor [weak self] in
                self?.previewImage = image
                self?.scheduleTextRecognition(from: image)
            }
        }

        photoToken = session.photoDataPublisher.listen { [weak self] photoData in
            guard let image = UIImage(data: photoData.data) else { return }
            Task { @MainActor [weak self] in
                self?.capturedImage = image
                self?.photoStatusText = "Captured"
            }
        }

        Task {
            await session.start()
        }
    }

    func stopStreaming() {
        guard let session = streamSession else { return }
        Task {
            await session.stop()
        }
    }

    func capturePhoto() {
        guard let session = streamSession else {
            photoStatusText = "Start a stream first."
            return
        }

        session.capturePhoto(format: .jpeg)
    }

    func saveCapturedPhotoToLibrary() {
        Task {
            await saveCapturedPhotoToLibraryAsync()
        }
    }

    private func scheduleTextRecognition(from image: UIImage) {
        let now = Date()
        guard !isRecognizing else { return }
        guard now.timeIntervalSince(lastRecognitionTime) > 0.6 else { return }
        guard let cgImage = image.cgImage else { return }

        isRecognizing = true
        lastRecognitionTime = now

        Task.detached {
            let recognized = Self.recognizeText(from: cgImage)
            await MainActor.run {
                self.recognizedText = recognized
                self.isRecognizing = false
            }
        }
    }

    private nonisolated static func recognizeText(from cgImage: CGImage) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return "Text recognition failed: \(error)"
        }

        guard let observations = request.results else { return "" }
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        return lines.joined(separator: "\n")
    }

    private func statusText(_ status: PermissionStatus) -> String {
        switch status {
        case .granted:
            return "Granted"
        case .denied:
            return "Denied"
        @unknown default:
            return "Unknown"
        }
    }

    private var selectedDevice: DeviceIdentifier? {
        guard selectedDeviceIndex >= 0, selectedDeviceIndex < devices.count else { return nil }
        return devices[selectedDeviceIndex]
    }

    func deviceDisplayName(for index: Int) -> String {
        guard index >= 0, index < devices.count else { return "Unknown" }
        return String(describing: devices[index])
    }

    func deviceCount() -> Int {
        devices.count
    }

    private func saveCapturedPhotoToLibraryAsync() async {
        guard let image = capturedImage else {
            photoStatusText = "No photo to save."
            return
        }

        let status = await requestPhotoLibraryAuthorization()
        guard status == .authorized || status == .limited else {
            photoStatusText = "Photo library permission denied."
            return
        }

        let result = await savePhotoToLibrary(image)
        switch result {
        case .success:
            photoStatusText = "Saved to Photos."
        case .failure(let error):
            photoStatusText = "Save failed: \(error)"
        }
    }

    private func requestPhotoLibraryAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func savePhotoToLibrary(_ image: UIImage) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(returning: .failure(error))
                } else if success {
                    continuation.resume(returning: .success(()))
                } else {
                    continuation.resume(returning: .failure(NSError(domain: "PhotoSave", code: -1)))
                }
            }
        }
    }
}
