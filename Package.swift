// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TreatPharmacy",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "TreatPharmacy",
            targets: ["TreatPharmacy"]
        )
    ],
    targets: [
        .target(
            name: "TreatPharmacy",
            path: "Sources/TreatPharmacy"
        )
    ]
)
