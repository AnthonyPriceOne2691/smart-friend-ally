// swift-tools-version:5.10
import PackageDescription

// The child screen (оболочка). ShellCore — poses, layout and palette on Foundation (Linux CI). The SwiftUI drawing
// (ShellUI, every file under `#if canImport(SwiftUI)`) joins with its snapshot tests in slice 3 of tasks.md.
let package = Package(
    name: "AllyShell",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "ShellCore", targets: ["ShellCore"])],
    dependencies: [.package(path: "../AllyCore")],
    targets: [
        .target(name: "ShellCore", dependencies: [.product(name: "AllyCore", package: "AllyCore")]),
        .testTarget(name: "ShellCoreTests",
                    dependencies: ["ShellCore", .product(name: "AllyCore", package: "AllyCore")])
    ]
)
