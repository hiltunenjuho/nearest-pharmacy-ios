# Pharmacy Finder iOS

SwiftUI source for the iOS version of the Pharmacy Finder portfolio project. This repository is a Swift package, not a standalone Xcode app project. An iOS host-app target is required to install and run the public `PharmacyFinderView`.

## Features

- Uses Core Location to search around the user's current position
- Searches Google Places API (New) within a maximum 50 km radius and returns up to the 10 closest pharmacies
- Displays pharmacy details, opening hours, and Google Maps links
- Includes Finnish and English language toggles and light/dark appearance controls
- Defaults to the device language and system appearance
- Includes an About screen and a separate "Info for nerds" technical overview

## Code layout

- `PharmacyFinderView.swift` defines the public SwiftUI screen and controls.
- `LocationManager.swift` handles location permission and search state.
- `PharmacySearchClient.swift` sends requests to the Worker.
- `Pharmacy.swift` defines the response model and distance calculation.
- `Resources/en.lproj` and `Resources/fi.lproj` contain localized strings.

The app sends coordinates through a Cloudflare Worker to Google Places and does not persist the user's location or search results. The Google Maps Demo Key remains in a Cloudflare Worker secret and is never included in the iOS app. The key is available without a billing account but has daily limits and is intended for prototypes and portfolio demos; availability is not guaranteed. Google Maps details can be incomplete or out of date, so confirm directly with a pharmacy before travelling.

## Configure the host iOS app

Import the `PharmacyFinder` package and present `PharmacyFinderView()` from the host app's root view. The host app must provide `NSLocationWhenInUseUsageDescription` in its `Info.plist` with a clear explanation of why location access is needed. The search client uses this production endpoint by default:

`https://pharmacy-finder-api.juho-m-hiltunen.workers.dev/api/pharmacies/search`

Set `PHARMACY_FINDER_API_URL` in the host app's `Info.plist` only when overriding the default endpoint. The endpoint is public; do not put the Google Maps Demo Key in the app, its `Info.plist`, or any client-side configuration.

## Build

Open the package in Xcode 15+ on macOS to inspect or build the Swift package. A standalone iOS app, simulator run, or App Store archive requires an Xcode app target and signing configuration; neither is included in this repository.

```bash
swift build
```

## Author and license

Application code is available under the [MIT License](./LICENSE). Google Maps content requires Google attribution and is subject to Google's terms.

- [Portfolio](https://hiltunenjuho.github.io/)
- [GitHub](https://github.com/hiltunenjuho)
- [LinkedIn](https://www.linkedin.com/in/hiltunenjuho/)
- [Web repository](https://github.com/hiltunenjuho/nearest-pharmacy-web)
- [iOS repository](https://github.com/hiltunenjuho/nearest-pharmacy-ios)
