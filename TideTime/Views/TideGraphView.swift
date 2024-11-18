import SwiftUI

struct TideGraphView: View {
    let tideData: TideData
    
    @State private var animationProgress: CGFloat = 0
    
    private var relevantHeights: [TideHeight] {
        let now = Date().timeIntervalSince1970
        return tideData.heights
            .filter { abs($0.dt - now) < 12 * 3600 }
            .sorted { $0.dt < $1.dt }
    }
    
    private var heightRange: (min: Double, max: Double) {
        let heights = relevantHeights.map { $0.height }
        guard let min = heights.min(),
              let max = heights.max() else {
            return (0, 1)
        }
        let padding = (max - min) * 0.1
        return (min - padding, max + padding)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Time markers
                timeAxisView(in: geometry.size)
                
                // Height markers
                heightAxisView(in: geometry.size)
                
                // Tide curve
                tideCurveView(in: geometry.size)
                    .trim(from: 0, to: animationProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue.opacity(0.7), .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                
                // Current time indicator
                currentTimeIndicator(in: geometry.size)
                
                // Extreme points
                extremePointsView(in: geometry.size)
            }
            .padding(.horizontal)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
    
    private func timeAxisView(in size: CGSize) -> some View {
        let hours = Array(stride(from: -12, through: 12, by: 6))
        return ForEach(hours, id: \.self) { hour in
            let x = xPosition(for: Date().timeIntervalSince1970 + Double(hour * 3600), in: size)
            VStack {
                Spacer()
                Text(formatHour(hour))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .offset(x: x)
        }
    }
    
    private func heightAxisView(in size: CGSize) -> some View {
        let heights = Array(stride(
            from: floor(heightRange.min),
            through: ceil(heightRange.max),
            by: 0.5
        ))
        return ForEach(heights, id: \.self) { height in
            let y = yPosition(for: height, in: size)
            HStack {
                Text(String(format: "%.1fm", height))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .offset(y: y)
        }
    }
    
    private func tideCurveView(in size: CGSize) -> Path {
        Path { path in
            guard let firstPoint = relevantHeights.first else { return }
            
            let points = relevantHeights.map { height in
                CGPoint(
                    x: xPosition(for: height.dt, in: size),
                    y: yPosition(for: height.height, in: size)
                )
            }
            
            path.move(to: points[0])
            
            for i in 1..<points.count {
                let previous = points[i - 1]
                let current = points[i]
                
                let control1 = CGPoint(
                    x: previous.x + (current.x - previous.x) / 2,
                    y: previous.y
                )
                let control2 = CGPoint(
                    x: previous.x + (current.x - previous.x) / 2,
                    y: current.y
                )
                
                path.addCurve(
                    to: current,
                    control1: control1,
                    control2: control2
                )
            }
        }
    }
    
    private func currentTimeIndicator(in size: CGSize) -> some View {
        let now = Date().timeIntervalSince1970
        if let currentHeight = interpolatedHeight(at: now) {
            return AnyView(
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .shadow(color: .red.opacity(0.3), radius: 4)
                    .position(
                        x: xPosition(for: now, in: size),
                        y: yPosition(for: currentHeight, in: size)
                    )
            )
        }
        return AnyView(EmptyView())
    }
    
    private func extremePointsView(in size: CGSize) -> some View {
        ForEach(tideData.extremes.filter { isInRange($0.dt) }) { extreme in
            VStack(spacing: 4) {
                Text(extreme.isHigh ? "H" : "L")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Circle()
                    .fill(extreme.isHigh ? Color.blue : Color.indigo)
                    .frame(width: 6, height: 6)
            }
            .position(
                x: xPosition(for: extreme.dt, in: size),
                y: yPosition(for: extreme.height, in: size)
            )
        }
    }
    
    private func xPosition(for timestamp: TimeInterval, in size: CGSize) -> CGFloat {
        let timeRange = relevantHeights.last!.dt - relevantHeights.first!.dt
        let relativePosition = (timestamp - relevantHeights.first!.dt) / timeRange
        return size.width * CGFloat(relativePosition)
    }
    
    private func yPosition(for height: Double, in size: CGSize) -> CGFloat {
        let range = heightRange.max - heightRange.min
        let relativeHeight = (height - heightRange.min) / range
        return size.height * (1 - CGFloat(relativeHeight))
    }
    
    private func interpolatedHeight(at timestamp: TimeInterval) -> Double? {
        guard let after = relevantHeights.first(where: { $0.dt > timestamp }),
              let beforeIndex = relevantHeights.firstIndex(where: { $0.dt > timestamp }).map({ $0 - 1 }),
              beforeIndex >= 0 else {
            return nil
        }
        
        let before = relevantHeights[beforeIndex]
        let timeDiff = after.dt - before.dt
        let heightDiff = after.height - before.height
        let progress = (timestamp - before.dt) / timeDiff
        
        return before.height + (heightDiff * progress)
    }
    
    private func isInRange(_ timestamp: TimeInterval) -> Bool {
        let now = Date().timeIntervalSince1970
        return abs(timestamp - now) < 12 * 3600
    }
    
    private func formatHour(_ hourOffset: Int) -> String {
        let date = Date(timeIntervalSince1970: Date().timeIntervalSince1970 + Double(hourOffset * 3600))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct TideGraphView_Previews: PreviewProvider {
    static var previews: some View {
        let mockTideData = TideData(
            status: 200,
            callCount: 1,
            requestLat: 0,
            requestLon: 0,
            responseLat: 0,
            responseLon: 0,
            atlas: "NOAA",
            copyright: "Tide data is for testing only",
            heights: [
                TideHeight(dt: Date().timeIntervalSince1970 - 6 * 3600, date: "2024-02-20 12:00", height: 1.0),
                TideHeight(dt: Date().timeIntervalSince1970 - 3 * 3600, date: "2024-02-20 15:00", height: 2.0),
                TideHeight(dt: Date().timeIntervalSince1970, date: "2024-02-20 18:00", height: 1.5),
                TideHeight(dt: Date().timeIntervalSince1970 + 3 * 3600, date: "2024-02-20 21:00", height: 0.5),
                TideHeight(dt: Date().timeIntervalSince1970 + 6 * 3600, date: "2024-02-21 00:00", height: 1.0)
            ],
            extremes: [
                TideExtreme(dt: Date().timeIntervalSince1970 - 3 * 3600, date: "2024-02-20 15:00", height: 2.0, type: "High"),
                TideExtreme(dt: Date().timeIntervalSince1970 + 3 * 3600, date: "2024-02-20 21:00", height: 0.5, type: "Low")
            ]
        )
        
        return Group {
            TideGraphView(tideData: mockTideData)
                .frame(height: 300)
                .padding()
                .previewLayout(.sizeThatFits)
            
            TideGraphView(tideData: mockTideData)
                .frame(height: 300)
                .padding()
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
        }
    }
} 