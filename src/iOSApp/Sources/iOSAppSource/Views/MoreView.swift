import SwiftUI

/// 一個整合次要導覽連結和使用者操作的視圖。
///
/// 此視圖被設計為從其他視圖（例如 `DashboardView` 的工具欄）中呈現。
/// 它提供了進入使用者個人資料、資訊頁面和登出操作的入口，遵循 iOS 重建計畫中的規劃。
struct MoreView: View {
    // 從環境中讀取驗證視圖模型，以管理登入狀態和操作。
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        // 使用 Form 來獲取標準的 iOS 分組列表外觀，適合設定頁面。
        Form {
            // 此區塊包含到其他資訊頁面的主要導覽連結。
            Section {
                // 連結到使用者的個人資料頁面。
                NavigationLink(destination: UserProfileView()) {
                    // 標籤使用本地化字串鍵和相關的 SF Symbol 圖示。
                    Label(LocalizedStringKey("userProfile.title"), systemImage: "person.crop.circle")
                }
                
                // 連結到「關於我們」頁面。
                NavigationLink(destination: AboutView()) {
                    Label(LocalizedStringKey("about.pageTitle"), systemImage: "info.circle")
                }
                
                // 連結到「法律聲明」頁面。
                NavigationLink(destination: LegalView()) {
                    Label(LocalizedStringKey("legal.pageTitle"), systemImage: "doc.text")
                }
            }
            
            // 此區塊包含操作，特別是登出按鈕。
            Section {
                // 登出按鈕僅在使用者通過驗證後顯示。
                if authViewModel.isAuthenticated {
                    Button(role: .destructive) {
                        // 登出流程由 AuthenticationViewModel 非同步處理。
                        Task {
                            await authViewModel.signOut()
                        }
                    } label: {
                        Label(LocalizedStringKey("userProfile.logout"), systemImage: "arrow.backward.square")
                    }
                }
            }
        }
        // 根據開發計畫的明確指示設定導覽標題。
        .navigationTitle("更多")
    }
}