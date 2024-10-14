// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "APIServiceRx",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "APIServiceRx",
            targets: ["APIServiceRx"]),
    ],
    dependencies: [
        .package(name: "APIService", path: "../APIService"),
        .package(
            url: "https://github.com/ReactiveX/RxSwift.git",
            .upToNextMajor(from: "6.0.0")
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "APIServiceRx",
            dependencies: [
                "APIService",
                .product(name: "RxSwift", package: "RxSwift"),
            ]),
        .testTarget(
            name: "APIServiceRxTests",
            dependencies: ["APIServiceRx"]
        ),
    ]
)
