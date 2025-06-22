import SwiftUI

@MainActor
public class ToastManager: ObservableObject { // 1. Class needs to be public
    @Published public var toast: Toast? // 2. Property needs to be public

    public static let shared = ToastManager()

    private init() {}

    // 3. The show method also needs to be public
    public func show(type: ToastType, title: String, message: String? = nil, duration: Double = 3.0) {
        self.toast = Toast(type: type, title: title, message: message, duration: duration)
    }
}