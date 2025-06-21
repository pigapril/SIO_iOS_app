import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        VStack(spacing: 20) {
            if let user = authViewModel.user {
                AsyncImage(url: URL(string: user.avatarUrl)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } placeholder: {
                    ProgressView()
                }
                
                Text(user.username)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    Task {
                        await authViewModel.signOut()
                    }
                }) {
                    Text("登出")
                        .foregroundColor(.red)
                }
                .padding(.top, 20)
                
            } else {
                Text("未登入")
            }
            Spacer()
        }
        .padding()
        .navigationTitle("個人資料")
    }
}