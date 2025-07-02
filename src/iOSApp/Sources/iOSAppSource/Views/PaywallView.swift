// src/iOSApp/Sources/iOSAppSource/Views/PaywallView.swift (修改後)

import SwiftUI

/// 向未訂閱使用者展示的「付費牆」畫面。
/// 這個視圖的目標是說服使用者訂閱，並提供購買與恢復的入口。
struct PaywallView: View {
    // 從環境中獲取模擬的付費服務
    @StateObject private var paymentService = PaymentService.shared
    @Environment(\.dismiss) private var dismiss

    // --- NEW ---
    /// 定義可用的訂閱方案
    private let plans: [SubscriptionPlan] = [
        SubscriptionPlan(id: "monthly",
                         title: "月度方案",
                         price: "NT$ 59",
                         period: "/ 月",
                         description: "每月自動續訂",
                         badge: nil),
        SubscriptionPlan(id: "annual",
                         title: "年度方案",
                         price: "NT$ 590",
                         period: "/ 年",
                         description: "年繳方案，現省 17%",
                         badge: "贈送2個月")
    ]
    
    /// 追蹤使用者選擇的方案
    @State private var selectedPlanID: String = "annual"
    // --- END NEW ---

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
                VStack(spacing: 10) {
                    VStack(spacing: 10) {
                        Image("Logo", bundle: .main)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 75)
                            // --- DELETED: 完全移除頂部 padding ---
                            // .padding(.top)
                        
                        Text("一天只要不到 2 塊")
                            .font(.largeTitle).bold()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // 特色列表
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(icon: "🔓", text: "解鎖完整功能")
                        FeatureRow(icon: "✨", text: "沒有廣告打擾")
                        FeatureRow(icon: "🚀", text: "未來優先功能更新")
                    }
                    .padding(EdgeInsets(top: 25, leading: 30, bottom: 25, trailing: 30))
                    .background(.thinMaterial)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // --- NEW: 方案選擇器 ---
                    VStack(spacing: 15) {
                        ForEach(plans) { plan in
                            SubscriptionOptionView(plan: plan, isSelected: selectedPlanID == plan.id)
                                .onTapGesture {
                                    selectedPlanID = plan.id
                                }
                        }
                    }
                    .padding(.horizontal)
                    // --- END NEW ---
                    
                    Spacer()

                    // 訂閱按鈕和條款
                    VStack(spacing: 16) {
                        if paymentService.isLoading {
                            ProgressView()
                                .frame(height: 50)
                        } else {
                            Button(action: {
                                // --- MODIFIED: 傳遞選擇的方案 ---
                                if let selectedPlan = plans.first(where: { $0.id == selectedPlanID }) {
                                    paymentService.purchase(plan: selectedPlan)
                                }
                            }) {
                                // --- MODIFIED: 更新按鈕文字 ---
                                Text("開始7天免費試用")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                            }
                        }
                        
                        // --- NEW: 試用期和續訂說明 ---
                        Text("首次訂閱可享7天免費試用。試用期結束後，將依您選擇的方案自動續訂，您可以隨時在 App Store 帳號設定中取消。")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        // --- END NEW ---

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
        .navigationBarHidden(true)
    }
}

// --- NEW HELPER VIEW ---
/// 用於顯示單個訂閱方案選項的視圖
struct SubscriptionOptionView: View {
    let plan: SubscriptionPlan
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(alignment: .firstTextBaseline) {
                    Text(plan.price)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(plan.period)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(plan.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let badge = plan.badge {
                Text(badge)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2.5)
        )
        .animation(.spring(), value: isSelected)
    }
}
// --- END NEW HELPER VIEW ---


/// 付費牆中的功能列表項目
private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.largeTitle)
                .frame(width: 40)
            Text(text)
                .font(.headline)
                .fontWeight(.medium)
            Spacer()
        }
    }
}