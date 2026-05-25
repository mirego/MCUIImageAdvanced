// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "MCUIImageAdvanced",
    platforms: [
        .iOS("9.0"),
        .tvOS("9.0")
    ],
    products: [
        .library(
            name: "MCUIImageAdvanced",
            targets: ["MCUIImageAdvanced"]
        )
    ],
    targets: [
        .target(
            name: "MCUIImageAdvanced",
            publicHeadersPath: "include"
        )
    ]
)
