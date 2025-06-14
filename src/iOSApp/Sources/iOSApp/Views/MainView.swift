import SwiftUI

public struct MainView: View {
    public init() {}

    public var body: some View {
        List {
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