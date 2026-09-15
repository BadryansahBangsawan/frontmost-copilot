// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FrontmostCopilot",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "FrontmostCopilot", targets: ["FrontmostCopilot"])
    ],
    targets: [
        .executableTarget(name: "FrontmostCopilot", path: "Sources")
    ]
)
