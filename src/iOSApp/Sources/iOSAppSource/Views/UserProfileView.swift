//
// pigapril/sio_ios_app/SIO_iOS_app-language-setting/src/iOSApp/Sources/iOSAppSource/Views/UserProfileView.swift
// Refactored to support dynamic localization
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        VStack(spacing: 20) {
            // 檢查使用者是否已登入
            if let user = authViewModel.user {
                // 使用者頭像
                AsyncImage(url: URL(string: user.avatarUrl)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } placeholder: {
                    ProgressView()
                }
                
                // 顯示使用者名稱（來自變數，不需翻譯）
                Text(user.username)
                    .font(.title)
                    .fontWeight(.bold)
                
                // 顯示使用者 Email（來自變數，不需翻譯）
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // 登出按鈕
                Button(action: {
                    Task {
                        await authViewModel.signOut()
                    }
                }) {
                    // --- 修改後：使用 .localized() 方法 ---
                    Text("userProfile.logout".localized())
                        .foregroundColor(.red)
                }
                .padding(.top, 20)
                
            } else {
                // 未登入時顯示的文字
                // --- 修改後：使用 .localized() 方法 ---
                Text("userProfile.notLoggedIn".localized())
            }
            Spacer()
        }
        .padding()
        // --- 修改後：導覽列標題也使用 .localized() 方法 ---
        .navigationTitle(Text("userProfile.title".localized()))
    }
}