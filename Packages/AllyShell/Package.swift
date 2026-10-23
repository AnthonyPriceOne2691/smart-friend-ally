// swift-tools-version:5.10
import PackageDescription

// The child screen (оболочка). ShellCore — poses, frames, layout and palette on Foundation (Linux CI); ShellUI — the
// drawing in SwiftUI, every file under `#if canImport(SwiftUI)`, so on Linux the package builds with ShellUI empty and
// the snapshot tests skip visibly.
let package = Package(
    name: "AllyShell",
    platforms: [.iOS(.v17), .macOS(.v14)],
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
