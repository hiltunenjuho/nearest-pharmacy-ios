import Foundation

struct Pharmacy: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let hours: String
    let services: [String]
}

let allPharmacies: [Pharmacy] = [
    Pharmacy(
        id: "apteekki-1",
        name: "Kallion Apteekki",
        address: "Kallionkatu 7, Helsinki",
        latitude: 60.1828,
        longitude: 24.9582,
        hours: "08:00–22:00",
        services: ["Päivystys", "Sairauslomat", "Vaccinations"]
    ),
    Pharmacy(
        id: "apteekki-2",
        name: "Munkkiniemen APT",
        address: "Munkkiniemenkatu 18, Helsinki",
        latitude: 60.2053,
        longitude: 24.8766,
        hours: "09:00–20:00",
        services: ["Lääkärin ohjeet", "Aikataulutettu neuvonta"]
    ),
    Pharmacy(
        id: "apteekki-3",
        name: "Punavuoren Lääke",
        address: "Purokatu 8, Helsinki",
        latitude: 60.1631,
        longitude: 24.9399,
        hours: "08:30–21:30",
        services: ["Vauva- ja perhepalvelut", "Vastaanotto"]
    ),
    Pharmacy(
        id: "apteekki-4",
        name: "Haaga Apteekki",
        address: "Haaga WEG 21, Helsinki",
        latitude: 60.2194,
        longitude: 24.8758,
        hours: "07:30–21:00",
        services: ["Nopea kuormitus", "Raskausajan neuvonta"]
    ),
    Pharmacy(
        id: "apteekki-5",
        name: "LähiLääke Malmi",
        address: "Malmin kauppatie 18, Helsinki",
        latitude: 60.2566,
        longitude: 25.0064,
        hours: "09:00–22:00",
        services: ["Säännöllinen toimitus", "Avoinna myöhään"]
    )
]

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

    var radiansToDegrees: Double {
        self * 180 / .pi
    }
}
