// swift-tools-version:5.10
import PackageDescription

// RUAccent на Swift (серия голоса V3): токенизаторы, словари и решения — только Foundation, тесты на Linux;
// модели через AllyOnnx — отдельным пакетом на Mac (V3c).
let package = Package(
    name: "AllyAccent",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AllyAccent", targets: ["AllyAccent"])],
    targets: [
        .target(name: "AllyAccent"),
        .testTarget(name: "AllyAccentTests", dependencies: ["AllyAccent"], resources: [.copy("Fixtures")])
    ]
)
