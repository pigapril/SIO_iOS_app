// pigapril/sio_ios_app/SIO_iOS_app-marketsentiment_fix/src/iOSApp/Sources/iOSApp/Views/UserProfileView.swift

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
                    Text("userProfile.logout", bundle: .module)
                        .foregroundColor(.red)
                }
                .padding(.top, 20)
                
            } else {
                Text("userProfile.notLoggedIn", bundle: .module)
            }
            Spacer()
        }
        .padding()
        .navigationTitle(Text("userProfile.title", bundle: .module))
    }
}