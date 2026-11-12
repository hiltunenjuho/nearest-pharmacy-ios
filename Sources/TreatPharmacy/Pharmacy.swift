import Foundation

struct Pharmacy: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let city: String
    let latitude: Double
    let longitude: Double
    let hours: String
    let facts: [String]
}

let allPharmacies: [Pharmacy] = [
    Pharmacy(id: "kallio", name: "Kallion Apteekki", address: "Kallionkatu 7", city: "Helsinki", latitude: 60.1828, longitude: 24.9582, hours: "08:00–22:00", facts: ["City-centre location", "Near tram connections", "Prescription pickup available"]),
    Pharmacy(id: "munkkiniemi", name: "Munkkiniemen APT", address: "Munkkiniemenkatu 18", city: "Helsinki", latitude: 60.2053, longitude: 24.8766, hours: "09:00–20:00", facts: ["Residential area pharmacy", "Parking nearby", "General health advice available"]),
    Pharmacy(id: "kamppi", name: "Kamppi Apteekki", address: "Mannerheimintie 7", city: "Helsinki", latitude: 60.1698, longitude: 24.9384, hours: "08:00–20:00", facts: ["Central Helsinki location", "Easy access by public transport", "Popular for quick medicine pickup"]),
    Pharmacy(id: "punavuori", name: "Punavuoren Lääke", address: "Purokatu 8", city: "Helsinki", latitude: 60.1631, longitude: 24.9399, hours: "08:30–21:30", facts: ["Inner-city location", "Accessible by foot", "Good for everyday prescriptions"]),
    Pharmacy(id: "itakeskus", name: "Itäkeskuksen Terveysapteekki", address: "Itäkeskuksen kauppakeskus", city: "Helsinki", latitude: 60.2119, longitude: 25.0808, hours: "09:00–21:00", facts: ["Shopping-centre pharmacy", "Popular for convenience", "Strong public transport access"]),
    Pharmacy(id: "malmi", name: "LähiLääke Malmi", address: "Malmin kauppatie 18", city: "Helsinki", latitude: 60.2566, longitude: 25.0064, hours: "09:00–22:00", facts: ["Late opening hours", "North Helsinki location", "Convenient for evening pickup"]),
    Pharmacy(id: "espoo-keskus", name: "Espoon Keskus Apteekki", address: "Espoon Keskus", city: "Espoo", latitude: 60.2050, longitude: 24.6564, hours: "08:00–21:00", facts: ["Major retail hub", "Easy access by transit", "Reliable prescription service"]),
    Pharmacy(id: "tapiola", name: "Tapiolan Apteekki", address: "Tapiola", city: "Espoo", latitude: 60.1751, longitude: 24.8010, hours: "09:00–20:30", facts: ["Residential neighbourhood", "Strong local access", "Good for family medication needs"]),
    Pharmacy(id: "leppavaara", name: "Leppävaaran APT", address: "Leppävaara", city: "Espoo", latitude: 60.2190, longitude: 24.8187, hours: "08:30–21:30", facts: ["Commute-friendly location", "Late closing on weekdays", "Prescription refill service"]),
    Pharmacy(id: "myyrmaki", name: "Myyrmäen Apteekki", address: "Myyrmäki", city: "Vantaa", latitude: 60.2617, longitude: 24.8443, hours: "08:00–21:00", facts: ["Suburban convenience", "Well connected by bus line", "Practical daily pharmacy stop"]),
    Pharmacy(id: "tikkurila", name: "Tikkurilan Apteekki", address: "Tikkurila", city: "Vantaa", latitude: 60.2932, longitude: 25.0378, hours: "09:00–21:30", facts: ["Transit hub location", "Extended weekday hours", "Useful for commuting households"]),
    Pharmacy(id: "kauniainen", name: "Kauniaisten Apteekki", address: "Kauniainen", city: "Kauniainen", latitude: 60.2129, longitude: 24.7272, hours: "08:30–20:30", facts: ["Small-city pharmacy", "Accessible local service", "Convenient for everyday needs"])
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
