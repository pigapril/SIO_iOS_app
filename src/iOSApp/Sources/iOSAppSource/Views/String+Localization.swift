// src/iOSApp/Sources/iOSAppSource/Utils/String+Localization.swift

import Foundation

extension String {
    // +++ FIX: Add @MainActor to ensure this function runs on the main thread +++
    // 這樣它才能安全地存取同樣在 MainActor 上的 LanguageManager.shared.currentLanguage
    @MainActor
    public func localized() -> String {
        // 1. 從 LanguageManager 獲取當前選擇的語言代碼 (例如 "en" 或 "zh-Hant")。
        let currentLanguage = LanguageManager.shared.currentLanguage
        
        // 2. 找到對應語言的資源包路徑。
        // 我們需要找到 "iOSApp_iOSAppSource.bundle" 這個 Swift Package 的資源包。
        guard let packageBundleURL = Bundle.main.url(forResource: "iOSApp_iOSAppSource", withExtension: "bundle"),
              let packageBundle = Bundle(url: packageBundleURL),
              let langPath = packageBundle.path(forResource: currentLanguage, ofType: "lproj"),
              let langBundle = Bundle(path: langPath) else {
            // 如果找不到對應的語言包，則直接返回鍵值本身作為後備。
            return self
        }
        
        // 3. 從找到的語言包中，根據 self (鍵值) 載入本地化字串。
        return NSLocalizedString(self, bundle: langBundle, comment: "")
    }
}