// pigapril/sio_ios_app/SIO_iOS_app-0706minor_fix/src/iOSApp/Sources/iOSAppSource/Views/DashboardViewModel.swift

import Foundation
import SwiftUI

/// A view model responsible for fetching and managing the data required for the `DashboardView`.
@MainActor
public class DashboardViewModel: ObservableObject {
    
    @Published public var marketSentiment: MarketSentimentResponse?
    @Published public var prioritizedWatchlistPreview: [Stock] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    /// Enum to manage the state of preloading data before showing the dashboard.
    public enum PreloadState {
        case idle       // Not started yet
        case loading    // Preloading is in progress
        case loaded     // Preloading completed successfully
        case timedOut   // Preloading timed out or failed
    }
    
    @Published public var preloadState: PreloadState = .idle
    private var timeoutWorkItem: DispatchWorkItem?

    // Public initializer to be accessible from other modules.
    public init() {}

    /// Preloads the essential watchlist preview data with a timeout.
    public func preloadWatchlistPreview(withTimeout timeout: TimeInterval) {
        guard preloadState == .idle else { return } // Prevent multiple runs

        preloadState = .loading
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.preloadState == .loading else { return }
            self.preloadState = .timedOut
        }
        self.timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: workItem)

        Task {
            do {
                // This fetches data but we don't need to store it here, just confirm it loads.
                _ = try await APIService.shared.fetchWatchlistPreview()
                if self.preloadState == .loading {
                    self.timeoutWorkItem?.cancel()
                    self.preloadState = .loaded
                }
            } catch {
                if self.preloadState == .loading {
                    self.timeoutWorkItem?.cancel()
                    self.preloadState = .timedOut
                }
            }
        }
    }

    /// Resets the preload state, typically called on user logout.
    public func resetPreloadState() {
        timeoutWorkItem?.cancel()
        preloadState = .idle
    }
    
    /// Fetches all necessary data for the dashboard from the `APIService`.
    public func fetchDashboardData() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                async let sentimentData = APIService.shared.fetchMarketSentiment()
                async let previewData = APIService.shared.fetchWatchlistPreview()

                self.marketSentiment = try await sentimentData
                self.prioritizedWatchlistPreview = try await previewData

            } catch {
                self.errorMessage = error.localizedDescription
                ErrorHandler.handle(error: error, component: "DashboardViewModel.fetchDashboardData")
            }
            
            self.isLoading = false
        }
    }
}