// src/iOSApp/Sources/iOSAppSource/Utils/TabSelectionManager.swift

import SwiftUI

@MainActor
public class TabSelectionManager: ObservableObject {
    @Published public var selectedTab: Int = 0 // 0 for Dashboard, 1 for Price Analysis, 2 for Market Sentiment, 3 for Watchlist

    public static let shared = TabSelectionManager()

    private init() {}
}