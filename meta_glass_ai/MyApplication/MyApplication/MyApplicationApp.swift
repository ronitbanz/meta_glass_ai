//
//  MyApplicationApp.swift
//  MyApplication
//
//  Created by Ronit Banze on 2026-04-08.
//

import SwiftUI
import MWDATCore

@main
struct MyApplicationApp: App {
    @StateObject private var model = WearablesViewModel()

    init() {
        do {
            try Wearables.configure()
        } catch {
            assertionFailure("Failed to configure Wearables SDK: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onOpenURL { url in
                    Task {
                        await model.handleWearablesCallback(url)
                    }
                }
        }
    }
}
