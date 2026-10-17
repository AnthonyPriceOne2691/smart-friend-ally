// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AllyDiscipline",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "Discipline", targets: ["Discipline"])],
    targets: [
        .target(name: "Discipline", resources: [.process("Resources")]),
        .testTarget(
            name: "DisciplineTests",
            dependencies: ["Discipline"],
            exclude: ["Fixtures/make_fixtures.py"],
            resources: [.copy("Fixtures/repair_parity.jsonl")]
        )
    ]
)
