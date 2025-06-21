import SwiftUI

struct HomeView: View {
        @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Section
                VStack {
                    Text("洞悉市場情緒，掌握投資先機")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("我們利用獨家的市場情緒分析模型，幫助您在複雜的金融市場中，做出更明智的決策。")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                    
                    Image(systemName: "chevron.down")
                        .padding(.top, 20)
                }
                .padding()

                // Feature 1: Price Analysis
                FeatureView(
                    imageName: "home-feature1",
                    title: "價格標準差分析",
                    text: "利用統計學找出股價的異常波動，捕捉潛在的交易機會。",
                    linkText: "了解更多",
                    destination: AnyView(PriceAnalysisView())
                )

                // Feature 2: Watchlist
                FeatureView(
                    imageName: "home-feature2",
                    title: "個人化追蹤清單",
                    text: "建立您的個人化股票清單，即時追蹤市場情緒與價格變化。",
                    linkText: "立即體驗",
                    destination: AnyView(WatchlistView())
                )

                // Feature 3: Market Sentiment
                FeatureView(
                    imageName: "home-feature3",
                    title: "市場情緒指數",
                    text: "獨家市場情緒指數，幫助您判斷當前市場氛圍，避免追高殺低。",
                    linkText: "查看指數",
                    destination: AnyView(MarketSentimentView())
                )
                
                // CTA Section - 只有在未登入時顯示
                if !authViewModel.isAuthenticated {
                    Button(action: {
                        Task {
                            await authViewModel.signIn()
                        }
                    }) {
                        Text("立即註冊，免費體驗")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("首頁")
    }
}

// FeatureView 保持不變
struct FeatureView: View {
    let imageName: String
    let title: String
    let text: String
    let linkText: String
    let destination: AnyView

    var body: some View {
        HStack(spacing: 20) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(text)
                    .font(.body)
                
                NavigationLink(destination: destination) {
                    Text(linkText)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
    }
}