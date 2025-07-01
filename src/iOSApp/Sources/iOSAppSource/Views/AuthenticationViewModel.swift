import Foundation
import Combine
import AuthenticationServices


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

    public func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            // 從授權結果中提取憑證
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Failed to get Apple ID Credential."
                isLoading = false
                return
            }
            
            // **重要：**
            // 只有在用戶「第一次」使用 Apple 登入您的 App 時，才會回傳 fullName 和 email。
            // 您必須安全地儲存這些資訊。後續登入將只回傳 user identifier。
            
            let userID = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            // 獲取 identityToken，這是要傳給後端驗證的 JWT
            guard let identityTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8) else {
                errorMessage = "Failed to get identity token."
                isLoading = false
                return
            }

            // 將 token 傳送到您的後端進行驗證
            Task {
                await verifyAppleToken(idToken: idToken, fullName: fullName, email: email)
            }
            
        case .failure(let error):
            // 處理錯誤，例如用戶取消
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
    
    /// 與您的後端 API 驗證 Apple idToken 的異步函數
    private func verifyAppleToken(idToken: String, fullName: PersonNameComponents?, email: String?) async {
        // --- 後端開發 ---
        // 您需要在後端建立一個新的 API 端點，例如 `/auth/apple/verify`
        // 這個端點會接收 idToken，並使用 Apple 的公鑰來驗證其簽名。
        // 驗證成功後，為該用戶建立或更新資料庫記錄，並回傳一個您自己系統的 JWT 或用戶資料。
        // -----------------

        // 以下為模擬呼叫後端 API
        do {
            // let backendUser = try await apiService.verifyAppleToken(idToken: idToken, fullName: fullName, email: email)
            // self.user = backendUser
            // self.isAuthenticated = true
            
            // --- 臨時前端模擬 ---
            // 因為後端尚未建立，我們先用假資料模擬成功登入
            print("Received Apple User ID: \(appleIDCredential.user)")
            print("Received idToken to be sent to backend: \(idToken)")
            let mockUserName = (fullName?.givenName ?? "") + " " + (fullName?.familyName ?? "")
            self.user = User(id: appleIDCredential.user, username: mockUserName.isEmpty ? "Apple User" : mockUserName, email: email ?? "hidden@apple.com", avatarUrl: "")
            self.isAuthenticated = true
            // --------------------
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAuthenticated = false
            ErrorHandler.handle(error: error, component: "AuthenticationViewModel.verifyAppleToken")
        }
        isLoading = false
    }
}