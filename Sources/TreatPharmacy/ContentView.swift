import CoreLocation
import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var selectedPharmacy: Pharmacy?

    var sortedPharmacies: [Pharmacy] {
        guard let userLocation = locationManager.location else {
            return allPharmacies
        }

        return allPharmacies.sorted {
            let leftDistance = distanceInKilometers(from: (userLocation.latitude, userLocation.longitude), to: (lat: $0.latitude, lon: $0.longitude))
            let rightDistance = distanceInKilometers(from: (userLocation.latitude, userLocation.longitude), to: (lat: $1.latitude, lon: $1.longitude))
            return leftDistance < rightDistance
        }
    }

    private var currentPharmacy: Pharmacy {
        selectedPharmacy ?? sortedPharmacies.first ?? allPharmacies[0]
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Juho Hiltunen")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .textCase(.uppercase)
                        Text("Pharmacy Finder")
                            .font(.largeTitle.bold())
                    }
                    Spacer()
                    Button(action: {
                        locationManager.requestLocation()
                    }) {
                        Text(locationManager.isLoading ? "Finding…" : "Use my location")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                    }
                }

                if let error = locationManager.errorMessage {
                    Text(error)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                List(sortedPharmacies) { pharmacy in
                    Button {
                        selectedPharmacy = pharmacy
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(pharmacy.name)
                                    .font(.headline)
                                Spacer()
                                if let userLocation = locationManager.location {
                                    let distance = distanceInKilometers(
                                        from: (userLocation.latitude, userLocation.longitude),
                                        to: (lat: pharmacy.latitude, lon: pharmacy.longitude)
                                    )
                                    Text(distance < 1 ? "\(Int(distance * 1000)) m" : String(format: "%.1f km", distance))
                                        .foregroundStyle(.green)
                                        .fontWeight(.semibold)
                                }
                            }
                            Text("\(pharmacy.address), \(pharmacy.city)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(pharmacy.hours)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)

                VStack(alignment: .leading, spacing: 12) {
                    Text(currentPharmacy.name)
                        .font(.title2.bold())
                    Text("\(currentPharmacy.address), \(currentPharmacy.city)")
                        .foregroundStyle(.secondary)

                    HStack {
                        Label(currentPharmacy.hours, systemImage: "clock")
                        Spacer()
                        if let userLocation = locationManager.location {
                            let distance = distanceInKilometers(
                                from: (userLocation.latitude, userLocation.longitude),
                                to: (lat: currentPharmacy.latitude, lon: currentPharmacy.longitude)
                            )
                            Label(distance < 1 ? "\(Int(distance * 1000)) m" : String(format: "%.1f km", distance), systemImage: "location")
                        }
                    }
                    .font(.subheadline)

                    HStack {
                        ForEach(currentPharmacy.facts, id: \ .self) { fact in
                            Text(fact)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.12))
                                .clipShape(Capsule())
                                .font(.caption)
                        }
                    }
                    .padding(.top, 8)

                    HStack {
                        Link("Get directions", destination: URL(string: "https://www.google.com/maps/search/?api=1&query=\(currentPharmacy.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? currentPharmacy.address)")!)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding()
            .navigationTitle("Pharmacies")
            .background(Color.black.opacity(0.8))
        }
    }
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var location: CLLocationCoordinate2D?
    @Published var isLoading = false
    @Published var errorMessage: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        isLoading = true
        errorMessage = nil
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        location = latest.coordinate
        isLoading = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location access was denied. Showing the nearest options across the Helsinki Metropolitan Area."
        isLoading = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            requestLocation()
        }
    }
}

#Preview {
    ContentView()
}
