# Pharmacy Finder iOS

This repository contains the iOS companion app for Juho Hiltunen's nearest-pharmacy concept.

## What it does

- Uses Core Location to find the user’s current position
- Fetches nearby pharmacies from Google Places Nearby Search and shows up to 10, sorted by distance
- Displays Google Places current opening hours (today’s hours where available), phone number, and Google Maps links
- Does not include a hardcoded pharmacy directory or fabricated business details
- Keeps the product uncluttered and easy to extend for future features

## Brand direction

- Dark mode-first presentation
- Pharmacy-green accent styling, aligned with the web app
- Personal branding instead of employer or organization branding

## Run locally

Open the Swift package in Xcode 15+ on macOS. The host iOS app must include both `NSLocationWhenInUseUsageDescription` and `GOOGLE_MAPS_API_KEY` entries in its `Info.plist` (or generate the API key entry from a local, untracked build setting). Enable Places API (New) and billing for the Google Cloud project, then restrict the iOS key to Places API (New) and the host app's bundle identifier.

```bash
swift build
```

The key is deliberately not included in this repository. Google Maps Platform usage can incur charges; review current pricing and quotas before enabling public use. Pharmacy results are fetched when the user requests their location and are not persisted.

## Notes

Google Places is the source of live pharmacy information. Search requests only ask for fields used by the app.

## Author and license

- [Portfolio](https://hiltunenjuho.github.io/)
- [GitHub](https://github.com/hiltunenjuho)
- [LinkedIn](https://www.linkedin.com/in/hiltunenjuho/)
- [MIT License](./LICENSE)

The license applies to this project's code; Google Maps content is subject to Google Maps Platform terms.
