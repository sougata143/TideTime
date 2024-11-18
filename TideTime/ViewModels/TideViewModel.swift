import SwiftUI
import CoreLocation

@MainActor
class TideViewModel: ObservableObject {
    @Published var tideData: TideData?
    @Published var selectedLocation: Location? {
        didSet {
            if let location = selectedLocation {
                saveLocation(location)
                Task {
                    await fetchTideData(for: location)
                }
            }
        }
    }
    @Published var error: Error?
    
    private let tideService = TideService()
    private let locationKey = "selectedLocation"
    
    init() {
        loadSavedLocation()
    }
    
    func fetchTideData(for location: Location) async {
        self.error = nil
        self.tideData = nil
        
        do {
            tideData = try await tideService.fetchTideData(lat: location.lat, lon: location.lon)
        } catch {
            print("Error fetching tide data: \(error)")
            self.error = error
        }
    }
    
    private func saveLocation(_ location: Location) {
        if let encoded = try? JSONEncoder().encode(location) {
            UserDefaults.standard.set(encoded, forKey: locationKey)
        }
    }
    
    private func loadSavedLocation() {
        if let data = UserDefaults.standard.data(forKey: locationKey),
           let location = try? JSONDecoder().decode(Location.self, from: data) {
            selectedLocation = location
        }
    }
} 