// pigapril/sio_ios_app/SIO_iOS_app-MinorFix/src/iOSApp/Sources/iOSAppSource/Views/DashboardViewModel.swift

import Foundation
import SwiftUI

/// A view model responsible for fetching and managing the data required for the `DashboardView`.
@MainActor
class DashboardViewModel: ObservableObject {
    
    @Published var marketSentiment: MarketSentimentResponse?
    
    // --- MODIFICATION START ---
    // The heavyweight 'categories' property is no longer needed in this ViewModel.
    
    // This property is now populated directly from the new lightweight API endpoint.
    @Published var prioritizedWatchlistPreview: [Stock] = []
    // --- MODIFICATION END ---
    
    @Published var isLoading = false
    @Published var errorMessage: String?

    // --- REMOVED ---
    // The client-side sorting logic (SentimentPriority enum, getSentimentPriority, updatePrioritizedWatchlist)
    // has been removed as this logic is now handled by the backend.

    /// Fetches all necessary data for the dashboard from the `APIService`.
    func fetchDashboardData() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // --- MODIFICATION ---
                // Fetch market sentiment and the new lightweight watchlist preview in parallel for a faster load.
                async let sentimentData = APIService.shared.fetchMarketSentiment()
                async let previewData = APIService.shared.fetchWatchlistPreview() // Use the new, efficient function

                // Await both results and assign them to the published properties.
                self.marketSentiment = try await sentimentData
                self.prioritizedWatchlistPreview = try await previewData // Assign the sorted preview data directly

            } catch {
                // If any of the parallel tasks fail, the error is caught here.
                self.errorMessage = error.localizedDescription
                ErrorHandler.handle(error: error, component: "DashboardViewModel.fetchDashboardData")
            }
            
            // Ensure the loading indicator is turned off regardless of success or failure.
            self.isLoading = false
        }
    }
}