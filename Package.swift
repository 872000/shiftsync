// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShiftSync",
    products: [
        .library(name: "ShiftSync", targets: ["ShiftSync"]),
    ],
    targets: [
        .target(
            name: "ShiftSync",
            path: "Sources/ShiftSync"
        ),
        .testTarget(
            name: "ShiftSyncTests",
            dependencies: ["ShiftSync"],
            path: "Tests/ShiftSyncTests"
        ),
    ]
)
