import CoreLocation
import SwiftUI

public struct PharmacyFinderView: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @StateObject private var locationManager = LocationManager()
    @State private var selectedPharmacyID: String?
    @State private var isAboutPresented = false
    @AppStorage("pharmacyFinder.appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("pharmacyFinder.language") private var languagePreference = "system"

    public init() {}

    private var selectedAppearance: AppearanceMode {
        AppearanceMode(rawValue: appearance) ?? .system
    }

    private var effectiveColorScheme: ColorScheme {
        selectedAppearance.colorScheme ?? systemColorScheme
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

    private func todayHours(_ hours: String?) -> String {
        guard let hours, !hours.isEmpty else { return text("hoursUnavailable") }
        return hours
    }

    private func pharmacyName(_ name: String) -> String {
        name == "Pharmacy" ? text("unnamedPharmacy") : name
    }

    private func toggleTheme() {
        appearance = effectiveColorScheme == .dark ? AppearanceMode.light.rawValue : AppearanceMode.dark.rawValue
    }

    private var languageToggle: some View {
        Button {
            languagePreference = selectedLanguage == "fi" ? "en" : "fi"
        } label: {
            ZStack(alignment: selectedLanguage == "fi" ? .trailing : .leading) {
                Capsule()
                    .fill(Color.green)
                    .frame(width: 32, height: 26)
                    .padding(3)
                HStack(spacing: 0) {
                    Text("EN")
                        .foregroundStyle(selectedLanguage == "en" ? Color.white : Color.gray)
                        .frame(maxWidth: .infinity)
                    Text("FI")
                        .foregroundStyle(selectedLanguage == "fi" ? Color.white : Color.gray)
                        .frame(maxWidth: .infinity)
                }
                .font(.caption.bold())
                .frame(width: 68, height: 32)
            }
            .background(.thinMaterial, in: Capsule())
            .animation(.easeInOut(duration: 0.22), value: selectedLanguage)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text("switchLanguage"))
        .accessibilityValue(selectedLanguage == "fi" ? "FI" : "EN")
    }

    private var themeToggle: some View {
        Button(action: toggleTheme) {
            ZStack(alignment: effectiveColorScheme == .dark ? .trailing : .leading) {
                Capsule()
                    .fill(Color.green)
                    .frame(width: 32, height: 26)
                    .padding(3)
                HStack(spacing: 0) {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(effectiveColorScheme == .light ? Color.white : Color.gray)
                        .frame(maxWidth: .infinity)
                    Image(systemName: "moon.fill")
                        .foregroundStyle(effectiveColorScheme == .dark ? Color.white : Color.gray)
                        .frame(maxWidth: .infinity)
                }
                .font(.caption.bold())
                .frame(width: 68, height: 32)
            }
            .background(.thinMaterial, in: Capsule())
            .animation(.easeInOut(duration: 0.22), value: effectiveColorScheme)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text("appearance"))
        .accessibilityValue(effectiveColorScheme == .dark ? text("dark") : text("light"))
    }

    private var selectedPharmacy: Pharmacy? {
        locationManager.pharmacies.first { $0.id == selectedPharmacyID } ?? locationManager.pharmacies.first
    }

    public var body: some View {
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
                    Button {
                        locationManager.requestLocation(language: selectedLanguage)
                    } label: {
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
                            Text(todayHours(pharmacy.todayHours))
                                .font(.headline)
                            if !pharmacy.openingHours.isEmpty {
                                Text(text("hoursDisclaimer"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if !pharmacy.openingHours.isEmpty {
                            DisclosureGroup(text("fullSchedule")) {
                                ForEach(pharmacy.openingHours, id: \.self) { day in
                                    Text(day)
                                }
                            }
                            .font(.subheadline)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            if let callURL = pharmacy.callURL {
                                Link(String(format: text("callPhone"), pharmacy.phoneNumber ?? ""), destination: callURL)
                            }
                            if let directionsURL = pharmacy.directionsURL {
                                Link(text("directions"), destination: directionsURL)
                            }
                            Link(text("viewOnGoogle"), destination: pharmacy.mapsURL)
                        }
                        .tint(.green)

                        Link(text("dataAttribution"), destination: URL(string: "https://maps.google.com/")!)
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
                                Text(todayHours(pharmacy.todayHours))
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
                themeToggle
            }
            ToolbarItem(placement: .topBarTrailing) {
                languageToggle
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
                    Text(text("infoPortfolio"))
                    Text(String(format: text("copyright"), Calendar.current.component(.year, from: Date())))
                    Link(text("mitLicense"), destination: URL(string: "https://github.com/hiltunenjuho/nearest-pharmacy-ios/blob/main/LICENSE")!)
                    Link(text("dataAttribution"), destination: URL(string: "https://maps.google.com/")!)
                } header: {
                    Text(text("aboutTitle"))
                }

                Section {
                    NavigationLink(text("infoForNerds")) {
                        technicalInfo
                    }
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

    private var technicalInfo: some View {
        List {
            Section {
                Text(text("infoTechnical"))
            } header: {
                Text(text("infoTechnicalTitle"))
            }
        }
        .navigationTitle(Text(text("infoForNerds")))
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(selectedAppearance.colorScheme)
    }

    private enum AppearanceMode: String {
        case system
        case light
        case dark

        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

}

#Preview {
    PharmacyFinderView()
}
