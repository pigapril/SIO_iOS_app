import SwiftUI

// 將 SemiCircleGaugeView 宣告為 public，這樣模組內的其他檔案才能存取
public struct SemiCircleGaugeView: View {
    let value: Double
    let showLabels: Bool

    // 建立一個 public 的初始化方法
    public init(value: Double, showLabels: Bool = true) {
        self.value = value
        self.showLabels = showLabels
    }
    
    private var sentimentGradient: AngularGradient {
        let colors = [
            AppColors.minus2SD,
            AppColors.minus1SD,
            AppColors.trend,
            AppColors.plus1SD,
            AppColors.plus2SD
        ]
        return AngularGradient(
            gradient: Gradient(colors: colors),
            center: .center,
            startAngle: .degrees(180),
            endAngle: .degrees(360)
        )
    }

    public var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height)
            let radius = min(geometry.size.width / 2, geometry.size.height) * 0.9
            let lineWidth = radius * 0.25
            let needleRotation = Angle.degrees((value / 100.0) * 180.0 - 90.0)
            
            ZStack {
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                    
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(sentimentGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 5)

                NeedleShape()
                    .fill(Color(.secondaryLabel))
                    .frame(width: radius * 0.05, height: radius * 0.7)
                    .offset(y: -radius * 0.35)
                    .rotationEffect(needleRotation)
                    .position(center)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 3)
                    .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.6), value: value)
                
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
                    
                    Text(String(format: "%.0f", value))
                        .font(.system(size: radius * 0.15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(.label))
                }
                .frame(width: lineWidth * 1.2, height: lineWidth * 1.2)
                .position(center)
                    
                if showLabels {
                    HStack {
                        Text("sentiment.extremeFear".localized())
                        Spacer()
                        Text("sentiment.extremeGreed".localized())
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: radius * 2.6)
                    .position(x: center.x, y: center.y + 35)
                }
            }
        }
    }
}

// 這個 Shape 只被 SemiCircleGaugeView 使用，所以可以保持 private
private struct NeedleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.midY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.maxX, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}