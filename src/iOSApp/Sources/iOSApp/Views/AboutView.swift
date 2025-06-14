import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image("aboutme_placeholder") // Replace with actual image name
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                
                Text("關於我們")
                    .font(.largeTitle)
                    .bold()
                
                SectionView(title: "我們的使命", text: "在資訊爆炸的時代，我們致力於提供最精準、最即時的市場情緒分析，幫助投資者洞悉市場動態，做出更明智的投資決策。")
                
                SectionView(title: "我們的技術", text: "我們結合了先進的自然語言處理（NLP）技術、機器學習模型以及大數據分析，從海量的市場資訊中，提煉出有價值的市場情緒指標。")

                SectionView(title: "我們的團隊", text: "我們的團隊由一群對金融科技充滿熱情的資料科學家、工程師和金融分析師組成，我們相信數據的力量，並致力於將複雜的數據轉化為簡單易懂的投資洞見。")

                Divider()

                HStack {
                    Image(systemName: "envelope.fill")
                    Link("support@sentimentinsideout.com", destination: URL(string: "mailto:support@sentimentinsideout.com")!)
                }
            }
            .padding()
        }
        .navigationTitle("關於")
    }
}

struct SectionView: View {
    let title: String
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.title2)
                .bold()
            Text(text)
                .font(.body)
        }
    }
} 