// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AllyCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AllyCore", targets: ["AllyCore"]),
        .executable(name: "encyclopedia-replay", targets: ["EncyclopediaReplay"])
    ],
    dependencies: [.package(path: "../AllyDiscipline"), .package(path: "../AllySQLite")],
    targets: [
        .target(name: "AllyCore", dependencies: [.product(name: "Discipline", package: "AllyDiscipline"),
                                                 .product(name: "AllySQLite", package: "AllySQLite")],
                resources: [.process("Resources")]),
        .executableTarget(name: "EncyclopediaReplay", dependencies: ["AllyCore"]),
        .testTarget(
            name: "AllyCoreTests",
            dependencies: ["AllyCore", .product(name: "Discipline", package: "AllyDiscipline")],
            resources: [.copy("Fixtures/intent_cases.json")]
        )
    ]
)
