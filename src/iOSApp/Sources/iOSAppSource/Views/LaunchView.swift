// src/iOSApp/Sources/iOSAppSource/Views/LaunchView.swift
import SwiftUI
public struct LaunchView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var dashboardViewModel: DashboardViewModel // Receive from environment
    
    @StateObject private var paymentService = PaymentService.shared

    public init() {}

    public var body: some View {
        ZStack {
            if authViewModel.isLoading {
                loadingView(textKey: "launch.loading.authenticating")
            } else if !authViewModel.isAuthenticated {
                LoginWallView()
            } else {
                // User is authenticated, proceed with subscription and preload checks
                if paymentService.isLoading && PaymentService.isPaywallEnabled {
                    loadingView(textKey: "launch.loading.authenticating")
                } else if PaymentService.isPaywallEnabled && !paymentService.isSubscribed {
                    PaywallView()
                } else {
                    // User is authenticated and subscribed (or paywall is disabled).
                    // Now, handle the preloading logic.
                    switch dashboardViewModel.preloadState {
                    case .idle:
                        loadingView(textKey: "launch.loading.preparing")
                            .onAppear {
                                // Preload with an 8-second timeout.
                                dashboardViewModel.preloadWatchlistPreview(withTimeout: 8.0)
                            }
                    case .loading:
                        loadingView(textKey: "launch.loading.preparing")
                    case .loaded, .timedOut:
                        // Proceed to the main app on success or timeout.
                        MainTabView()
                    }
                }
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                paymentService.checkSubscriptionStatus()
            } else {
                // On logout, reset all relevant states.
                // A reset function for PaymentService will be added.
                dashboardViewModel.resetPreloadState()
            }
        }
    }
    
    /// A reusable loading view with customizable text.
    private func loadingView(textKey: String) -> some View {
        VStack(spacing: 20) {
            Image("Logo", bundle: .main)
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
            ProgressView()
            Text(textKey.localized())
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }
}
private struct LoginWallView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 40) {
                Spacer()
                Image("Logo", bundle: .main)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                VStack(spacing: 20) {
                    Text("launch.login.prompt".localized())
                        .font(.headline)
                        .foregroundColor(.secondary)
                    SignInWithAppleButtonView(type: .signIn, style: .black) { result in
                        authViewModel.handleAppleSignInResult(result)
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 40)
                    GoogleSignInButtonView(colorScheme: .dark) {
                        Task {
                            await authViewModel.signIn()
                        }
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 40)
                }
                Spacer()
                Spacer()
            }
        }
    }
}