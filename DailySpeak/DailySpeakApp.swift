//
//  DailySpeakApp.swift
//  DailySpeak
//
//  Created by levi on 2026/2/28.
//

import SwiftUI

@main
struct DailySpeakApp: App {
    @State private var progressManager = ProgressManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(progressManager)
        }
    }
}
