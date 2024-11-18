import SwiftUI
import CoreLocation

struct LocationSearchView: View {
    @ObservedObject var viewModel: TideViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var locations: [Location] = []
    
    private let searchCompleter = LocationCompleter()
    
    var body: some View {
        List {
            ForEach(locations) { location in
                Button {
                    viewModel.selectedLocation = location
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(location.name)
                            .foregroundColor(.primary)
                        Text("\(location.lat), \(location.lon)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Search Location")
        .searchable(text: $searchText)
        .onChange(of: searchText) { newValue in
            searchCompleter.search(text: newValue) { locations in
                self.locations = locations
            }
        }
    }
}

// Helper class to handle location search
class LocationCompleter {
    private let searchCompleter = CLGeocoder()
    
    func search(text: String, completion: @escaping ([Location]) -> Void) {
        guard !text.isEmpty else {
            completion([])
            return
        }
        
        searchCompleter.geocodeAddressString(text) { placemarks, error in
            let locations = placemarks?.compactMap { placemark -> Location? in
                guard let name = placemark.name,
                      let location = placemark.location else { return nil }
                
                return Location(
                    id: "\(location.coordinate.latitude),\(location.coordinate.longitude)",
                    name: name,
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude
                )
            } ?? []
            
            DispatchQueue.main.async {
                completion(locations)
            }
        }
    }
}

#Preview {
    NavigationView {
        LocationSearchView(viewModel: TideViewModel())
    }
} 