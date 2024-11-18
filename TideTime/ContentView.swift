//
//  ContentView.swift
//  TideTime
//
//  Created by SOUGATA ROY on 11/8/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TideViewModel()
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let error = viewModel.error {
                    ContentUnavailableView {
                        Label("Error Loading Data", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.localizedDescription)
                    } actions: {
                        Button("Try Again") {
                            if let location = viewModel.selectedLocation {
                                Task {
                                    await viewModel.fetchTideData(for: location)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if viewModel.selectedLocation == nil {
                    ContentUnavailableView {
                        Label("No Location Selected", systemImage: "location.slash")
                    } description: {
                        Text("Please select a location to view tide information")
                    } actions: {
                        NavigationLink(destination: LocationSearchView(viewModel: viewModel)) {
                            Text("Select Location")
                                .frame(minWidth: 200)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                } else if let tideData = viewModel.tideData {
                    ScrollView {
                        VStack(spacing: 0) {
                            TideGraphView(tideData: tideData)
                                .frame(height: 300)
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.05), radius: 10)
                                .padding()
                            
                            TideInfoView(tideData: tideData)
                        }
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(viewModel.selectedLocation?.name ?? "Tide Time")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: LocationSearchView(viewModel: viewModel)) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
