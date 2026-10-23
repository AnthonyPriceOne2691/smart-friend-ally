// swift-tools-version:5.10
import PackageDescription

// The one ONNX Runtime of the app (decision 2026-10-23): Microsoft's official onnxruntime-c pod 1.28.0 — a static
// xcframework with iOS, simulator and macOS slices (no binary in git), API 28 like the headers of sherpa-onnx 1.13.8 —
// and a thin Swift layer over its C API. The voice and the hearing use only this one; a second ORT in the app's graph
// is what scripts/lint/check_single_ort.sh refuses. The static runtime needs libc++ and CoreML at link time. Tests run
// on the Mac (the macOS slice), not on Linux.
let package = Package(
    name: "AllyOnnx",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AllyOnnx", targets: ["AllyOnnx"])],
    targets: [
        .binaryTarget(
            name: "onnxruntime",
            url: "https://download.onnxruntime.ai/pod-archive-onnxruntime-c-1.28.0.zip",
            checksum: "b503cf5949ab718a1dff17d1643237ecc0fecf50ad86264572dcafddb140a327" // pragma: allowlist secret
        ),
        .target(name: "COnnxRuntime", dependencies: ["onnxruntime"],
                linkerSettings: [.linkedLibrary("c++"), .linkedFramework("CoreML")]),
        .target(name: "AllyOnnx", dependencies: ["COnnxRuntime"]),
        .testTarget(name: "AllyOnnxTests", dependencies: ["AllyOnnx"], resources: [.copy("add.onnx")])
    ]
)
