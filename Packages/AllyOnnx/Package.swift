// swift-tools-version:5.10
import PackageDescription

// The one ONNX Runtime of the app (decision 2026-10-23): Microsoft's official onnxruntime-c pod 1.28.0 — a static
// xcframework with iOS, simulator and macOS slices (no binary in git), API 28 like the headers of sherpa-onnx 1.13.8 —
// and a thin Swift layer over its C API. The voice and the hearing use only this one; a second ORT in the app's graph
// is what scripts/lint/check_single_ort.sh refuses. The static runtime needs libc++ and CoreML at link time. Tests run
// on the Mac (the macOS slice), not on Linux. sherpa-onnx 1.13.8 (the hearing, D7.2): k2-fsa's static xcframeworks of
// the release, iOS and macOS apart as in its own manifest — its C API without a runtime inside, built against API 28,
// so it links the one above; the guard pins the pair (sherpa 1.13.8 with ORT 1.28.0).
let sherpaReleases = "https://github.com/k2-fsa/sherpa-onnx/releases/download/xcframework/"

let package = Package(
    name: "AllyOnnx",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AllyOnnx", targets: ["AllyOnnx"]),
               .library(name: "AllySherpa", targets: ["AllySherpa"])],
    targets: [
        .binaryTarget(
            name: "onnxruntime",
            url: "https://download.onnxruntime.ai/pod-archive-onnxruntime-c-1.28.0.zip",
            checksum: "b503cf5949ab718a1dff17d1643237ecc0fecf50ad86264572dcafddb140a327" // pragma: allowlist secret
        ),
        .binaryTarget(
            name: "SherpaOnnxIOS",
            url: sherpaReleases + "sherpa-onnx-v1.13.8-ios-static.xcframework.zip",
            checksum: "6b8e769cb153343270fdccbe92e3b3db0d1c421d67fa0989ab01fdf5b2fcf2de" // pragma: allowlist secret
        ),
        .binaryTarget(
            name: "SherpaOnnxMacOS",
            url: sherpaReleases + "sherpa-onnx-v1.13.8-macos-static.xcframework.zip",
            checksum: "93f7a064abe99e0d6185a88c5b36ce18c4bff35cd0d5e4e81f81151de8e3e7e5" // pragma: allowlist secret
        ),
        .target(name: "COnnxRuntime", dependencies: ["onnxruntime"],
                linkerSettings: [.linkedLibrary("c++"), .linkedFramework("CoreML")]),
        .target(name: "AllyOnnx", dependencies: ["COnnxRuntime"]),
        .target(name: "AllySherpa", dependencies: [
            "AllyOnnx",
            .target(name: "SherpaOnnxIOS", condition: .when(platforms: [.iOS])),
            .target(name: "SherpaOnnxMacOS", condition: .when(platforms: [.macOS]))
        ]),
        .testTarget(name: "AllyOnnxTests", dependencies: ["AllyOnnx"], resources: [.copy("add.onnx")])
    ]
)
