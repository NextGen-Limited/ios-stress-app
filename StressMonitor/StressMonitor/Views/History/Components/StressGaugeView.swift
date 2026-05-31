import SwiftUI

struct StressGaugeView: View {
    let level: Double
    let category: StressCategory

    var body: some View {
        ZStack {
            Path { path in
                path.addArc(
                    center: CGPoint(x: 100, y: 100),
                    radius: 80,
                    startAngle: .degrees(150),
                    endAngle: .degrees(30),
                    clockwise: false
                )
            }
            .stroke(Color.secondary.opacity(0.2), lineWidth: 20)

            ZStack {
                Path { path in
                    path.addArc(
                        center: CGPoint(x: 100, y: 100),
                        radius: 80,
                        startAngle: .degrees(150),
                        endAngle: .degrees(180),
                        clockwise: false
                    )
                }
                .stroke(Color.stressRelaxed, style: StrokeStyle(lineWidth: 20, lineCap: .butt))

                Path { path in
                    path.addArc(
                        center: CGPoint(x: 100, y: 100),
                        radius: 80,
                        startAngle: .degrees(180),
                        endAngle: .degrees(210),
                        clockwise: false
                    )
                }
                .stroke(Color.stressMild, style: StrokeStyle(lineWidth: 20, lineCap: .butt))

                Path { path in
                    path.addArc(
                        center: CGPoint(x: 100, y: 100),
                        radius: 80,
                        startAngle: .degrees(210),
                        endAngle: .degrees(240),
                        clockwise: false
                    )
                }
                .stroke(Color.stressModerate, style: StrokeStyle(lineWidth: 20, lineCap: .butt))

                Path { path in
                    path.addArc(
                        center: CGPoint(x: 100, y: 100),
                        radius: 80,
                        startAngle: .degrees(240),
                        endAngle: .degrees(30),
                        clockwise: false
                    )
                }
                .stroke(Color.stressHigh, style: StrokeStyle(lineWidth: 20, lineCap: .butt))
            }

            let angle = needleAngle(for: level)
            Path { path in
                path.move(to: CGPoint(x: 100, y: 100))
                path.addLine(to: CGPoint(
                    x: 100 + cos(angle) * 60,
                    y: 100 + sin(angle) * 60
                ))
            }
            .stroke(Color.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .shadow(color: .black.opacity(0.2), radius: 2)

            Circle()
                .fill(Color.primary)
                .frame(width: 12, height: 12)

            VStack {
                Spacer()
                Text("\(Int(level))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("out of 100")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)
            }
            .offset(y: 140)
        }
        .frame(width: 200, height: 200)
    }

    private func needleAngle(for value: Double) -> Double {
        let normalized = value / 100.0
        let startAngle = 150.0
        let endAngle = 30.0
        let degrees = startAngle + (endAngle - startAngle) * normalized
        return degrees * .pi / 180
    }
}
