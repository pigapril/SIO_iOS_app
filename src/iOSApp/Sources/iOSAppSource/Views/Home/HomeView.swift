import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Section
                VStack {
                    // highlight-start
                    Text("home.hero.title", bundle: .module)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("home.hero.subtitle", bundle: .module)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                    // highlight-end
                    
                    Image(systemName: "chevron.down")
                        .padding(.top, 20)
                }
                .padding()

                // Feature 1: Price Analysis
                // highlight-start
                FeatureView(
                    imageName: "home-feature1",
                    titleKey: "home.feature1.title",
                    textKey: "home.feature1.text",
                    linkTextKey: "home.feature.link",
                    destination: AnyView(PriceAnalysisView())
                )
                // highlight-end

                // Feature 2: Watchlist
                // highlight-start
                FeatureView(
                    imageName: "home-feature2",
                    titleKey: "home.feature2.title",
                    textKey: "home.feature2.text",
                    linkTextKey: "home.feature.link",
                    destination: AnyView(WatchlistView())
                )
                // highlight-end

                // Feature 3: Market Sentiment
                // highlight-start
                FeatureView(
                    imageName: "home-feature3",
                    titleKey: "home.feature3.title",
                    textKey: "home.feature3.text",
                    linkTextKey: "home.feature.link",
                    destination: AnyView(MarketSentimentView())
                )
                // highlight-end
                
                // CTA Section - 只有在未登入時顯示
                if !authViewModel.isAuthenticated {
                    Button(action: {
                        Task {
                            await authViewModel.signIn()
                        }
                    }) {
                        // highlight-start
                        Text("home.cta.button", bundle: .module)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                        // highlight-end
                    }
                    .padding()
                }
            }
        }
        // highlight-start
        .navigationTitle(Text("nav.home", bundle: .module))
        // highlight-end
    }
}

// FeatureView 已修改為接受翻譯鍵
struct FeatureView: View {
    let imageName: String
    let titleKey: LocalizedStringKey
    let textKey: LocalizedStringKey
    let linkTextKey: LocalizedStringKey
    let destination: AnyView

    var body: some View {
        HStack(spacing: 20) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 10) {
                // highlight-start
                Text(titleKey, bundle: .module)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(textKey, bundle: .module)
                    .font(.body)
                
                NavigationLink(destination: destination) {
                    Text(linkTextKey, bundle: .module)
                        .foregroundColor(.blue)
                }
                // highlight-end
            }
        }
        .padding()
    }
}