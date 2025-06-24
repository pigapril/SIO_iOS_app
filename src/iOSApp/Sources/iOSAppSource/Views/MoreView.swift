// 檔案路徑: pigapril/sio_ios_app/SIO_iOS_app-NewDesignV2/src/iOSApp/Sources/iOSAppSource/Views/MoreView.swift

import SwiftUI
// 導入 iOSAppSource 以便訪問其中的類別
import iOSAppSource

struct MoreView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    // 複製過來的、可靠的 Bundle 尋找器
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
        // 使用 Form 來獲取標準的 iOS 分組列表外觀
        Form {
            Section {
                // 修正1：使用 NSLocalizedString 從正確的 packageBundle 讀取字串
                NavigationLink(destination: UserProfileView()) {
                    Label(NSLocalizedString("userProfile.title", bundle: packageBundle, comment: "Profile link"), 
                          systemImage: "person.crop.circle")
                }
                
                // 修正2：處理 "關於我們"
                NavigationLink(destination: AboutView()) {
                    Label(NSLocalizedString("about.pageTitle", bundle: packageBundle, comment: "About Us link"), 
                          systemImage: "info.circle")
                }
                
                // 修正3：處理 "法律聲明"
                NavigationLink(destination: LegalView()) {
                    Label(NSLocalizedString("legal.pageTitle", bundle: packageBundle, comment: "Legal link"), 
                          systemImage: "doc.text")
                }
            }
            
            Section {
                if authViewModel.isAuthenticated {
                    Button(role: .destructive) {
                        Task {
                            await authViewModel.signOut()
                        }
                    } label: {
                        // 修正4：處理 "登出" 按鈕
                        Label(NSLocalizedString("userProfile.logout", bundle: packageBundle, comment: "Logout button"), 
                              systemImage: "arrow.backward.square")
                    }
                }
            }
        }
        // 修正5：將硬編碼的標題改為本地化字串
        // "footer.otherResources" 在您的翻譯檔中對應 "其他資源" / "Other Resources"
        .navigationTitle(Text(NSLocalizedString("footer.otherResources", bundle: packageBundle, comment: "Title for the More view")))
    }
}