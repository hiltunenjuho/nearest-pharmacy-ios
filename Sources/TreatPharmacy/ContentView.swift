import CoreLocation
import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var selectedPharmacyID: String?
    @State private var isAboutPresented = false

    private var selectedPharmacy: Pharmacy? {
        locationManager.pharmacies.first { $0.id == selectedPharmacyID } ?? locationManager.pharmacies.first
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
                    Button(action: locationManager.requestLocation) {
                        Text(locationManager.isLoading ? "Searching…" : "Find nearby")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                    }
                    .disabled(locationManager.isLoading)
                }

                if let error = locationManager.errorMessage {
                    Text(error)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let pharmacy = selectedPharmacy {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(pharmacy.name)
                            .font(.title2.bold())
                        Text(pharmacy.address.isEmpty ? "Address not provided" : pharmacy.address)
                            .foregroundStyle(.secondary)

                        if let userLocation = locationManager.location {
                            let distance = distanceInKilometers(
                                from: (userLocation.latitude, userLocation.longitude),
                                to: (lat: pharmacy.latitude, lon: pharmacy.longitude)
                            )
                            Label(distance < 1 ? "\(Int(distance * 1000)) m away" : String(format: "%.1f km away", distance), systemImage: "location")
                                .font(.subheadline)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("OPEN TODAY")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(pharmacy.hoursToday ?? "Hours unavailable")
                                .font(.headline)
                        }

                        if !pharmacy.currentWeekHours.isEmpty {
                            DisclosureGroup("This week’s hours") {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(Array(pharmacy.currentWeekHours.enumerated()), id: \.offset) { item in
                                        Text(item.element)
                                            .font(.caption)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding(.top, 6)
                            }
                        }

                        HStack(spacing: 12) {
                            if let callURL = pharmacy.callURL {
                                Link("Call \(pharmacy.phoneNumber ?? "pharmacy")", destination: callURL)
                            }
                            if let directionsURL = pharmacy.directionsURL {
                                Link("Get directions", destination: directionsURL)
                            }
                            if let mapsURL = pharmacy.mapsURL {
                                Link("View in Google Maps", destination: mapsURL)
                            }
                        }
                        .tint(.green)

                        Text("Pharmacy information from Google Maps")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Google Maps")
                            .environment(\.locale, Locale(identifier: "en"))
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                if locationManager.pharmacies.isEmpty {
                    ContentUnavailableView(
                        "No pharmacy results",
                        systemImage: "cross.case",
                        description: Text("Find your location to load nearby pharmacies from Google Maps.")
                    )
                } else {
                    List(locationManager.pharmacies) { pharmacy in
                        Button {
                            selectedPharmacyID = pharmacy.id
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
                                Text(pharmacy.address.isEmpty ? "Address not provided" : pharmacy.address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(pharmacy.hoursToday ?? "Hours unavailable")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
            .padding()
            .navigationTitle("Pharmacies")
            .background(Color.black.opacity(0.8))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAboutPresented = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("About this app")
            }
        }
        .sheet(isPresented: $isAboutPresented) {
            aboutSheet
        }
    }

    private var aboutSheet: some View {
        NavigationStack {
            List {
                Section("About") {
                    Text("Pharmacy Finder is a personal project by Juho Hiltunen.")
                    Text("© \(Calendar.current.component(.year, from: Date())) Juho Hiltunen")
                    Link("MIT License", destination: URL(string: "https://github.com/hiltunenjuho/nearest-pharmacy-ios/blob/main/LICENSE")!)
                }

                Section("Juho Hiltunen") {
                    Link("Portfolio", destination: URL(string: "https://hiltunenjuho.github.io/")!)
                    Link("GitHub", destination: URL(string: "https://github.com/hiltunenjuho")!)
                    Link("LinkedIn", destination: URL(string: "https://www.linkedin.com/in/hiltunenjuho/")!)
                }

                Section("Projects") {
                    Link("Web repository", destination: URL(string: "https://github.com/hiltunenjuho/nearest-pharmacy-web")!)
                    Link("iOS repository", destination: URL(string: "https://github.com/hiltunenjuho/nearest-pharmacy-ios")!)
                    Link("Live web demo", destination: URL(string: "https://hiltunenjuho.github.io/nearest-pharmacy-web/")!)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isAboutPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let placesClient = GooglePlacesClient()

    @Published var location: CLLocationCoordinate2D?
    @Published var pharmacies: [Pharmacy] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        errorMessage = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            isLoading = true
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isLoading = true
            manager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Location permission is unavailable. Enable it in Settings to find nearby pharmacies."
        @unknown default:
            errorMessage = "Location permission status is unknown."
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if isLoading {
                manager.requestLocation()
            }
        case .denied, .restricted:
            isLoading = false
            errorMessage = "Location permission is unavailable. Enable it in Settings to find nearby pharmacies."
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else {
            isLoading = false
            errorMessage = "Your location could not be determined. Try again."
            return
        }

        Task { @MainActor in
            location = latest.coordinate
            await loadPharmacies(near: latest.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isLoading = false
            errorMessage = "Could not determine your location: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func loadPharmacies(near coordinate: CLLocationCoordinate2D) async {
        do {
            pharmacies = try await placesClient.searchNearby(coordinate)
            if pharmacies.isEmpty {
                errorMessage = "No pharmacies were found within 50 km of your location."
            }
        } catch {
            pharmacies = []
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    ContentView()
}
