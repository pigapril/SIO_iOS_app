import SwiftUI

struct ArticlesView: View {
    var body: some View {
        // 頁面中的主要標題，對應 "articles.heading"
        // 您之後可能會將此 Text 替換為實際的文章列表
        Text("articles.heading", bundle: .module)
            // 導航欄上的標題，對應 "articles.pageTitle"
            .navigationTitle(Text("articles.pageTitle", bundle: .module))
    }
}