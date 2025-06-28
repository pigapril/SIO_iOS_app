// src/iOSApp/Sources/iOSAppSource/Views/LegalView.swift

import SwiftUI

// 主視圖：LegalView
struct LegalView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 使用新的 .localized() 方法來獲取翻譯字串
                Text("legal.mainHeading".localized())
                    .font(.largeTitle)
                    .bold()

                // 隱私權政策區塊
                LegalSection(
                    titleKey: "legal.privacyPolicyTitle",
                    subsections: [
                        LegalSubsection(
                            titleKey: "legal.dataCollectionTitle",
                            introKey: "legal.dataCollectionIntro",
                            pointKeys: [
                                "legal.dataCollectionItem1",
                                "legal.dataCollectionItem2",
                                "legal.dataCollectionItem3"
                            ]
                        ),
                        LegalSubsection(
                            titleKey: "legal.dataUsageTitle",
                            introKey: "legal.dataUsageIntro",
                            pointKeys: [
                                "legal.dataUsageItem1",
                                "legal.dataUsageItem2",
                                "legal.dataUsageItem3"
                            ]
                        ),
                        LegalSubsection(
                            titleKey: "legal.dataProtectionTitle",
                            introKey: "legal.dataProtectionIntro",
                            pointKeys: [
                                "legal.dataProtectionItem1",
                                "legal.dataProtectionItem2",
                                "legal.dataProtectionItem3"
                            ]
                        ),
                        LegalSubsection(
                            titleKey: "legal.userRightsTitle",
                            introKey: "legal.userRightsIntro",
                            pointKeys: [
                                "legal.userRightsItem1",
                                "legal.userRightsItem2",
                                "legal.userRightsItem3",
                                "legal.userRightsItem4"
                            ]
                        )
                    ]
                )

                // 服務條款區塊
                LegalSection(
                    titleKey: "legal.termsOfServiceTitle",
                    subsections: [
                        LegalSubsection(
                            titleKey: "legal.serviceDescriptionTitle",
                            introKey: "legal.serviceDescriptionIntro",
                            pointKeys: [
                                "legal.serviceDescriptionItem1",
                                "legal.serviceDescriptionItem2"
                            ]
                        ),
                        LegalSubsection(
                            titleKey: "legal.usageRulesTitle",
                            introKey: "legal.usageRulesIntro",
                            pointKeys: [
                                "legal.usageRulesItem1",
                                "legal.usageRulesItem2",
                                "legal.usageRulesItem3",
                                "legal.usageRulesItem4"
                            ]
                        ),
                        LegalSubsection(
                            titleKey: "legal.disclaimerTitle",
                            introKey: "legal.disclaimerIntro",
                            pointKeys: [
                                "legal.disclaimerItem1",
                                "legal.disclaimerItem2",
                                "legal.disclaimerItem3"
                            ]
                        )
                    ]
                )
            }
            .padding()
        }
        // 同樣使用 .localized() 設定導航列標題
        .navigationTitle(Text("legal.pageTitle".localized()))
    }
}

// 子視圖：LegalSection - 已修改為接受 String 型別的 key
struct LegalSection: View {
    let titleKey: String
    let subsections: [LegalSubsection]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleKey.localized())
                .font(.title)
                .bold()
            ForEach(subsections) { subsection in
                subsection
            }
        }
    }
}

// 子視圖：LegalSubsection - 已修改為接受 String 型別的 key
struct LegalSubsection: View, Identifiable {
    let id = UUID()
    let titleKey: String
    let introKey: String?
    let pointKeys: [String]

    init(titleKey: String, introKey: String? = nil, pointKeys: [String]) {
        self.titleKey = titleKey
        self.introKey = introKey
        self.pointKeys = pointKeys
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titleKey.localized())
                .font(.title2)
                .bold()
            
            if let intro = introKey {
                Text(intro.localized())
            }
            
            ForEach(pointKeys, id: \.self) { key in
                HStack(alignment: .top) {
                    Text("•")
                    // 將陣列中的每個 key 也進行本地化
                    Text(key.localized())
                }
            }
        }
        .padding(.leading)
    }
}