// swift-tools-version:5.10
import PackageDescription

// Текст для синтеза (V2 voice-text): только Foundation — пакет собирается и тестируется на Linux.
let package = Package(
    name: "AllySpeechText",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AllySpeechText", targets: ["AllySpeechText"])],
    targets: [
        .target(name: "AllySpeechText", resources: [.process("Resources")]),
        .testTarget(name: "AllySpeechTextTests", dependencies: ["AllySpeechText"])
    ]
)
