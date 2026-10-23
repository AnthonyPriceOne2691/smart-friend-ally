// swift-tools-version:5.10
import PackageDescription

// The voice engine behind `SpeechEngine` (voice series V1–V4): Supertonic 3 on the one ONNX Runtime of the app
// (AllyOnnx). Weights are not in git — ~/models/tts/supertonic-3-ext on the Mac, the app's Voice folder on the phone
// (V4); the tests run on the Mac against the Python reference, not on Linux.
let package = Package(
    name: "AllyVoice",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AllyVoice", targets: ["AllyVoice"])],
    dependencies: [.package(path: "../AllyOnnx")],
    targets: [
        .target(name: "AllyVoice", dependencies: [.product(name: "AllyOnnx", package: "AllyOnnx")]),
        .testTarget(name: "AllyVoiceTests", dependencies: ["AllyVoice"])
    ]
)
