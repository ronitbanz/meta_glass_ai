//
//  ContentView.swift
//  MyApplication
//
//  Created by Ronit Banze on 2026-04-08.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var model: WearablesViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Meta AI Glasses OCR")
                    .font(.title2)
                    .bold()

                previewSection

                statusSection

                controlSection

                capturedPhotoSection

                textSection

                if !model.lastError.isEmpty {
                    Text(model.lastError)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
            .padding()
        }
        .onAppear {
            model.startObserving()
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live Preview")
                .font(.headline)

            if let image = model.previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.15))
                    .frame(height: 220)
                    .overlay(
                        Text("No stream yet")
                            .foregroundStyle(.secondary)
                    )
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)

            Text("Registration: \(model.registrationStateText)")
            Text("Devices: \(model.devicesText)")
            Text("Camera permission: \(model.permissionText)")
            Text("Stream: \(model.streamStateText)")
        }
    }

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Controls")
                .font(.headline)

            if model.deviceCount() > 0 {
                Picker("Device", selection: $model.selectedDeviceIndex) {
                    Text("Auto").tag(-1)
                    ForEach(0..<model.deviceCount(), id: \.self) { index in
                        Text(model.deviceDisplayName(for: index)).tag(index)
                    }
                }
                .pickerStyle(.menu)
            } else {
                Text("Device: Auto")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Register") {
                    model.startRegistration()
                }

                Button("Unregister") {
                    model.startUnregistration()
                }
            }

            HStack {
                Button("Request Camera Permission") {
                    model.requestCameraPermission()
                }
            }

            HStack {
                Button("Start Stream") {
                    model.startStreaming()
                }

                Button("Stop Stream") {
                    model.stopStreaming()
                }
            }

            HStack {
                Button("Capture Photo") {
                    model.capturePhoto()
                }

                Button("Save Photo") {
                    model.saveCapturedPhotoToLibrary()
                }
            }

            if !model.photoStatusText.isEmpty {
                Text(model.photoStatusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Detected Text")
                .font(.headline)

            if model.recognizedText.isEmpty {
                Text("No text detected yet.")
                    .foregroundStyle(.secondary)
            } else {
                Text(model.recognizedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var capturedPhotoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Captured Photo")
                .font(.headline)

            if let image = model.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.1))
                    .frame(height: 160)
                    .overlay(
                        Text("No photo yet")
                            .foregroundStyle(.secondary)
                    )
            }
        }
    }
}

#Preview {
    ContentView(model: WearablesViewModel())
}
