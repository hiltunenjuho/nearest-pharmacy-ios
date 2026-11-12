# Pharmacy Finder iOS

The SwiftUI companion app for Juho Hiltunen's global nearest-pharmacy finder.

## Features

- Uses Core Location to search around the user's current position anywhere in the world
- Fetches and distance-sorts up to 10 pharmacies from OpenStreetMap via public Overpass API instances
- Searches within a maximum radius of 50 km and returns up to the 10 closest results
- Displays mapped addresses, contact details, today's hours when available, and map links
- Offers System, Light, and Dark appearance options; System follows the iOS appearance
- Includes an English/Finnish language toggle, initially using the device language
- Includes an About screen with project, author, license, and data-source links
- The About screen explains how search, map data, and location privacy work

No Google Maps API key, account, or billing configuration is needed. Public Overpass instances are community resources and do not guarantee uptime. OpenStreetMap coverage and mapped details vary by region, so fewer than 10 results may be returned. Opening-hours details can be missing, out of date, or omit local holiday exceptions; confirm before travelling.

The app sends the coordinates needed to perform the search to an Overpass service and does not persist location or search results. Pharmacy data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under the [ODbL](https://opendatacommons.org/licenses/odbl/).

## Build

Open the Swift package in Xcode 15+ on macOS, or run:

```bash
swift build
```

The host iOS app needs `NSLocationWhenInUseUsageDescription` in its `Info.plist`. No API key is required.

## Author and license

Application code is available under the [MIT License](./LICENSE); OpenStreetMap data remains under the ODbL.

- [Portfolio](https://hiltunenjuho.github.io/)
- [GitHub](https://github.com/hiltunenjuho)
- [LinkedIn](https://www.linkedin.com/in/hiltunenjuho/)
- [Web repository](https://github.com/hiltunenjuho/nearest-pharmacy-web)
- [iOS repository](https://github.com/hiltunenjuho/nearest-pharmacy-ios)
