import SwiftUI

struct ArticlesView: View {
    var body: some View {
        // 頁面中的主要標題，現在使用 .localized()
        Text("articles.heading".localized())
            // 導航欄上的標題，也更新為使用 .localized()
            .navigationTitle(Text("articles.pageTitle".localized()))
    }
}