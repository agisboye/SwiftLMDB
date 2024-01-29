// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "SwiftLMDB",
    products: [
        .library(name: "SwiftLMDB", targets: ["SwiftLMDB"]),
    ],
    
    dependencies: [
        .package(url: "https://github.com/agisboye/CLMDB.git", exact: "0.9.31")
    ],

    targets: [
        .target(name: "SwiftLMDB", dependencies: [.product(name: "LMDB", package: "CLMDB")], path: "Sources"),
        .testTarget(name: "SwiftLMDBTests", dependencies: ["SwiftLMDB"]),
    ]
)
