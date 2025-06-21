import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image("aboutme_placeholder") // 圖片名稱通常不需要本地化
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                
                // --- 修改開始: 使用翻譯鍵 ---
                Text("about.heading", bundle: .module)
                    .font(.largeTitle)
                    .bold()
                
                // 使用修改後的 SectionView，直接傳入翻譯鍵
                SectionView(titleKey: "about.section1Title", textKey: "about.section1Text")
                
                SectionView(titleKey: "about.section2Title", textKey: "about.section2Text")

                SectionView(titleKey: "about.section3Title", textKey: "about.section3Text")

                Divider()

                // 聯絡方式區塊
                VStack(alignment: .leading, spacing: 10) {
                    Text("about.contactTitle", bundle: .module)
                        .font(.title2)
                        .bold()
                    HStack {
                        Image(systemName: "envelope.fill")
                        // Email 地址本身通常不翻譯
                        Link("support@sentimentinsideout.com", destination: URL(string: "mailto:support@sentimentinsideout.com")!)
                    }
                }
                // --- 修改結束 ---
            }
            .padding()
        }
        // --- 修改開始: 使用翻譯鍵 ---
        .navigationTitle(Text("about.pageTitle", bundle: .module))
        // --- 修改結束 ---
    }
}

// --- 修改開始: 內部輔助視圖 SectionView 現在接收 LocalizedStringKey ---
struct SectionView: View {
    let titleKey: LocalizedStringKey
    let textKey: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titleKey, bundle: .module)
                .font(.title2)
                .bold()
            Text(textKey, bundle: .module)
                .font(.body)
        }
    }
}
// --- 修改結束 ---