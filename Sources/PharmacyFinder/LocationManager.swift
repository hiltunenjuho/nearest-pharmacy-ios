import Combine
import CoreLocation
import Foundation

/// Coordinates location permission and the asynchronous pharmacy search.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let placesClient = PharmacySearchClient()
    private var searchLanguage = "en"

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

    func requestLocation(language: String) {
        searchLanguage = language
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
            // Permission may arrive after the user starts a search; do not locate on launch.
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
            pharmacies = try await placesClient.searchNearby(coordinate, language: searchLanguage)
            if pharmacies.isEmpty {
                errorMessageKey = "noResults"
                errorDetails = nil
            }
        } catch {
            pharmacies = []
            errorDetails = nil
            // Views localize stable error keys; raw details are reserved for unexpected failures.
            if let searchError = error as? PharmacySearchClient.SearchError {
                switch searchError {
                case .dailyLimit:
                    errorMessageKey = "demoDailyLimit"
                case .rateLimited:
                    errorMessageKey = "rateLimited"
                case .notConfigured:
                    errorMessageKey = "serviceUnavailable"
                case .requestFailed, .invalidResponse:
                    errorMessageKey = "searchFailed"
                }
            } else {
                errorMessageKey = "searchFailed"
                errorDetails = error.localizedDescription
            }
        }
        isLoading = false
    }
}
