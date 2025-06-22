import SwiftUI

struct ToastView: View {
    let toast: Toast

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                toast.type.icon
                    .foregroundColor(toast.type.themeColor)

                VStack(alignment: .leading) {
                    Text(toast.title)
                        .font(.headline)
                        .fontWeight(.medium)

                    if let message = toast.message {
                        Text(message)
                            .font(.subheadline)
                            .opacity(0.8)
                    }
                }
                Spacer(minLength: 10)
            }
            .padding()
        }
        .background(.background)
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(.horizontal)
        .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
    }
}
