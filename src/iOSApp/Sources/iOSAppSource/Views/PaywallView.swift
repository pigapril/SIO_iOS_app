// src/iOSApp/Sources/iOSAppSource/Views/PaywallView.swift

import SwiftUI

/// 向未訂閱使用者展示的「付費牆」畫面。
/// 這個視圖的目標是說服使用者訂閱，並提供購買與恢復的入口。
struct PaywallView: View {
    // 從環境中獲取模擬的付費服務
    @StateObject private var paymentService = PaymentService.shared
    @Environment(\.dismiss) private var dismiss

    // --- MODIFIED: The plans are now a computed property using the correct localization keys ---
    /// 定義可用的訂閱方案
    private var plans: [SubscriptionPlan] {
        [
            SubscriptionPlan(id: "monthly",
                             title: "paywall.plan.monthly.title".localized(),
                             price: "paywall.plan.monthly.price".localized(),
                             period: "paywall.plan.monthly.period".localized(),
                             description: "paywall.plan.monthly.description".localized(),
                             badge: nil), // 月度方案沒有徽章
            SubscriptionPlan(id: "annual",
                             title: "paywall.plan.annual.title".localized(),
                             price: "paywall.plan.annual.price".localized(),
                             period: "paywall.plan.annual.period".localized(),
                             description: "paywall.plan.annual.description".localized(),
                             badge: "paywall.plan.annual.badge".localized())
        ]
    }
    
    /// 追蹤使用者選擇的方案
    @State private var selectedPlanID: String = "annual"

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
                        
                        // --- LOCALIZED (Corrected Key) ---
                        Text("paywall.title".localized())
                            .font(.largeTitle).bold()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // 特色列表
                    VStack(alignment: .leading, spacing: 20) {
                        // --- LOCALIZED (Corrected Keys) ---
                        FeatureRow(icon: "🔓", text: "paywall.feature1".localized())
                        FeatureRow(icon: "✨", text: "paywall.feature2".localized())
                        FeatureRow(icon: "🚀", text: "paywall.feature3".localized())
                    }
                    .padding(EdgeInsets(top: 25, leading: 30, bottom: 25, trailing: 30))
                    .background(.thinMaterial)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // 方案選擇器
                    VStack(spacing: 15) {
                        ForEach(plans) { plan in
                            SubscriptionOptionView(plan: plan, isSelected: selectedPlanID == plan.id)
                                .onTapGesture {
                                    selectedPlanID = plan.id
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()

                    // 訂閱按鈕和條款
                    VStack(spacing: 16) {
                        if paymentService.isLoading {
                            ProgressView()
                                .frame(height: 50)
                        } else {
                            Button(action: {
                                if let selectedPlan = plans.first(where: { $0.id == selectedPlanID }) {
                                    paymentService.purchase(plan: selectedPlan)
                                }
                            }) {
                                // --- LOCALIZED (Corrected Key) ---
                                Text("paywall.cta.trial".localized())
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                            }
                        }
                        
                        // --- LOCALIZED (Corrected Key) ---
                        Text("paywall.terms".localized())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                             paymentService.restorePurchases()
                        }) {
                            // --- LOCALIZED (Corrected Key) ---
                            Text("paywall.restore".localized())
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
            
            if let badge = plan.badge, !badge.isEmpty {
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