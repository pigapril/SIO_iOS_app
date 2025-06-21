import SwiftUI

public struct MainView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    public init() {}

    public var body: some View {
        List {
            // 登入/個人資料區塊
            if authViewModel.isAuthenticated {
                NavigationLink(destination: UserProfileView()) {
                    // highlight-start
                    // 這種動態文字的情況，使用 NSLocalizedString 是正確的
                    Label(authViewModel.user?.username ?? NSLocalizedString("userProfile.title", bundle: .module, comment: ""), systemImage: "person.crop.circle.fill")
                    // highlight-end
                }
            } else {
                Button(action: {
                    Task {
                        await authViewModel.signIn()
                    }
                }) {
                    // highlight-start
                    // NSLocalizedString 同樣適用於 Button
                    Label(NSLocalizedString("signInButton.googleAriaLabel", bundle: .module, comment: ""), systemImage: "person.badge.key.fill")
                    // highlight-end
                }
            }

            Divider()

            // 功能列表 - 全面改用 `Label { Text(...) }` 語法
            NavigationLink(destination: HomeView()) {
                // highlight-start
                Label {
                    Text("nav.home", bundle: .module)
                } icon: {
                    Image(systemName: "house.fill")
                }
                // highlight-end
            }
            NavigationLink(destination: PriceAnalysisView()) {
                // highlight-start
                Label {
                    Text("nav.priceAnalysis", bundle: .module)
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }
                // highlight-end
            }
            NavigationLink(destination: MarketSentimentView()) {
                // highlight-start
                Label {
                    Text("nav.marketSentiment", bundle: .module)
                } icon: {
                    Image(systemName: "heart.fill")
                }
                // highlight-end
            }
            NavigationLink(destination: WatchlistView()) {
                // highlight-start
                Label {
                    Text("nav.watchlist", bundle: .module)
                } icon: {
                    Image(systemName: "list.star")
                }
                // highlight-end
            }
            NavigationLink(destination: ArticlesView()) {
                // highlight-start
                Label {
                    Text("nav.articles", bundle: .module)
                } icon: {
                    Image(systemName: "newspaper.fill")
                }
                // highlight-end
            }
            NavigationLink(destination: AboutView()) {
                // highlight-start
                Label {
                    Text("footer.aboutSite", bundle: .module)
                } icon: {
                    Image(systemName: "info.circle.fill")
                }
                // highlight-end
            }
            NavigationLink(destination: LegalView()) {
                // highlight-start
                Label {
                    Text("legal.pageTitle", bundle: .module)
                } icon: {
                    Image(systemName: "doc.text.fill")
                }
                // highlight-end
            }
        }
    }
}