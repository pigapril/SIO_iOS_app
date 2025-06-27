// src/Sentiment Inside Out/Sentiment Inside Out/StockAppApp.swift
import SwiftUI
import iOSAppSource
import Firebase

// +++ START OF FIX: Add a new AppDelegate class +++
// Create a class that conforms to NSObject and UIApplicationDelegate.
class AppDelegate: NSObject, UIApplicationDelegate {
    // This method is required by Firebase for a clean integration.
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // The AppSetupService.configure() call can remain in the App's init,
        // as it's called even before this delegate method.
        // This delegate is primarily for the SDKs to hook into the lifecycle.
        return true
    }
}
// +++ END OF FIX +++


@main
struct StockAppApp: App {
    // +++ START OF FIX: Add the UIApplicationDelegateAdaptor +++
    // This connects the AppDelegate to your SwiftUI App's lifecycle.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    // +++ END OF FIX +++
    
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var toastManager = ToastManager.shared

    init() {
        AppSetupService.configure()
    }

    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environmentObject(authViewModel)
                .environmentObject(toastManager)
        }
    }
}