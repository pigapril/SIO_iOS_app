import SwiftUI

public struct MainView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    public init() {}

    public var body: some View {
        List {
            // 登入/個人資料區塊
            if authViewModel.isAuthenticated {
                NavigationLink(destination: UserProfileView()) {
                    Label(authViewModel.user?.username ?? "個人資料", systemImage: "person.crop.circle.fill")
                }
            } else {
                Button(action: {
                    Task {
                        await authViewModel.signIn()
                    }
                }) {
                    Label("使用 Google 登入", systemImage: "person.badge.key.fill")
                }
            }

            Divider()

            // 功能列表
            NavigationLink(destination: HomeView()) {
                Label("首頁", systemImage: "house.fill")
            }
            NavigationLink(destination: PriceAnalysisView()) {
                Label("價格標準差分析", systemImage: "chart.line.uptrend.xyaxis")
            }
            NavigationLink(destination: MarketSentimentView()) {
                Label("市場情緒指數", systemImage: "heart.fill")
            }
            NavigationLink(destination: WatchlistView()) {
                Label("觀察清單", systemImage: "list.star")
            }
            NavigationLink(destination: ArticlesView()) {
                Label("文章", systemImage: "newspaper.fill")
            }
            NavigationLink(destination: AboutView()) {
                Label("關於", systemImage: "info.circle.fill")
            }
            NavigationLink(destination: LegalView()) {
                Label("法律資訊", systemImage: "doc.text.fill")
            }
        }
        .navigationTitle("選單")
    }
}