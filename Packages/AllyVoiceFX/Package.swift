// swift-tools-version:5.10
import PackageDescription

// Voice processing after synthesis (voice series V4a): own TD-PSOLA with an own autocorrelation pitch tracker, in
// plain C; the chain's EQ arrives with V4b. Only Foundation and C — the package builds and tests on Linux.
let package = Package(
    name: "AllyVoiceFX",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AllyVoiceFX", targets: ["AllyVoiceFX"])],
    targets: [
        .target(name: "CVoiceFX", linkerSettings: [.linkedLibrary("m", .when(platforms: [.linux]))]),
        .target(name: "AllyVoiceFX", dependencies: ["CVoiceFX"]),
        .testTarget(name: "AllyVoiceFXTests", dependencies: ["AllyVoiceFX"])
    ]
)
