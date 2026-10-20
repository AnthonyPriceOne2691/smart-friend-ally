// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AllyDiscipline",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Discipline", targets: ["Discipline"]),
        .executable(name: "discipline-replay", targets: ["DisciplineReplay"])
    ],
    targets: [
        .target(name: "Discipline", resources: [.process("Resources")]),
        .executableTarget(name: "DisciplineReplay", dependencies: ["Discipline"]),
        .testTarget(
            name: "DisciplineTests",
            dependencies: ["Discipline"],
            exclude: ["Fixtures/make_fixtures.py", "Fixtures/make_router.py"],
            resources: [.copy("Fixtures/repair_parity.jsonl"), .copy("Fixtures/router_parity.jsonl"),
                        .copy("Fixtures/contract_probes.jsonl")]
        )
    ]
)
