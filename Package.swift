// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let modules = ["RFVisuals", "RFNotifications"]
let tests = ["RFNotifications"]

let package = Package(
    name: "RFKit",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
    ],
    products: [
        .library(name: "RFKit", targets: modules),
    ],
    targets: modules.map { .target(name: $0) } + tests.map { .testTarget(name: "\($0)Tests", dependencies: [.byName(name: $0)]) }
)
