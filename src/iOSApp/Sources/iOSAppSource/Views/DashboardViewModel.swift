import Foundation
import SwiftUI

/// A view model responsible for fetching and managing the data required for the `DashboardView`.
///
/// This class conforms to the `ObservableObject` protocol, allowing SwiftUI views to subscribe to its changes.
/// All updates to its `@Published` properties are guaranteed to be on the main thread because the class is marked with `@MainActor`.
@MainActor
class DashboardViewModel: ObservableObject {
    
    /// The latest market sentiment data, including the composite score and individual indicators.
    /// This property is optional and will be `nil` until the first successful fetch.
    @Published var marketSentiment: MarketSentimentResponse?
    
    /// The user's watchlist categories and the stocks within them.
    /// It is initialized as an empty array to prevent UI issues with optionals.
    @Published var categories: [Category] = []
    
    /// A Boolean flag indicating whether a data fetch operation is currently in progress.
    @Published var isLoading = false
    
    /// An optional string containing a description of the most recent error, if one occurred.
    @Published var errorMessage: String?

    /// Fetches all necessary data for the dashboard from the `APIService`.
    ///
    /// This method performs two network requests in parallel to fetch market sentiment and user categories.
    /// It updates the `isLoading` state and handles any potential errors by populating `errorMessage`
    /// and logging the error through the `ErrorHandler`.
    func fetchDashboardData() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // According to the plan, fetch market sentiment and categories in parallel
                // for a faster dashboard load time.
                async let sentimentData = APIService.shared.fetchMarketSentiment()
                async let categoriesData = APIService.shared.fetchCategories()

                // Await both results and assign them to the published properties.
                self.marketSentiment = try await sentimentData
                self.categories = try await categoriesData

            } catch {
                // If any of the parallel tasks fail, the error is caught here.
                // The localized description is assigned for display in the UI.
                self.errorMessage = error.localizedDescription
                
                // Use the established ErrorHandler to log the error for analytics and debugging.
                ErrorHandler.handle(error: error, component: "DashboardViewModel.fetchDashboardData")
            }
            
            // Ensure the loading indicator is turned off regardless of success or failure.
            self.isLoading = false
        }
    }
}