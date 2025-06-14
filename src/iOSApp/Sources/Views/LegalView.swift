import SwiftUI

struct LegalView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("法律資訊")
                    .font(.largeTitle)
                    .bold()

                LegalSection(
                    title: "隱私權政策",
                    subsections: [
                        LegalSubsection(
                            title: "我們收集的資訊",
                            points: [
                                "您註冊時提供的個人資訊，如電子郵件地址。",
                                "您在使用服務時產生的數據，如您的觀察清單和搜尋紀錄。",
                                "我們透過 Cookies 和其他技術收集的匿名使用數據。"
                            ]
                        ),
                        LegalSubsection(
                            title: "我們如何使用您的資訊",
                            points: [
                                "提供、維護及改進我們的服務。",
                                "個人化您的使用體驗。",
                                "與您溝通，包括回覆您的查詢和發送服務相關通知。"
                            ]
                        )
                        // Add more subsections here
                    ]
                )

                LegalSection(
                    title: "服務條款",
                    subsections: [
                        LegalSubsection(
                            title: "服務說明",
                            points: [
                                "本服務提供市場情緒分析和相關數據，僅供參考，不構成任何投資建議。",
                                "我們保留隨時修改或終止服務的權利。"
                            ]
                        ),
                        LegalSubsection(
                            title: "免責聲明",
                            points: [
                                "您承認使用本服務的風險由您自行承擔。",
                                "我們不保證服務的準確性、完整性或及時性。",
                                "對於您因使用或無法使用本服務而造成的任何損失，我們概不負責。"
                            ]
                        )
                        // Add more subsections here
                    ]
                )
            }
            .padding()
        }
        .navigationTitle("法律資訊")
    }
}

struct LegalSection: View {
    let title: String
    let subsections: [LegalSubsection]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title)
                .bold()
            ForEach(subsections) { subsection in
                subsection
            }
        }
    }
}

struct LegalSubsection: View, Identifiable {
    let id = UUID()
    let title: String
    let points: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.title2)
                .bold()
            ForEach(points, id: \.self) { point in
                Text("• \(point)")
            }
        }
        .padding(.leading)
    }
} 