import CoreLocation
import Foundation

struct Pharmacy: Identifiable, Equatable, Decodable {
    let id: String
    let name: String
    let address: String
    let lat: Double
    let lng: Double
    let todayHours: String?
    let openingHours: [String]
    let phoneNumber: String?

    var latitude: Double { lat }
    var longitude: Double { lng }

    var callURL: URL? {
        guard let phoneNumber else {
            return nil
        }

        let digits = phoneNumber.filter(\.isNumber)
        guard !digits.isEmpty else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "tel"
        components.path = (phoneNumber.trimmingCharacters(in: .whitespaces).hasPrefix("+") ? "+" : "") + digits
        return components.url
    }

    var directionsURL: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.google.com"
        components.path = "/maps/dir/"
        components.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "destination", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "destination_place_id", value: id)
        ]
        return components.url
    }
}

// Haversine distance remains accurate for the app's worldwide coordinate range.
func distanceInKilometers(from: (lat: Double, lon: Double), to: (lat: Double, lon: Double)) -> Double {
    let earthRadiusKm = 6371.0
    let dLat = (to.lat - from.lat).degreesToRadians
    let dLon = (to.lon - from.lon).degreesToRadians

    let a = sin(dLat / 2) * sin(dLat / 2) +
        cos(from.lat.degreesToRadians) * cos(to.lat.degreesToRadians) *
        sin(dLon / 2) * sin(dLon / 2)

    let c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return earthRadiusKm * c
}

private extension Double {
    var degreesToRadians: Double {
        self * .pi / 180
    }
}
