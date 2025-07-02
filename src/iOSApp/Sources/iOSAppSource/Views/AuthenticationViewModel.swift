// AuthenticationViewModel.swift (完整修正版)

import Foundation
import Combine
import AuthenticationServices


@MainActor
public class AuthenticationViewModel: ObservableObject {
    @Published public var user: User?
    @Published public var isAuthenticated: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?

    private let apiService = APIService.shared
    private let googleSignInService = GoogleSignInService.shared

    public init() {
        // Attempt to restore a previous sign-in when the app starts
        Task {
            await restorePreviousSignIn()
        }
    }
    
    // signIn, signOut, restorePreviousSignIn 函式維持不變...
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


    public func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Failed to get Apple ID Credential."
                isLoading = false
                return
            }
            
            let userID = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            guard let identityTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8) else {
                errorMessage = "Failed to get identity token."
                isLoading = false
                return
            }

            // 將 token 和其他資訊傳送到您的後端進行驗證
            Task {
                // highlight-start
                // 修正 #1: 將 userID 作為參數傳遞
                await verifyAppleToken(idToken: idToken, userID: userID, fullName: fullName, email: email)
                // highlight-end
            }
            
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                print("Apple Sign In cancelled by user.")
                isLoading = false
                return
            }
            self.errorMessage = error.localizedDescription
            self.isAuthenticated = false
            ErrorHandler.handle(error: error, component: "AuthenticationViewModel.handleAppleSignInResult")
            isLoading = false
        }
    }
    
    // highlight-start
    // 修正 #2: 修改函式簽名以接收 userID
    private func verifyAppleToken(idToken: String, userID: String, fullName: PersonNameComponents?, email: String?) async {
    // highlight-end
        do {
            // highlight-start
            // 修正 #3: 移除臨時前端模擬，啟用真正的後端 API 呼叫
            let backendUser = try await apiService.verifyAppleToken(idToken: idToken, fullName: fullName, email: email)
            self.user = backendUser
            self.isAuthenticated = true
            // highlight-end
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAuthenticated = false
            ErrorHandler.handle(error: error, component: "AuthenticationViewModel.verifyAppleToken")
        }
        isLoading = false
    }
}