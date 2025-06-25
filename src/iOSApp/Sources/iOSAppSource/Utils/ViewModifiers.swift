import SwiftUI

// 這是一個公開的 ViewModifier，負責實現卡片樣式
public struct CardViewModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding([.horizontal, .bottom])
    }
    
    // 需要一個公開的初始化方法
    public init() {}
}

// 這是對 View 的擴展，讓我們可以方便地使用 .cardStyle()
public extension View {
    func cardStyle() -> some View {
        self.modifier(CardViewModifier())
    }
}