// src/iOSApp/Sources/iOSAppSource/Services/LanguageManager.swift

import Foundation
import SwiftUI

// 這是一個可觀察的物件，用於在整個 App 中共享和管理當前的語言設定。
@MainActor
public class LanguageManager: ObservableObject {
    // 使用 @Published 屬性，當其值改變時，所有訂閱此物件的 SwiftUI 視圖都會自動更新。
    @Published public var currentLanguage: String

    // 提供一個全局共享的單例，方便從 App 的任何地方存取。
    public static let shared = LanguageManager()

    // 支援的語言列表 (語言代碼)
    private let supportedLanguages = ["en", "zh-Hant"]

    private init() {
        // 從 UserDefaults 讀取用戶上次儲存的語言偏好。
        // "AppleLanguages" 是 iOS 系統用來儲存 App 語言偏好的標準鍵。
        if let savedLanguage = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first, supportedLanguages.contains(savedLanguage) {
            self.currentLanguage = savedLanguage
        } else {
            // 如果沒有儲存的偏好，則根據設備的系統語言來設定預設值。
            let preferredLanguage = Bundle.main.preferredLocalizations.first ?? "en"
            self.currentLanguage = supportedLanguages.contains(preferredLanguage) ? preferredLanguage : "en" // 如果系統語言不支援，預設為英文
        }
    }

    // 設定新的語言，並將其儲存到 UserDefaults 中以供下次啟動時使用。
    public func setLanguage(_ language: String) {
        guard supportedLanguages.contains(language) else { return }
        currentLanguage = language
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
    }
}