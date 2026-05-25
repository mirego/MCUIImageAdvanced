// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "MCUIImageAdvanced",
    platforms: [
        .iOS("12.0"),
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
            path: "MCUIImageAdvanced",
            exclude: [
                "include"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("MGImageUtilities"),
                .headerSearchPath("ShrinkPNG"),
                .headerSearchPath("include/MCUIImageAdvanced")
            ]
        )
    ]
)
