import CoreLocation
import Foundation

struct PharmacySearchClient {
    private struct SearchRequest: Encodable {
        let lat: Double
        let lng: Double
        let language: String
    }

    private struct SearchResponse: Decodable {
        let pharmacies: [Pharmacy]
    }

    private struct ErrorResponse: Decodable {
        let error: String
    }

    enum SearchError: Error {
        case notConfigured
        case dailyLimit
        case rateLimited
        case requestFailed
        case invalidResponse
    }

    private static let defaultEndpoint =
        "https://pharmacy-finder-api.juho-m-hiltunen.workers.dev/api/pharmacies/search"

    private var endpoint: URL? {
        let configuredValue = (Bundle.main.object(forInfoDictionaryKey: "PHARMACY_FINDER_API_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let value = configuredValue.flatMap { $0.isEmpty ? nil : $0 } ?? Self.defaultEndpoint
        guard let url = URL(string: value),
              url.scheme == "https",
              url.host != nil else {
            return nil
        }
        return url
    }

    func searchNearby(_ coordinate: CLLocationCoordinate2D, language: String) async throws -> [Pharmacy] {
        guard let endpoint else {
            throw SearchError.notConfigured
        }

        // The client sends only coordinates and language; the provider key stays in the Worker.
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            SearchRequest(lat: coordinate.latitude, lng: coordinate.longitude, language: language)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SearchError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let error = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.error
            if error == "demo_daily_limit" {
                throw SearchError.dailyLimit
            }
            if error == "rate_limited" {
                throw SearchError.rateLimited
            }
            if error == "service_not_configured" {
                throw SearchError.notConfigured
            }
            throw SearchError.requestFailed
        }

        guard let result = try? JSONDecoder().decode(SearchResponse.self, from: data) else {
            throw SearchError.invalidResponse
        }
        return result.pharmacies
    }
}
