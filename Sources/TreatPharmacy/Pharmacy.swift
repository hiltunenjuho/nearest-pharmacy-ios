import CoreLocation
import Foundation

struct Pharmacy: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let currentWeekHours: [String]
    let phoneNumber: String?
    let mapsURL: URL?

    var hoursToday: String? {
        openingHoursForToday(currentWeekHours)
    }

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
            URLQueryItem(name: "destination_place_id", value: id),
        ]
        return components.url
    }
}

func openingHoursForToday(_ descriptions: [String], date: Date = Date()) -> String? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en-US")
    formatter.dateFormat = "EEEE"
    let weekday = formatter.string(from: date).lowercased()
    return descriptions.first { $0.lowercased().hasPrefix(weekday) }
}

func nearestPharmacies(_ pharmacies: [Pharmacy], from coordinate: CLLocationCoordinate2D, limit: Int = 10) -> [Pharmacy] {
    pharmacies
        .sorted {
            distanceInKilometers(
                from: (coordinate.latitude, coordinate.longitude),
                to: (lat: $0.latitude, lon: $0.longitude)
            ) < distanceInKilometers(
                from: (coordinate.latitude, coordinate.longitude),
                to: (lat: $1.latitude, lon: $1.longitude)
            )
        }
        .prefix(limit)
        .map { $0 }
}

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
