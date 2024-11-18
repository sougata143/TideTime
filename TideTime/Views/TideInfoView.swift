import SwiftUI

struct TideInfoView: View {
    let tideData: TideData
    
    init(tideData: TideData) {
        self.tideData = tideData
    }
    
    private var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    private var next24HourExtremes: [TideExtreme] {
        let now = Date().timeIntervalSince1970
        return tideData.extremes
            .filter { $0.dt > now && $0.dt <= now + 24 * 3600 }
            .sorted { $0.dt < $1.dt }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Current tide info
            currentTideView
            
            // Next 24 hours extremes
            extremesListView
        }
        .padding()
    }
    
    private var currentTideView: some View {
        VStack(spacing: 16) {
            Text("Current Tide")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .bottom, spacing: 20) {
                if let currentHeight = interpolatedCurrentHeight() {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "%.1f m", currentHeight))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                        
                        Text("Height")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let trend = getTideTrend() {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: trend.icon)
                                .imageScale(.large)
                            Text(trend.description)
                        }
                        .foregroundStyle(trend.color)
                        
                        Text("Trend")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
    
    private var extremesListView: some View {
        VStack(spacing: 16) {
            Text("Next 24 Hours")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 2) {
                ForEach(next24HourExtremes) { extreme in
                    HStack {
                        Image(systemName: extreme.isHigh ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundStyle(extreme.isHigh ? Color.blue : Color.indigo)
                        
                        VStack(alignment: .leading) {
                            Text(extreme.isHigh ? "High Tide" : "Low Tide")
                                .font(.system(.body, design: .rounded))
                            Text(Date(timeIntervalSince1970: extreme.dt), formatter: timeFormatter)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "%.1f m", extreme.height))
                            .font(.system(.body, design: .rounded))
                            .bold()
                    }
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
    
    private func interpolatedCurrentHeight() -> Double? {
        let now = Date().timeIntervalSince1970
        guard let after = tideData.heights.first(where: { $0.dt > now }),
              let beforeIndex = tideData.heights.firstIndex(where: { $0.dt > now }).map({ $0 - 1 }),
              beforeIndex >= 0 else {
            return tideData.heights.first?.height
        }
        
        let before = tideData.heights[beforeIndex]
        
        let timeDiff = after.dt - before.dt
        let heightDiff = after.height - before.height
        let progressBetweenPoints = (now - before.dt) / timeDiff
        
        return before.height + (heightDiff * progressBetweenPoints)
    }
    
    private func getTideTrend() -> TideTrend? {
        guard let currentHeight = interpolatedCurrentHeight(),
              let nextExtreme = next24HourExtremes.first else {
            return nil
        }
        
        if nextExtreme.isHigh {
            return TideTrend(
                icon: "arrow.up.right",
                description: "Rising",
                color: .blue
            )
        } else {
            return TideTrend(
                icon: "arrow.down.right",
                description: "Falling",
                color: .indigo
            )
        }
    }
}

private struct TideTrend {
    let icon: String
    let description: String
    let color: Color
}

#Preview {
    TideInfoView(tideData: TideData(
        status: 200,
        callCount: 1,
        requestLat: 0,
        requestLon: 0,
        responseLat: 0,
        responseLon: 0,
        atlas: "NOAA",
        copyright: "Tide data is for testing only",
        heights: [
            TideHeight(dt: Date().timeIntervalSince1970 - 3600, date: "2024-02-20 17:00", height: 1.0),
            TideHeight(dt: Date().timeIntervalSince1970 + 3600, date: "2024-02-20 19:00", height: 1.5)
        ],
        extremes: [
            TideExtreme(dt: Date().timeIntervalSince1970 + 7200, date: "2024-02-20 20:00", height: 2.0, type: "High"),
            TideExtreme(dt: Date().timeIntervalSince1970 + 14400, date: "2024-02-20 22:00", height: 0.5, type: "Low")
        ]
    ))
    .preferredColorScheme(.dark)
}


