// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AllyCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AllyCore", targets: ["AllyCore"])],
    dependencies: [.package(path: "../AllyDiscipline")],
    targets: [
        .target(name: "AllyCore", dependencies: [.product(name: "Discipline", package: "AllyDiscipline")]),
        .testTarget(
            name: "AllyCoreTests",
            dependencies: ["AllyCore", .product(name: "Discipline", package: "AllyDiscipline")]
        )
    ]
)
