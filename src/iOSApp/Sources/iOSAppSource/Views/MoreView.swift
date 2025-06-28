// src/iOSApp/Sources/iOSAppSource/Views/MoreView.swift

import SwiftUI
import iOSAppSource

struct MoreView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    // 從環境中獲取 LanguageManager，以便讀取和修改語言設定
    @EnvironmentObject var languageManager: LanguageManager

    // 依然使用可靠的 Bundle 尋找器來確保 NSLocalizedString 能找到正確的翻譯檔
    private var packageBundle: Bundle {
        let bundleName = "iOSApp_iOSAppSource"
        if let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }
        return Bundle(for: AuthenticationViewModel.self)
    }

    var body: some View {
        Form {
            // 第一區塊：帳號與資訊連結
            Section {
                NavigationLink(destination: UserProfileView()) {
                    // 所有標籤都使用 .localized() 以支援即時語言切換
                    Label("userProfile.title".localized(),
                          systemImage: "person.crop.circle")
                }
                
                NavigationLink(destination: AboutView()) {
                    Label("about.pageTitle".localized(),
                          systemImage: "info.circle")
                }
                
                NavigationLink(destination: LegalView()) {
                    Label("legal.pageTitle".localized(),
                          systemImage: "doc.text")
                }
            }
            
            // 第二區塊：新增的語言選擇器
            Section(header: Text("language.change".localized())) {
                // Picker 的選擇狀態直接綁定到 languageManager 的 currentLanguage
                Picker("language.change".localized(), selection: $languageManager.currentLanguage) {
                    Text("language.en".localized()).tag("en")
                    Text("language.zhTW".localized()).tag("zh-Hant")
                }
                .pickerStyle(.inline) // 使用內聯樣式，讓選項直接顯示在列表中
                .labelsHidden()       // 隱藏 Picker 左側的重複標題
            }
            // 當綁定的 currentLanguage 值改變時，調用 setLanguage 方法來儲存設定
            .onChange(of: languageManager.currentLanguage) { newLanguage in
                languageManager.setLanguage(newLanguage)
            }
            
            // 第三區塊：登出按鈕
            Section {
                if authViewModel.isAuthenticated {
                    Button(role: .destructive) {
                        Task {
                            await authViewModel.signOut()
                        }
                    } label: {
                        Label("userProfile.logout".localized(),
                              systemImage: "arrow.backward.square")
                    }
                }
            }
        }
        // 頁面標題也使用 .localized()
        .navigationTitle(Text("footer.otherResources".localized()))
    }
}