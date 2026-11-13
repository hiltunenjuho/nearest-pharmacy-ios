import CoreLocation
import Foundation
import SwiftUI

private enum PharmacyFilter: String, Hashable {
    case all
    case openNow
    case opensEarliest
}

public struct PharmacyFinderView: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @StateObject private var locationManager = LocationManager()
    @State private var selectedPharmacyID: String?
    @State private var selectedFilter: PharmacyFilter = .all
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
        guard let hours else { return text("hoursUnavailable") }
        let trimmedHours = hours.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedHours.isEmpty ? text("hoursUnavailable") : trimmedHours
    }

    private var appGreen: Color {
        effectiveColorScheme == .dark
            ? Color(red: 0.35, green: 0.83, blue: 0.54)
            : Color(red: 0.13, green: 0.52, blue: 0.32)
    }

    private var appGreenStrong: Color {
        effectiveColorScheme == .dark
            ? Color(red: 0.20, green: 0.78, blue: 0.47)
            : Color(red: 0.09, green: 0.43, blue: 0.25)
    }

    private var pageBackground: Color {
        effectiveColorScheme == .dark
            ? Color(red: 0.12, green: 0.12, blue: 0.12)
            : Color(red: 0.95, green: 0.97, blue: 0.95)
    }

    private var panelBackground: Color {
        effectiveColorScheme == .dark ? Color(red: 0.16, green: 0.16, blue: 0.16) : .white
    }

    private func openingCountdown(for pharmacy: Pharmacy, at now: Date) -> String? {
        guard let isOpen = pharmacy.openNow else {
            return nil
        }

        let boundary = isOpen ? pharmacy.nextClosingDate : pharmacy.nextOpeningDate
        guard let boundary else {
            return nil
        }

        let minutesRemaining = Int(ceil(boundary.timeIntervalSince(now) / 60))
        guard minutesRemaining > 0 else {
            return nil
        }

        let hours = minutesRemaining / 60
        let minutes = minutesRemaining % 60
        let duration = hours > 0 ? "\(hours)h \(minutes)min" : "\(minutes)min"
        return String(format: text(isOpen ? "openFor" : "opensIn"), duration)
    }

    private func pharmacyName(_ name: String) -> String {
        name == "Pharmacy" ? text("unnamedPharmacy") : name
    }

    private var visiblePharmacies: [Pharmacy] {
        switch selectedFilter {
        case .all:
            return locationManager.pharmacies
        case .openNow:
            return locationManager.pharmacies.filter { $0.openNow == true }
        case .opensEarliest:
            return locationManager.pharmacies
                .enumerated()
                .filter { $0.element.openNow == false }
                .sorted { first, second in
                    let firstOpening = first.element.nextOpeningDate ?? .distantFuture
                    let secondOpening = second.element.nextOpeningDate ?? .distantFuture
                    if firstOpening != secondOpening {
                        return firstOpening < secondOpening
                    }

                    if let location = locationManager.location {
                        let firstDistance = distanceInKilometers(
                            from: (location.latitude, location.longitude),
                            to: (lat: first.element.latitude, lon: first.element.longitude)
                        )
                        let secondDistance = distanceInKilometers(
                            from: (location.latitude, location.longitude),
                            to: (lat: second.element.latitude, lon: second.element.longitude)
                        )
                        if firstDistance != secondDistance {
                            return firstDistance < secondDistance
                        }
                    }

                    return first.offset < second.offset
                }
                .map { $0.element }
        }
    }

    private var filterEmptyMessage: String {
        if locationManager.pharmacies.contains(where: { $0.openNow == nil }) {
            return text("openingStatusUnavailable")
        }
        return text(selectedFilter == .openNow ? "noneOpen" : "noneClosed")
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
                    .fill(appGreen)
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
                    .fill(appGreen)
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

    public var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [appGreen.opacity(0.12), pageBackground, pageBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        Text(text("subtitle"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button {
                            locationManager.requestLocation(language: selectedLanguage)
                        } label: {
                            HStack(spacing: 10) {
                                if locationManager.isLoading {
                                    ProgressView()
                                        .tint(effectiveColorScheme == .dark ? Color.black : Color.white)
                                }
                                Text(locationManager.isLoading ? text("searching") : text("findNearby"))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .foregroundStyle(effectiveColorScheme == .dark ? Color.black : Color.white)
                            .background(
                                LinearGradient(colors: [appGreen, appGreenStrong], startPoint: .leading, endPoint: .trailing),
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(locationManager.isLoading)

                        if let errorKey = locationManager.errorMessageKey {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(text(errorKey))
                                if let details = locationManager.errorDetails {
                                    Text(details)
                                        .font(.caption)
                                }
                            }
                            .font(.subheadline)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(appGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        }

                        resultsPanel
                        footer
                    }
                    .frame(maxWidth: 720, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onChange(of: locationManager.pharmacies.map(\.id)) { _, pharmacyIDs in
            selectedFilter = .all
            selectedPharmacyID = pharmacyIDs.first
        }
        .onChange(of: selectedFilter) { _, _ in
            selectedPharmacyID = visiblePharmacies.first?.id
        }
        .preferredColorScheme(selectedAppearance.colorScheme)
        .sheet(isPresented: $isAboutPresented) {
            aboutSheet
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(effectiveColorScheme == .dark ? Color.black : Color.white)
                    .frame(width: 58, height: 58)
                    .background(
                        LinearGradient(colors: [appGreen, appGreenStrong], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 17)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Juho Hiltunen")
                        .font(.caption.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(appGreen)
                        .textCase(.uppercase)
                    Text("Pharmacy Finder")
                        .font(.title2.bold())
                        .tracking(-0.7)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 4)
                quickLinksMenu
            }

            HStack(spacing: 10) {
                Spacer()
                languageToggle
                themeToggle
                Button {
                    isAboutPresented = true
                } label: {
                    Image(systemName: "info")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(panelBackground, in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(appGreen.opacity(0.24), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(text("openInfo"))
            }
        }
    }

    private var quickLinksMenu: some View {
        Menu {
            Button(text("infoMenuItem")) {
                isAboutPresented = true
            }
            Divider()
            Link("Juho Hiltunen", destination: URL(string: "https://hiltunenjuho.github.io/")!)
            Link("LinkedIn", destination: URL(string: "https://www.linkedin.com/in/hiltunenjuho/")!)
            Link("GitHub", destination: URL(string: "https://github.com/hiltunenjuho")!)
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(panelBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(appGreen.opacity(0.24), lineWidth: 1)
                }
        }
        .accessibilityLabel(text("menuControl"))
    }

    private var resultsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(text("nearest"))
                    .font(.headline)
                Spacer()
                Text(String(format: text("resultCount"), visiblePharmacies.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !locationManager.pharmacies.isEmpty {
                Picker(text("filterPharmacies"), selection: $selectedFilter) {
                    Text(text("filterAll")).tag(PharmacyFilter.all)
                    Text(text("filterOpenNow")).tag(PharmacyFilter.openNow)
                    Text(text("filterOpensEarliest")).tag(PharmacyFilter.opensEarliest)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(text("filterPharmacies"))
            }

            if visiblePharmacies.isEmpty {
                Text(locationManager.pharmacies.isEmpty ? text("findLocation") : filterEmptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(visiblePharmacies) { pharmacy in
                        pharmacyRow(pharmacy)
                    }
                }
            }
        }
        .padding(18)
        .background(panelBackground.opacity(0.96), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(appGreen.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Pharmacy Finder")
                    .font(.headline)
                Text(String(format: text("footerBuilt"), Calendar.current.component(.year, from: Date())))
                Text(text("footerPrivacy"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), alignment: .leading)], alignment: .leading, spacing: 10) {
                Link("Portfolio", destination: URL(string: "https://hiltunenjuho.github.io/")!)
                Link("GitHub", destination: URL(string: "https://github.com/hiltunenjuho")!)
                Link("LinkedIn", destination: URL(string: "https://www.linkedin.com/in/hiltunenjuho/")!)
                Link(text("webRepository"), destination: URL(string: "https://github.com/hiltunenjuho/nearest-pharmacy-web")!)
                Link(text("iosRepository"), destination: URL(string: "https://github.com/hiltunenjuho/nearest-pharmacy-ios")!)
                Link(text("mitLicense"), destination: URL(string: "https://github.com/hiltunenjuho/nearest-pharmacy-web/blob/main/LICENSE")!)
            }
            .font(.caption.weight(.semibold))
            .tint(effectiveColorScheme == .dark ? Color.black.opacity(0.8) : Color.white)
        }
        .font(.caption)
        .foregroundStyle(effectiveColorScheme == .dark ? Color.black.opacity(0.85) : Color.white)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [appGreenStrong, appGreen], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    private func pharmacyRow(_ pharmacy: Pharmacy) -> some View {
        let isExpanded = selectedPharmacyID == pharmacy.id

        return VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPharmacyID = isExpanded ? nil : pharmacy.id
                }
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
                                .foregroundStyle(appGreen)
                                .fontWeight(.semibold)
                        }
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    Text(pharmacy.address.isEmpty ? text("addressMissing") : pharmacy.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        if let countdown = openingCountdown(for: pharmacy, at: context.date) {
                            Text(countdown)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(appGreen)
                        }
                    }
                    Text(todayHours(pharmacy.todayHours))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(pharmacyName(pharmacy.name))
            .accessibilityValue(text(isExpanded ? "expanded" : "collapsed"))
            .accessibilityHint(text("togglePharmacyDetails"))

            if isExpanded {
                pharmacyDetails(for: pharmacy)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isExpanded ? appGreen.opacity(0.08) : panelBackground,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(appGreen.opacity(isExpanded ? 0.55 : 0.12), lineWidth: 1)
        }
    }

    private func pharmacyDetails(for pharmacy: Pharmacy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(text("openToday"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(todayHours(pharmacy.todayHours))
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(text("phone"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let phoneNumber = pharmacy.phoneNumber, let callURL = pharmacy.callURL {
                        Link(phoneNumber, destination: callURL)
                            .font(.subheadline.weight(.semibold))
                            .tint(appGreen)
                    } else {
                        Text(text("notProvided"))
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !pharmacy.openingHours.isEmpty {
                DisclosureGroup(text("fullSchedule")) {
                    ForEach(pharmacy.openingHours, id: \.self) { day in
                        Text(day)
                    }
                }
                .font(.subheadline)
            }

            Text(text("hoursDisclaimer"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Link(text("dataAttribution"), destination: URL(string: "https://maps.google.com/")!)
                .font(.footnote)
                .tint(.primary)

            VStack(spacing: 8) {
                if let directionsURL = pharmacy.directionsURL {
                    Link(destination: directionsURL) {
                        Label(text("directions"), systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.horizontal, 12)
                            .foregroundStyle(effectiveColorScheme == .dark ? Color.black : Color.white)
                            .background(appGreen, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                if let callURL = pharmacy.callURL {
                    Link(destination: callURL) {
                        Label(
                            text("callPharmacy"),
                            systemImage: "phone.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.horizontal, 12)
                        .foregroundStyle(appGreen)
                        .background(appGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(pageBackground, in: RoundedRectangle(cornerRadius: 16))
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
                    Link("Juho Hiltunen", destination: URL(string: "https://hiltunenjuho.github.io/")!)
                    Link("LinkedIn", destination: URL(string: "https://www.linkedin.com/in/hiltunenjuho/")!)
                    Link("GitHub", destination: URL(string: "https://github.com/hiltunenjuho")!)
                    Link(text("contact"), destination: URL(string: "mailto:juho.m.hiltunen@gmail.com")!)
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
