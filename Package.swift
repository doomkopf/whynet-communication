// swift-tools-version: 6.3.3
import PackageDescription

let package = Package(
    name: "WhynetCommunication",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "WhynetCommunication",
            targets: ["WhynetCommunication"],
        )
    ],
    dependencies: [
        .package(url: "https://github.com/doomkopf/whynet-connection", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "WhynetCommunication",
            dependencies: [
                .product(name: "WhynetConnection", package: "whynet-connection")
            ],
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["WhynetCommunication"],
            swiftSettings: swiftSettings,
        ),
    ])

var swiftSettings: [SwiftSetting] {
    [
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
