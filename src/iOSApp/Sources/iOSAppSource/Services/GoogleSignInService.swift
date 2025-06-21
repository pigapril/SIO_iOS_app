import Foundation
import GoogleSignIn

@MainActor
class GoogleSignInService {
    static let shared = GoogleSignInService()

    private init() {}

    func signIn() async throws -> GIDGoogleUser {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            // 在真實的 App 中，你可能需要一個更優雅的方式來獲取 root view controller
            throw AppError.unknownError
        }

        // signIn 方法回傳的是 GIDSignInResult
        let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        // highlight-start
        // 從結果中返回 user 物件
        return signInResult.user
        // highlight-end
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
    
    func restorePreviousSignIn() async -> GIDGoogleUser? {
        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            return user
        } catch {
            // 這是一個預期中的錯誤，當沒有先前登入的用戶時會發生，所以我們只返回 nil
            return nil
        }
    }
}