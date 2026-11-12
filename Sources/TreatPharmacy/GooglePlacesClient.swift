import CoreLocation
import Foundation

struct GooglePlacesClient {
    private let apiKey: String?
    private let endpoint = URL(string: "https://places.googleapis.com/v1/places:searchNearby")!

    init(apiKey: String? = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String) {
        self.apiKey = apiKey
    }

    func searchNearby(_ coordinate: CLLocationCoordinate2D) async throws -> [Pharmacy] {
        guard let apiKey, !apiKey.isEmpty else {
            throw PlacesError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(
            "places.id,places.displayName,places.location,places.formattedAddress,places.googleMapsUri,places.nationalPhoneNumber,places.currentOpeningHours",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )
        request.httpBody = try JSONEncoder().encode(SearchRequest(coordinate: coordinate))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlacesError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw PlacesError.requestFailed(httpResponse.statusCode)
        }

        let responseBody = try JSONDecoder().decode(SearchResponse.self, from: data)
        let pharmacies = (responseBody.places ?? []).compactMap { place -> Pharmacy? in
            guard
                let id = place.id,
                let name = place.displayName?.text,
                let location = place.location
            else {
                return nil
            }

            return Pharmacy(
                id: id,
                name: name,
                address: place.formattedAddress ?? "",
                latitude: location.latitude,
                longitude: location.longitude,
                currentWeekHours: place.currentOpeningHours?.weekdayDescriptions ?? [],
                phoneNumber: place.nationalPhoneNumber,
                mapsURL: place.googleMapsUri.flatMap(URL.init(string:))
            )
        }

        return nearestPharmacies(pharmacies, from: coordinate)
    }
}

private extension GooglePlacesClient {
    struct SearchRequest: Encodable {
        let includedPrimaryTypes = ["pharmacy"]
        let maxResultCount = 10
        let rankPreference = "DISTANCE"
        let languageCode = "en"
        let locationRestriction: LocationRestriction

        init(coordinate: CLLocationCoordinate2D) {
            locationRestriction = LocationRestriction(
                circle: Circle(
                    center: Center(latitude: coordinate.latitude, longitude: coordinate.longitude),
                    radius: 50_000
                )
            )
        }

        struct LocationRestriction: Encodable {
            let circle: Circle
        }

        struct Circle: Encodable {
            let center: Center
            let radius: Double
        }

        struct Center: Encodable {
            let latitude: Double
            let longitude: Double
        }
    }

    struct SearchResponse: Decodable {
        let places: [PlaceResult]?
    }

    struct PlaceResult: Decodable {
        let id: String?
        let displayName: LocalizedText?
        let location: PlaceLocation?
        let formattedAddress: String?
        let googleMapsUri: String?
        let nationalPhoneNumber: String?
        let currentOpeningHours: OpeningHours?
    }

    struct LocalizedText: Decodable {
        let text: String?
    }

    struct PlaceLocation: Decodable {
        let latitude: Double
        let longitude: Double
    }

    struct OpeningHours: Decodable {
        let weekdayDescriptions: [String]?
    }

    enum PlacesError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case requestFailed(Int)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Google Maps is not configured. Add GOOGLE_MAPS_API_KEY to the app’s Info.plist."
            case .invalidResponse:
                return "Google Places returned an invalid response."
            case .requestFailed(let statusCode):
                return "Google Places request failed (HTTP \(statusCode)). Check the API key, enabled API, and billing settings."
            }
        }
    }
}
