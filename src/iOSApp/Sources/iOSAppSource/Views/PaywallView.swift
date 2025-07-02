// src/iOSApp/Sources/iOSAppSource/Views/PaywallView.swift (文案更新版)

import SwiftUI

/// 向未訂閱使用者展示的「付費牆」畫面。
/// 這個視圖的目標是說服使用者訂閱，並提供購買與恢復的入口。
struct PaywallView: View {
    // 從環境中獲取模擬的付費服務
    @StateObject private var paymentService = PaymentService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 背景漸層，增加視覺吸引力
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2), Color(.systemBackground)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) { // 增加間距
                    // 標題與 Logo
                    VStack(spacing: 2) {
                        Image("Logo", bundle: .main)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                            .padding(.top, 30) // 增加頂部空間
                        
                        // --- 修改後的標題 ---
                        Text("一天只要不到 2 塊")
                            .font(.largeTitle).bold()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // --- 修改後的特色列表 ---
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(icon: "🔓", text: "解鎖完整功能")
                        FeatureRow(icon: "✨", text: "沒有廣告打擾")
                        FeatureRow(icon: "🚀", text: "未來優先功能更新")
                    }
                    .padding(EdgeInsets(top: 25, leading: 30, bottom: 25, trailing: 30))
                    .background(.thinMaterial) // 使用毛玻璃效果
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    Spacer()

                    // 訂閱按鈕和條款
                    VStack(spacing: 16) {
                        if paymentService.isLoading {
                            ProgressView()
                                .frame(height: 50)
                        } else {
                            Button(action: {
                                paymentService.purchase()
                            }) {
                                Text("開始免費試用並訂閱")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                            }
                        }

                        Button(action: {
                             paymentService.restorePurchases()
                        }) {
                            Text("恢復購買")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .navigationBarHidden(true) // 付費牆通常會隱藏導航列以增加專注度
    }
}

/// 付費牆中的功能列表項目
/// 已修改為直接接收文字，而非本地化鍵
private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.largeTitle)
                .frame(width: 40) // 固定圖示寬度，讓文字對齊
            Text(text)
                .font(.headline)
                .fontWeight(.medium)
            Spacer() // 讓內容靠左
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(LanguageManager.shared) // 預覽時也注入環境物件
}