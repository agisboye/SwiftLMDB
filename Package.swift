import PackageDescription

let package = Package(
    name: "SwiftLMDB",
    dependencies: [
      .Package(url: "https://github.com/SUIRON/CLMDB.git", majorVersion: 0, minor: 0),
      ]
)

