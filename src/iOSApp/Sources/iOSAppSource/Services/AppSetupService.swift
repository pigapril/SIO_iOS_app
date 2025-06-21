import Foundation
import FirebaseCore
import GoogleSignIn

public enum AppSetupService {
    public static func configure() {
        // 確保您的專案中已經正確加入了 GoogleService-Info.plist 檔案
        guard let gServicesPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let firebaseOptions = FirebaseOptions(contentsOfFile: gServicesPath) else {
            fatalError("Could not find or load GoogleService-Info.plist. Please ensure it is added to the StockApp target.")
        }
        
        // 設定 Firebase
        FirebaseApp.configure(options: firebaseOptions)

        // 從 Firebase 設定中取得 Client ID 並設定 Google Sign-In
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("Couldn't find client ID in GoogleService-Info.plist after Firebase configure.")
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }
}