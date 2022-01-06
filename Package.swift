// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TicketingLibrary",
    platforms: [.iOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TicketingLibrary",
            targets: ["TicketingLibrary"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.4.3"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.0.0"),
        .package(url: "https://github.com/eu-digital-green-certificates/dgc-certlogic-ios.git", branch: "main"),
        .package(url: "https://github.com/auth0/JWTDecode.swift.git", from: "2.0.0"),
        .package(url: "https://github.com/eu-digital-green-certificates/dgca-app-core-ios", branch: "feature/ticketing_module"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TicketingLibrary",
            dependencies: ["Alamofire",
                "CryptoSwift",
                .product(name: "CertLogic", package: "dgc-certlogic-ios"),
                .product(name: "SwiftDGC", package: "dgca-app-core-ios"),
                .product(name: "JWTDecode", package: "JWTDecode.swift")
            ],
            path: "Sources"),
        .testTarget(
            name: "TicketingLibraryTests",
            dependencies: ["TicketingLibrary"]),
    ]
)
