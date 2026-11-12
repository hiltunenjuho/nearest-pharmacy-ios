import CoreLocation
import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var selectedPharmacyID: String?
    @State private var isAboutPresented = false
    @AppStorage("pharmacyFinder.appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("pharmacyFinder.language") private var languagePreference = "system"

    private var selectedAppearance: AppearanceMode {
        AppearanceMode(rawValue: appearance) ?? .system
    }

    private var selectedLanguage: String {
        if languagePreference == "fi" || languagePreference == "en" {
            return languagePreference
        }
        return Locale.preferredLanguages.first?.lowercased().hasPrefix("fi") == true ? "fi" : "en"
    }

    private var localizedBundle: Bundle {
        guard let path = Bundle.module.path(forResource: selectedLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .module
        }
        return bundle
    }

    private func text(_ key: String) -> String {
        localizedBundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }

    private func todayHours(_ schedule: String?) -> String {
        guard let schedule, let hours = openingHoursForToday(schedule) else {
            return text(schedule == nil ? "hoursUnavailable" : "checkHours")
        }
        switch hours {
        case "Open 24 hours": return text("open24Hours")
        case "Closed today": return text("closedToday")
        default: return hours
        }
    }

    private func pharmacyName(_ name: String) -> String {
        name == "Pharmacy" ? text("unnamedPharmacy") : name
    }

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
                        Text(locationManager.isLoading ? text("searching") : text("findNearby"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                    }
                    .disabled(locationManager.isLoading)
                }

                if let errorKey = locationManager.errorMessageKey {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(text(errorKey))
                        if let details = locationManager.errorDetails {
                            Text(details)
                                .font(.caption)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let pharmacy = selectedPharmacy {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(pharmacyName(pharmacy.name))
                            .font(.title2.bold())
                        Text(pharmacy.address.isEmpty ? text("addressMissing") : pharmacy.address)
                            .foregroundStyle(.secondary)

                        if let userLocation = locationManager.location {
                            let distance = distanceInKilometers(
                                from: (userLocation.latitude, userLocation.longitude),
                                to: (lat: pharmacy.latitude, lon: pharmacy.longitude)
                            )
                            Label(distance < 1
                                ? "\(Int(distance * 1000)) \(text("metersAway"))"
                                : "\(String(format: "%.1f", locale: Locale(identifier: selectedLanguage), distance)) \(text("kilometersAway"))",
                                  systemImage: "location")
                                .font(.subheadline)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(text("openToday"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(todayHours(pharmacy.openingHours))
                                .font(.headline)
                            if pharmacy.openingHours != nil {
                                Text(text("hoursDisclaimer"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            if let callURL = pharmacy.callURL {
                                Link(String(format: text("callPhone"), pharmacy.phoneNumber ?? ""), destination: callURL)
                            }
                            if let directionsURL = pharmacy.directionsURL {
                                Link(text("directions"), destination: directionsURL)
                            }
                            Link(text("viewOnOSM"), destination: pharmacy.osmURL)
                        }
                        .tint(.green)

                        Text(text("dataAttribution"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(text("dataAttribution"))
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                if locationManager.pharmacies.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "cross.case")
                            .font(.largeTitle)
                        Text(text("noPharmacyResults"))
                            .font(.headline)
                        Text(text("findLocation"))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(locationManager.pharmacies) { pharmacy in
                        Button {
                            selectedPharmacyID = pharmacy.id
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(pharmacyName(pharmacy.name))
                                        .font(.headline)
                                    Spacer()
                                    if let userLocation = locationManager.location {
                                        let distance = distanceInKilometers(
                                            from: (userLocation.latitude, userLocation.longitude),
                                            to: (lat: pharmacy.latitude, lon: pharmacy.longitude)
                                        )
                                        Text(distance < 1
                                            ? "\(Int(distance * 1000)) \(text("metersAway"))"
                                            : "\(String(format: "%.1f", locale: Locale(identifier: selectedLanguage), distance)) \(text("kilometersAway"))")
                                            .foregroundStyle(.green)
                                            .fontWeight(.semibold)
                                    }
                                }
                                Text(pharmacy.address.isEmpty ? text("addressMissing") : pharmacy.address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(todayHours(pharmacy.openingHours))
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
            .navigationTitle(Text(text("pharmacies")))
        }
        .preferredColorScheme(selectedAppearance.colorScheme)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker(selection: $appearance, label: Text(text("appearance"))) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(text(mode.titleKey)).tag(mode.rawValue)
                        }
                    }
                } label: {
                    Image(systemName: selectedAppearance.symbol)
                }
                .accessibilityLabel(text("appearance"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    languagePreference = selectedLanguage == "fi" ? "en" : "fi"
                } label: {
                    Text(selectedLanguage == "fi" ? "EN" : "FI")
                        .font(.caption.bold())
                }
                .accessibilityLabel(text("switchLanguage"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAboutPresented = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel(text("openInfo"))
            }
        }
        .sheet(isPresented: $isAboutPresented) {
            aboutSheet
        }
    }

    private var aboutSheet: some View {
        NavigationStack {
            List {
                Section {
                    Text(text("infoIntro"))
                    Text(String(format: text("copyright"), Calendar.current.component(.year, from: Date())))
                    Link(text("mitLicense"), destination: URL(string: "https://github.com/hiltunenjuho/nearest-pharmacy-ios/blob/main/LICENSE")!)
                    Link(text("dataAttribution"), destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                } header: {
                    Text(text("aboutTitle"))
                }

                Section {
                    Text(text("howItWorks"))
                } header: {
                    Text(text("howItWorksTitle"))
                }

                Section {
                    Text(text("dataInformation"))
                } header: {
                    Text(text("dataTitle"))
                }

                Section {
                    Text(text("privacyInformation"))
                } header: {
                    Text(text("privacyTitle"))
                }

                Section {
                    Link(text("portfolio"), destination: URL(string: "https://hiltunenjuho.github.io/")!)
                    Link("GitHub", destination: URL(string: "https://github.com/hiltunenjuho")!)
                    Link("LinkedIn", destination: URL(string: "https://www.linkedin.com/in/hiltunenjuho/")!)
                } header: {
                    Text(text("authorTitle"))
                }

                Section {
                    Link(text("webRepository"), destination: URL(string: "https://github.com/hiltunenjuho/nearest-pharmacy-web")!)
                    Link(text("iosRepository"), destination: URL(string: "https://github.com/hiltunenjuho/nearest-pharmacy-ios")!)
                    Link(text("liveDemo"), destination: URL(string: "https://hiltunenjuho.github.io/nearest-pharmacy-web/")!)
                } header: {
                    Text(text("projectsTitle"))
                }
            }
            .navigationTitle(Text(text("aboutTitle")))
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(selectedAppearance.colorScheme)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isAboutPresented = false
                    } label: {
                        Text(text("done"))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private enum AppearanceMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }
        var titleKey: String {
            switch self {
            case .system: "system"
            case .light: "light"
            case .dark: "dark"
            }
        }
        var symbol: String {
            switch self {
            case .system: "circle.lefthalf.filled"
            case .light: "sun.max"
            case .dark: "moon"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let placesClient = OpenStreetMapClient()

    @Published var location: CLLocationCoordinate2D?
    @Published var pharmacies: [Pharmacy] = []
    @Published var isLoading = false
    @Published var errorMessageKey: String?
    @Published var errorDetails: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        errorMessageKey = nil
        errorDetails = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            isLoading = true
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isLoading = true
            manager.requestLocation()
        case .denied, .restricted:
            errorMessageKey = "locationPermission"
        @unknown default:
            errorMessageKey = "locationUnknown"
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
            errorMessageKey = "locationPermission"
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else {
            isLoading = false
            errorMessageKey = "locationUnavailable"
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
            errorMessageKey = "locationFailed"
            errorDetails = error.localizedDescription
        }
    }

    @MainActor
    private func loadPharmacies(near coordinate: CLLocationCoordinate2D) async {
        do {
            pharmacies = try await placesClient.searchNearby(coordinate)
            if pharmacies.isEmpty {
                errorMessageKey = "noResults"
                errorDetails = nil
            }
        } catch {
            pharmacies = []
            errorMessageKey = "searchFailed"
            errorDetails = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    ContentView()
}
