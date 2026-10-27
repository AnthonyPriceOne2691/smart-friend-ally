// swift-tools-version:5.10
import PackageDescription

// The girl's memory (series memory-core → memory-extract → memory-app → memory-forget): facts anchored to her turn,
// confidence by code, replacement by date, the prompt block, erase-all — over the app's one SQLite (../AllySQLite).
let package = Package(
    name: "AllyMemory",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "Memory", targets: ["Memory"])],
    dependencies: [.package(path: "../AllySQLite")],
    targets: [
        .target(name: "Memory", dependencies: [.product(name: "AllySQLite", package: "AllySQLite")],
                resources: [.process("Resources")]),
        .testTarget(name: "MemoryTests", dependencies: ["Memory"])
    ]
)
