import Foundation

struct TideData: Codable {
    let status: Int
    let callCount: Int
    let requestLat: Double
    let requestLon: Double
    let responseLat: Double
    let responseLon: Double
    let atlas: String
    let copyright: String
    let heights: [TideHeight]
    let extremes: [TideExtreme]
    
    private enum CodingKeys: String, CodingKey {
        case status, callCount, requestLat, requestLon, responseLat, responseLon
        case atlas, copyright, heights, extremes
    }
}

struct TideHeight: Codable, Identifiable {
    let dt: TimeInterval
    let date: String
    let height: Double
    
    var id: TimeInterval { dt }
    
    private enum CodingKeys: String, CodingKey {
        case dt, date, height
    }
}

struct TideExtreme: Codable, Identifiable {
    let dt: TimeInterval
    let date: String
    let height: Double
    let type: String
    
    var id: TimeInterval { dt }
    var isHigh: Bool { type == "High" }
    
    private enum CodingKeys: String, CodingKey {
        case dt, date, height, type
    }
} 