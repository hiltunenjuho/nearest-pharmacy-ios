import CoreLocation
import Foundation

struct OpenStreetMapClient {
    private let endpoints = [
        URL(string: "https://overpass-api.de/api/interpreter")!,
        URL(string: "https://overpass.private.coffee/api/interpreter")!,
        URL(string: "https://overpass.kumi.systems/api/interpreter")!
    ]
    private let searchRadius = 50_000.0

    func searchNearby(_ coordinate: CLLocationCoordinate2D) async throws -> [Pharmacy] {
        var failures: [String] = []
        var found: [String: Pharmacy] = [:]
        let query = makeQuery(near: coordinate, radius: searchRadius)
        var elements: [Element]?

        for endpoint in endpoints {
            do {
                elements = try await request(endpoint: endpoint, query: query)
                break
            } catch {
                failures.append(error.localizedDescription)
            }
        }

        guard let elements else {
            throw SearchError.unavailable(failures.joined(separator: " "))
        }
        for element in elements {
            if let pharmacy = element.pharmacy {
                found[pharmacy.id] = pharmacy
            }
        }

        return nearestPharmacies(Array(found.values), from: coordinate)
    }

    private func request(endpoint: URL, query: String) async throws -> [Element] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: allowedCharacters) else {
            throw SearchError.invalidQuery
        }
        request.httpBody = Data("data=\(encodedQuery)".utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SearchError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SearchError.requestFailed(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(SearchResponse.self, from: data).elements ?? []
    }

    private func makeQuery(near coordinate: CLLocationCoordinate2D, radius: Double) -> String {
        let latitude = String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), coordinate.latitude)
        let longitude = String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), coordinate.longitude)
        return """
        [out:json][timeout:20];(nwr["amenity"="pharmacy"](around:\(Int(radius)),\(latitude),\(longitude));nwr["healthcare"="pharmacy"](around:\(Int(radius)),\(latitude),\(longitude)););out center tags;
        """
    }
}

private extension OpenStreetMapClient {
    struct SearchResponse: Decodable {
        let elements: [Element]?
    }

    struct Element: Decodable {
        let type: String
        let id: Int64
        let lat: Double?
        let lon: Double?
        let center: Center?
        let tags: [String: String]?

        var pharmacy: Pharmacy? {
            let latitude = lat ?? center?.lat
            let longitude = lon ?? center?.lon
            guard let latitude, let longitude else { return nil }

            let tags = tags ?? [:]
            let street = [tags["addr:street"], tags["addr:housenumber"]]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            let locality = tags["addr:city"] ?? tags["addr:town"] ?? tags["addr:village"] ?? tags["addr:suburb"]
            let address = [street, tags["addr:postcode"], locality]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")

            return Pharmacy(
                id: "\(type)/\(id)",
                name: tags["name"] ?? tags["name:en"] ?? tags["name:local"] ?? "Pharmacy",
                address: address,
                latitude: latitude,
                longitude: longitude,
                openingHours: tags["opening_hours"],
                phoneNumber: tags["phone"] ?? tags["contact:phone"],
                osmURL: URL(string: "https://www.openstreetmap.org/\(type)/\(id)")!
            )
        }
    }

    struct Center: Decodable {
        let lat: Double
        let lon: Double
    }

    enum SearchError: LocalizedError {
        case invalidQuery
        case invalidResponse
        case requestFailed(Int)
        case unavailable(String)

        var errorDescription: String? {
            switch self {
            case .invalidQuery:
                return "Could not prepare the OpenStreetMap search."
            case .invalidResponse:
                return "OpenStreetMap returned an invalid response."
            case .requestFailed(let statusCode):
                return "OpenStreetMap search failed (HTTP \(statusCode))."
            case .unavailable(let details):
                return "Free OpenStreetMap search is temporarily unavailable. Please try again later. \(details)"
            }
        }
    }
}
