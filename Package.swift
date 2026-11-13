// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PharmacyFinder",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "PharmacyFinder",
            targets: ["PharmacyFinder"]
        )
    ],
    targets: [
        .target(
            name: "PharmacyFinder",
            path: "Sources/PharmacyFinder",
            resources: [.process("Resources")]
        )
    ]
)
