// swift-tools-version:5.10
import PackageDescription

// The child screen (оболочка). ShellCore — poses, frames, layout and palette on Foundation (Linux CI); ShellUI — the
// drawing in SwiftUI, every file under `#if canImport(SwiftUI)`, so on Linux the package builds with ShellUI empty and
// the snapshot tests skip visibly. iOS and macOS 27 — the app's target (app-glass, the parent 2026-10-27: Liquid Glass
// «под iOS 27»); as strings, so the tools version and the Linux job stay as they are.
let package = Package(
    name: "AllyShell",
    platforms: [.iOS("27.0"), .macOS("27.0")],
    products: [
        .library(name: "ShellCore", targets: ["ShellCore"]),
        .library(name: "ShellUI", targets: ["ShellUI"])
    ],
    dependencies: [.package(path: "../AllyCore")],
    targets: [
        .target(name: "ShellCore", dependencies: [.product(name: "AllyCore", package: "AllyCore")]),
        .target(name: "ShellUI", dependencies: ["ShellCore", .product(name: "AllyCore", package: "AllyCore")]),
        .testTarget(name: "ShellCoreTests",
                    dependencies: ["ShellCore", .product(name: "AllyCore", package: "AllyCore")]),
        .testTarget(name: "ShellUITests",
                    dependencies: ["ShellUI", "ShellCore", .product(name: "AllyCore", package: "AllyCore")])
    ]
)
