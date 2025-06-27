// src/iOSApp/Sources/iOSAppSource/Views/LaunchView.swift
import SwiftUI
import iOSAppSource

public struct LaunchView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    public init() {}

    public var body: some View {
        ZStack {
            // While the authentication state is being determined, show a loading view.
            if authViewModel.isLoading {
                // A simple loading screen with the app logo and a progress indicator.
                VStack(spacing: 20) {
                    Image("Logo", bundle: .main) // Assuming Logo is in your main app assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                    ProgressView()
                }
            } else if authViewModel.isAuthenticated {
                // Once loading is complete and the user is authenticated, show the main app.
                MainTabView()
            } else {
                // If loading is complete and the user is not authenticated, show the login wall.
                LoginWallView()
            }
        }
        .onAppear {
            // This ensures the check is triggered if it hasn't started.
            // The logic is in AuthenticationViewModel's init.
        }
    }
}


private struct LoginWallView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                
                Spacer()
                
                // Logo
                Image("Logo", bundle: .main)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)

                // Prompt and Button
                VStack(spacing: 20) {
                    Text("launch.login.prompt", bundle: .module)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
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