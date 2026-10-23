// swift-tools-version:5.10
import PackageDescription

// The app's one SQLite (lead's decision 2026-10-23): the system library behind a thin wrapper — open, query, bind,
// step, transaction, errors. No memory or encyclopedia logic lives here; both depend on it and own no SQLite module.
let package = Package(
    name: "AllySQLite",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AllySQLite", targets: ["AllySQLite"])],
    targets: [
        .systemLibrary(name: "CSQLite", path: "Sources/CSQLite", providers: [.apt(["libsqlite3-dev"])]),
        .target(name: "AllySQLite", dependencies: ["CSQLite"]),
        .testTarget(name: "AllySQLiteTests", dependencies: ["AllySQLite"])
    ]
)
