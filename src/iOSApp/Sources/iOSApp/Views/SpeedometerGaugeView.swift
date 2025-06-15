import SwiftUI

struct SpeedometerGaugeView: View {
    let value: Double // 0 to 100
    @ObservedObject var viewModel: MarketSentimentViewModel

    // 將情緒和顏色計算移至此處，使其更獨立
    private var sentiment: String { viewModel.sentiment(for: value) }
    private var color: Color { viewModel.sentimentColor(for: sentiment) }
    
    // 計算指針的旋轉角度 (-90度為最左，+90度為最右)
    private var needleRotation: Angle {
        let normalizedValue = value / 100.0
        let degrees = normalizedValue * 180.0 - 90.0
        return .degrees(degrees)
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // 1. 背景漸層弧形
                GaugeBackground()
                
                // 2. 指針
                Needle()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: 4, height: 90)
                    .offset(y: -45) // 將指針向上移動，使其底部在中心點
                    .rotationEffect(needleRotation)
                    .animation(.spring(response: 0.7, dampingFraction: 0.6, blendDuration: 0.8), value: value)

                // 3. 中心的樞軸點
                Circle()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: 15, height: 15)
                Circle()
                    .fill(.white)
                    .frame(width: 7, height: 7)
            }
            .frame(width: 250, height: 125) // 設定儀表板的大小
            .clipped() // 確保 ZStack 之外的內容被裁切

            // 4. 顯示數值和情緒狀態
            VStack {
                Text(String(format: "%.0f", value))
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                Text(LocalizedStringKey(sentiment), bundle: .module)
                    .font(.title3.bold())
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 儀表板背景
struct GaugeBackground: View {
    var body: some View {
        ZStack {
            // 背景底色
            Circle()
                .trim(from: 0.5, to: 1.0)
                .stroke(Color(.systemGray5), lineWidth: 50)
            
            // 漸層色
            Circle()
                .trim(from: 0.5, to: 1.0)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#0000FF"), // 極度恐懼
                            Color(hex: "#5B9BD5"), // 恐懼
                            Color(hex: "#708090"), // 中性
                            Color(hex: "#F0B8CE"), // 貪婪
                            Color(hex: "#D24A93")  // 極度貪婪
                        ]),
                        center: .center,
                        startAngle: .degrees(180),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 50, lineCap: .butt)
                )

            // 底部標籤
            VStack {
                Spacer()
                HStack {
                    Text("sentiment.extremeFear", bundle: .module)
                    Spacer()
                    Text("sentiment.extremeGreed", bundle: .module)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
            }
        }
    }
}

// 指針形狀
struct Needle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}