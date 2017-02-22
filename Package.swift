import PackageDescription

let package = Package(
    name: "SwiftLMDB",
    dependencies: [
      .Package(url: "../CLMDB", majorVersion: 0, minor: 0),
      ]
)

