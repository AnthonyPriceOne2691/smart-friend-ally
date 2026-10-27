// swift-tools-version:5.10
import PackageDescription

// The hearing on the phone (series «слух», D7.2): Silero VAD through sherpa-onnx's C API on the one ONNX Runtime of the
// app (AllyOnnx), as the activity the core's end-of-speech detector takes. The model is not in git — the app's Models
// folder on the phone, the speech-in spike's folder in local/ on the Mac; the tests run on the Mac, not on Linux.
let package = Package(
    name: "AllyHearing",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AllyHearing", targets: ["AllyHearing"]),
               .executable(name: "asr-step3", targets: ["StepThreeTool"])],
    dependencies: [.package(path: "../AllyCore"), .package(path: "../AllyOnnx")],
    targets: [
        .target(name: "AllyHearing", dependencies: [.product(name: "AllyCore", package: "AllyCore"),
                                                    .product(name: "AllySherpa", package: "AllyOnnx")]),
        // Step 3 on the Mac (D7.4): the parent's tool over the black box export; the app does not link it.
        .executableTarget(name: "StepThreeTool", dependencies: ["AllyHearing"]),
        .testTarget(name: "AllyHearingTests", dependencies: ["AllyHearing", "StepThreeTool"])
    ]
)
