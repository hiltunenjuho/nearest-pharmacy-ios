import CoreLocation
import Foundation

struct Pharmacy: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let openingHours: String?
    let phoneNumber: String?
    let osmURL: URL

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
            URLQueryItem(name: "destination", value: "\(latitude),\(longitude)")
        ]
        return components.url
    }
}

func openingHoursForToday(_ expression: String, date: Date = Date()) -> String? {
    let value = expression.trimmingCharacters(in: .whitespacesAndNewlines)
    if value == "24/7" {
        return "Open 24 hours"
    }

    let unsupported = try? NSRegularExpression(pattern: #"\b(PH|SH|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|sunrise|sunset|easter)\b"#, options: [.caseInsensitive])
    let fullRange = NSRange(value.startIndex..<value.endIndex, in: value)
    if unsupported?.firstMatch(in: value, range: fullRange) != nil {
        return nil
    }

    let weekdayCodes = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    let weekdayIndex = (Calendar.current.component(.weekday, from: date) + 5) % 7
    let today = weekdayCodes[weekdayIndex]
    let dayPattern = try? NSRegularExpression(pattern: #"\b(Mo|Tu|We|Th|Fr|Sa|Su)(?:\s*-\s*(Mo|Tu|We|Th|Fr|Sa|Su))?\b"#)
    let hoursPattern = try? NSRegularExpression(pattern: #"\d{1,2}:\d{2}-\d{1,2}:\d{2}(?:,\s*\d{1,2}:\d{2}-\d{1,2}:\d{2})*"#)
    var todayResult: String?

    for rule in value.split(separator: ";").map(String.init) {
        let ruleRange = NSRange(rule.startIndex..<rule.endIndex, in: rule)
        let hoursMatch = hoursPattern?.firstMatch(in: rule, range: ruleRange)
        let selectorEnd = hoursMatch.flatMap { Range($0.range, in: rule)?.lowerBound } ?? rule.endIndex
        let selector = String(rule[..<selectorEnd]).trimmingCharacters(in: .whitespaces)

        if selector.range(of: #"^[A-Za-z0-9,\-\s]*$"#, options: .regularExpression) == nil {
            continue
        }

        let matchingDays = dayPattern?.matches(in: selector, range: NSRange(selector.startIndex..<selector.endIndex, in: selector)).contains { match in
            guard let firstRange = Range(match.range(at: 1), in: selector),
                  let firstIndex = weekdayCodes.firstIndex(of: String(selector[firstRange])) else {
                return false
            }
            guard match.range(at: 2).location != NSNotFound,
                  let lastRange = Range(match.range(at: 2), in: selector),
                  let lastIndex = weekdayCodes.firstIndex(of: String(selector[lastRange])) else {
                return weekdayCodes[firstIndex] == today
            }

            var index = firstIndex
            while true {
                if weekdayCodes[index] == today { return true }
                if index == lastIndex { break }
                index = (index + 1) % weekdayCodes.count
            }
            return false
        } ?? selector.isEmpty

        guard matchingDays else { continue }
        let lowerRule = rule.lowercased()
        if lowerRule.contains("off") || lowerRule.contains("closed") {
            todayResult = "Closed today"
        } else if let hoursMatch,
                  let range = Range(hoursMatch.range, in: rule) {
            todayResult = String(rule[range]).replacingOccurrences(of: ",", with: ", ")
        } else if lowerRule.contains("24/7") || lowerRule.contains("open") {
            todayResult = "Open 24 hours"
        }
    }

    return todayResult
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
