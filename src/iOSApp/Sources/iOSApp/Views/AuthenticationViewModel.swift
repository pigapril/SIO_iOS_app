import Foundation
import Combine

@MainActor
// highlight-next-line
public class AuthenticationViewModel: ObservableObject {
    @Published public var user: User?
    @Published public var isAuthenticated: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?

    private let apiService = APIService.shared
    private let googleSignInService = GoogleSignInService.shared

    // highlight-next-line
    public init() {
        // Attempt to restore a previous sign-in when the app starts
        Task {
            await restorePreviousSignIn()
        }
    }
    
    public func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            let gidUser = try await googleSignInService.signIn()
            guard let idToken = gidUser.idToken?.tokenString else {
                throw AppError.googleAuthCancelled
            }
            let backendUser = try await apiService.verifyGoogleToken(idToken: idToken)
            self.user = backendUser
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAuthenticated = false
            ErrorHandler.handle(error: error, component: "AuthenticationViewModel.signIn")
        }
        isLoading = false
    }

    public func signOut() async {
        isLoading = true
        googleSignInService.signOut()
        do {
            try await apiService.logout()
        } catch {
            // Handle backend logout error if necessary, but proceed with UI update
            ErrorHandler.handle(error: error, component: "AuthenticationViewModel.signOut")
        }
        self.user = nil
        self.isAuthenticated = false
        isLoading = false
    }
    
    public func restorePreviousSignIn() async {
        isLoading = true
        if let _ = await googleSignInService.restorePreviousSignIn() {
            // If Google SDK finds a user, verify with our backend
            do {
                let backendUser = try await apiService.checkAuthStatus()
                self.user = backendUser
                self.isAuthenticated = true
            } catch {
                // If backend check fails, sign out completely
                await signOut()
            }
        }
        isLoading = false
    }
}