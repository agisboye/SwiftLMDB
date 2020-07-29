// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftLMDB",
    products: [
        .library(name: "SwiftLMDB", targets: ["SwiftLMDB"]),
    ],
    
    dependencies: [
        .package(url: "https://github.com/esurio/CLMDB.git", .exact("0.9.24")),
    ],

    targets: [
        .target(name: "SwiftLMDB", dependencies: ["LMDB"], path: "Sources"),
        .testTarget(name: "SwiftLMDBTests", dependencies: ["SwiftLMDB"]),
    ]
)
