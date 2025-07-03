// src/iOSApp/Sources/iOSAppSource/Views/AboutView.swift

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image("aboutme", bundle: .module) 
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                
                // --- 修改後：所有文字都使用 .localized() ---
                Text("about.heading".localized())
                    .font(.largeTitle)
                    .bold()
                
                // SectionView 也同樣使用 .localized()
                SectionView(titleKey: "about.section1Title", textKey: "about.section1Text")
                
                SectionView(titleKey: "about.section2Title", textKey: "about.section2Text")

                SectionView(titleKey: "about.section3Title", textKey: "about.section3Text")

                Divider()

                // 聯絡方式區塊
                VStack(alignment: .leading, spacing: 10) {
                    Text("about.contactTitle".localized())
                        .font(.title2)
                        .bold()
                    HStack {
                        Image(systemName: "envelope.fill")
                        // Email 地址本身不需翻譯
                        Link("support@sentimentinsideout.com", destination: URL(string: "mailto:support@sentimentinsideout.com")!)
                    }
                }
            }
            .padding()
        }
        // 導航標題也使用 .localized()
        .navigationTitle(Text("about.pageTitle".localized()))
    }
}

// 內部的 SectionView 現在也使用 .localized()
struct SectionView: View {
    let titleKey: String
    let textKey: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titleKey.localized())
                .font(.title2)
                .bold()
            Text(textKey.localized())
                .font(.body)
        }
    }
}