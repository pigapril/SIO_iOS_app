import SwiftUI

// 主視圖：LegalView
struct LegalView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 使用 "legal.mainHeading" 作為頁面主標題
                Text("legal.mainHeading", bundle: .module)
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
        // 使用 "legal.pageTitle" 作為導航列標題
        .navigationTitle(Text("legal.pageTitle", bundle: .module))
    }
}

// 子視圖：LegalSection (無需修改，但保持清晰)
struct LegalSection: View {
    let titleKey: LocalizedStringKey
    let subsections: [LegalSubsection]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleKey, bundle: .module)
                .font(.title)
                .bold()
            ForEach(subsections) { subsection in
                subsection
            }
        }
    }
}

// 子視圖：LegalSubsection (已修正)
struct LegalSubsection: View, Identifiable {
    let id = UUID()
    let titleKey: LocalizedStringKey
    let introKey: LocalizedStringKey?
    let pointKeys: [String] // <--- *** 修正點 1: 型別改為 [String] ***

    // 初始化方法也更新參數型別
    init(titleKey: LocalizedStringKey, introKey: LocalizedStringKey? = nil, pointKeys: [String]) {
        self.titleKey = titleKey
        self.introKey = introKey
        self.pointKeys = pointKeys
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titleKey, bundle: .module)
                .font(.title2)
                .bold()
            
            if let intro = introKey {
                Text(intro, bundle: .module)
            }
            
            // <--- *** 修正點 2: ForEach 遍歷 String 陣列 ***
            ForEach(pointKeys, id: \.self) { key in
                HStack(alignment: .top) {
                    Text("•")
                    // <--- *** 修正點 3: 在此處將 String 轉為 LocalizedStringKey ***
                    Text(LocalizedStringKey(key), bundle: .module)
                }
            }
        }
        .padding(.leading)
    }
}