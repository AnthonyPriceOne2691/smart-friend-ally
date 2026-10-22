// swift-tools-version:5.10
import PackageDescription

// The model of the app: llama.cpp b10809, the release xcframework (iOS and macOS slices, no binary in git) — the
// runtime of the probe and of the accepted v2.4 bench; the tests run on the Mac (A23), not on Linux.
let package = Package(
    name: "AllyLlama",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AllyLlama", targets: ["AllyLlama"])],
    dependencies: [.package(path: "../AllyCore")],
    targets: [
        .binaryTarget(
            name: "llama",
            url: "https://github.com/ggml-org/llama.cpp/releases/download/b10809/llama-b10809-xcframework.zip",
            checksum: "d6813b3b6c73728a19f0bc0d1d7cea04ccdb07f9583c1d930c0b38af2377606d" // pragma: allowlist secret
        ),
        .target(name: "AllyLlama", dependencies: ["llama", .product(name: "AllyCore", package: "AllyCore")]),
        .testTarget(name: "AllyLlamaTests", dependencies: ["AllyLlama"])
    ]
)
