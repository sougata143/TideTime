struct Location: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let lat: Double
    let lon: Double
    
    static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.id == rhs.id
    }
} 