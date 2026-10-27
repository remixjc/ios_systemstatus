import SwiftUI

enum Palette {
    static let background = Color(red: 0.044, green: 0.047, blue: 0.09)
    static let card = Color(red: 0.135, green: 0.137, blue: 0.185)
    static let blue = Color(red: 0.02, green: 0.57, blue: 1)
    static let cyan = Color(red: 0.03, green: 0.76, blue: 0.87)
    static let green = Color(red: 0.18, green: 0.82, blue: 0.40)
    static let orange = Color(red: 1, green: 0.57, blue: 0.14)
    static let yellow = Color(red: 1, green: 0.81, blue: 0.03)
}

struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(15)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Palette.card)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                    }
            }
    }
}

extension View {
    func cardSurface() -> some View { modifier(CardSurface()) }
}

struct CardHeading: View {
    let title: String
    let icon: String
    let color: Color
    var subtitle: String? = nil
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(color).font(.system(size: 19, weight: .medium))
            Text(title).font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))
            if let subtitle {
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

struct Legend: View {
    let color: Color
    let text: String
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).font(.caption).foregroundStyle(.white.opacity(0.7)).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.65)
        }
    }
}

struct RingChart: View {
    let values: [(Double, Color)]
    var lineWidth: CGFloat = 10
    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.09), lineWidth: lineWidth)
            ForEach(values.indices, id: \.self) { index in
                let total = max(1, values.reduce(0) { $0 + max(0, $1.0) })
                let start = values.prefix(index).reduce(0) { $0 + max(0, $1.0) } / total
                let end = start + max(0, values[index].0) / total
                Circle().trim(from: start, to: end)
                    .stroke(values[index].1, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(lineWidth / 2)
        .accessibilityHidden(true)
    }
}

struct MiniGauge: View {
    let value: Double
    let color: Color
    var body: some View {
        ZStack {
            Circle().trim(from: 0, to: 0.72).stroke(.white.opacity(0.1), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            Circle().trim(from: 0, to: min(1, max(0, value)) * 0.72)
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
        .rotationEffect(.degrees(140))
        .frame(width: 30, height: 30)
        .accessibilityHidden(true)
    }
}

struct LiveChart: View {
    let points: [HistoryPoint]
    let now: Date
    let ceiling: Double
    let colors: [Color]
    let label: (Double) -> String
    var body: some View {
        HStack(spacing: 5) {
            VStack {
                Text(label(ceiling))
                Spacer()
                Text(label(ceiling / 2))
                Spacer()
                Text("0")
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.27))
            .frame(minWidth: 24, alignment: .trailing)
            Canvas { context, size in
                var grid = Path()
                for i in 0...4 {
                    let y = size.height * CGFloat(i) / 4
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                for i in 0...6 {
                    let x = size.width * CGFloat(i) / 6
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(grid, with: .color(.white.opacity(0.06)), lineWidth: 1)
                for series in 0..<2 {
                    var path = Path()
                    var lastDate: Date?
                    for point in points {
                        let age = now.timeIntervalSince(point.date)
                        let x = size.width * (1 - min(60, max(0, age)) / 60)
                        let value = series == 0 ? point.first : point.second
                        let y = size.height * (1 - min(1, max(0, value) / max(1, ceiling)))
                        let position = CGPoint(x: x, y: y)
                        if lastDate == nil || point.date.timeIntervalSince(lastDate!) > 3 {
                            path.move(to: position)
                        } else {
                            path.addLine(to: position)
                        }
                        lastDate = point.date
                    }
                    context.stroke(path, with: .color(colors[series]), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                }
            }
        }
        .frame(height: 64)
        .accessibilityHidden(true)
    }
}

struct SmallMetricCard: View {
    let title: String
    let icon: String
    let value: String
    let subtitle: String
    var color: Color = .white
    var gauge: Double? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CardHeading(title: title, icon: icon, color: .white.opacity(0.8))
            HStack(alignment: .center, spacing: 4) {
                Text(value).font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(color)
                    .monospacedDigit()
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let gauge { MiniGauge(value: gauge, color: color) }
            }
            Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
        .cardSurface()
        .contentShape(RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .combine)
    }
}
