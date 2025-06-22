import SwiftUI

// 1. Make the ViewModifier struct public
public struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    @State private var workItem: DispatchWorkItem?

    // You need a public initializer as well
    public init(toast: Binding<Toast?>) {
        self._toast = toast
    }

    // 2. The body method must also be public
    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    if let toast = toast {
                        ToastView(toast: toast)
                            .onTapGesture {
                                dismissToast()
                            }
                            .onAppear {
                                scheduleDismissal()
                            }
                    }
                }
                .animation(.spring(), value: toast)
            )
            .onChange(of: toast) { _ in
                 scheduleDismissal()
            }
    }

    private func scheduleDismissal() {
        workItem?.cancel()
        
        let task = DispatchWorkItem {
            dismissToast()
        }

        workItem = task
        if let duration = toast?.duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
        }
    }

    private func dismissToast() {
        withAnimation {
            toast = nil
        }
        workItem?.cancel()
        workItem = nil
    }
}

extension View {
    // 3. The helper function needs to be public
    public func toast(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}