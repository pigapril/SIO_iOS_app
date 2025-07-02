// src/iOSApp/Sources/iOSAppSource/Services/PaymentService.swift (修改後)

import Foundation
import SwiftUI

/// 一個模擬的付費服務管理器，用於在沒有 Apple Developer 帳號的情況下開發和測試付費牆 UI 和流程。
@MainActor
class PaymentService: ObservableObject {
    
    // ========================================================================
    // ✨ 開發總開關 ✨
    // 將此值改為 false，即可在開發過程中暫時禁用整個 App 的付費牆，直接進入主畫面。
    // 設定為 true，則會啟用付費牆邏輯。
    static let isPaywallEnabled = true
    // ========================================================================
    
    @Published var isSubscribed: Bool = false
    @Published var isLoading: Bool = false
    
    static let shared = PaymentService()
    
    private init() {}
    
    /// 檢查使用者當前的訂閱狀態。
    func checkSubscriptionStatus() {
        // 如果總開關是關閉的，就直接設定為已訂閱狀態，並跳過檢查
        guard PaymentService.isPaywallEnabled else {
            print("PaymentService: 付費牆總開關為關閉狀態，略過檢查。")
            self.isSubscribed = true
            return
        }
        
        guard !isLoading else { return }
        isLoading = true
        print("PaymentService: 正在檢查訂閱狀態...")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isSubscribed = false // 預設使用者未訂閱
            self.isLoading = false
            print("PaymentService: 檢查完成，使用者未訂閱。")
        }
    }
    
     // --- MODIFIED: 修改函式以接受一個方案 ---
    func purchase(plan: SubscriptionPlan) {
        guard !isLoading else { return }
        
        isLoading = true
        // --- MODIFIED: Log 顯示正在購買哪個方案 ---
        print("PaymentService: 開始模擬購買流程，方案: \(plan.title) (\(plan.id))")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            print("PaymentService: 模擬購買成功！")
            self.isSubscribed = true
            self.isLoading = false
            
            ToastManager.shared.show(
                type: .success,
                title: "訂閱成功！", // 這裡可以使用本地化字串
                message: "您已成功解鎖所有功能！"
            )
        }
    }
    
    func restorePurchases() {
        guard !isLoading else { return }

        isLoading = true
        print("PaymentService: 開始模擬恢復購買流程...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            print("PaymentService: 模擬恢復購買成功！")
            self.isSubscribed = true
            self.isLoading = false

            ToastManager.shared.show(
                type: .success,
                title: "恢復成功", // 這裡可以使用本地化字串
                message: "已成功恢復您先前的購買項目。"
            )
        }
    }
}