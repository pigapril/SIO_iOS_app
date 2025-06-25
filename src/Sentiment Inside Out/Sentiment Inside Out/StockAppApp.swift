// src/Sentiment Inside Out/Sentiment Inside Out/StockAppApp.swift
import SwiftUI
import iOSAppSource
// highlight-next-line
import Firebase // Make sure to import Firebase to access configuration options

@main
struct StockAppApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var toastManager = ToastManager.shared

    // highlight-start
    // Add an init() method to perform one-time setup when the app launches.
    init() {
        // Call the configuration service to set up Firebase and Google Sign-In.
        AppSetupService.configure()
    }
    // highlight-end

    var body: some Scene {
        WindowGroup {
            // The LaunchView remains the root view as intended.
            LaunchView()
                .environmentObject(authViewModel)
                .environmentObject(toastManager)
        }
    }
}