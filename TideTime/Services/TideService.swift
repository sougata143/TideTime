import Foundation

class TideService {
    // Get your API key from https://www.worldtides.info/developer
    private let apiKey = "YOUR_API_KEY" // Replace with your actual API key
    private let baseURL = "https://api.worldtides.info/v3"
    
    func fetchTideData(lat: Double, lon: Double) async throws -> TideData {
        var urlComponents = URLComponents(string: "\(baseURL)/heights")!
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "step", value: "900"), // 15-minute intervals
            URLQueryItem(name: "days", value: "2"),   // 2 days of data
            URLQueryItem(name: "datum", value: "LAT"), // Lowest Astronomical Tide
            URLQueryItem(name: "extremes", value: "true") // Include high/low tides
        ]
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Check for rate limit or other API-specific errors
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(TideErrorResponse.self, from: data)
            throw TideError(statusCode: httpResponse.statusCode, message: errorResponse?.error ?? "Unknown error")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(TideData.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "none")")
            throw error
        }
    }
}

struct TideErrorResponse: Codable {
    let error: String
}

struct TideError: LocalizedError {
    let statusCode: Int
    let message: String
    
    var errorDescription: String? {
        switch statusCode {
        case 401:
            return "Invalid API key"
        case 403:
            return "API quota exceeded"
        case 429:
            return "Too many requests. Please try again later."
        default:
            return message
        }
    }
} 