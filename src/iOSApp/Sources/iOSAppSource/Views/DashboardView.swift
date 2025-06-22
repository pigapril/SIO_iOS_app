// pigapril/sio_ios_app/SIO_iOS_app-NewDesignV1/src/iOSApp/Sources/iOSAppSource/Views/DashboardView.swift
import SwiftUI

// Represents the main dashboard view of the app.
public struct DashboardView: View {
    // TODO: To be implemented in a future phase.
    // @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject private var authViewModel: AuthenticationViewModel

    public init() {}

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Welcome Header
                    welcomeHeader
                    
                    // Summary Cards
                    summaryCard(
                        titleKey: "dashboard.marketSentimentTitle",
                        destination: MarketSentimentView(),
                        icon: "heart.pulse.fill",
                        color: .pink
                    )
                    
                    summaryCard(
                        titleKey: "dashboard.priceAnalysisTitle",
                        destination: PriceAnalysisView(),
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue
                    )

                    summaryCard(
                        titleKey: "dashboard.watchlistTitle",
                        destination: WatchlistView(),
                        icon: "list.star",
                        color: .orange
                    )

                    // Articles Section
                    articlesSection

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(Text("dashboard.pageTitle", bundle: .module))
            .background(Color(.systemGroupedBackground))
        }
    }

    /// The view for the welcome header.
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let user = authViewModel.user {
                    // Uses localization with a parameter.
                    Text("dashboard.greeting", bundle: .module)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(user.username)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                } else {
                    Text("dashboard.welcome", bundle: .module)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
            }
            Spacer()
        }
    }
    
    /// A reusable view for summary navigation cards.
    private func summaryCard<Destination: View>(titleKey: LocalizedStringKey, destination: Destination, icon: String, color: Color) -> some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .frame(width: 40)
                
                Text(titleKey, bundle: .module)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle()) // Ensures the entire card is tappable as one unit
    }

    /// The view for the latest articles section.
    private var articlesSection: some View {
        VStack(alignment: .leading) {
            Text("dashboard.latestArticlesTitle", bundle: .module)
                .font(.title2)
                .bold()
                .padding(.bottom, 8)
            
            // Placeholder for article content
            // TODO: Replace with data from a ViewModel in a future phase.
            VStack(spacing: 16) {
                NavigationLink(destination: ArticlesView()) { // Placeholder destination
                    articleRow(imageName: "home-feature1", titleKey: "home.feature1.title", date: Date())
                }
                NavigationLink(destination: ArticlesView()) { // Placeholder destination
                    articleRow(imageName: "home-feature2", titleKey: "home.feature2.title", date: Date().addingTimeInterval(-86400))
                }
            }
        }
    }

    /// A reusable view for a single article row.
    private func articleRow(imageName: String, titleKey: LocalizedStringKey, date: Date) -> some View {
        HStack(spacing: 16) {
            Image(imageName) // Assuming images are in asset catalog
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 60)
                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(titleKey, bundle: .module)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .buttonStyle(PlainButtonStyle())
    }
}