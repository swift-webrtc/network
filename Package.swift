// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "webrtc-network",
  products: [
    .library(name: "Network", targets: ["Network"]),
  ],
  dependencies: [
    .package(name: "webrtc-core", url: "https://github.com/swift-webrtc/core.git", .branch("master"))
  ],
  targets: [
    .target(name: "Network", dependencies: [
      .product(name: "Core", package: "webrtc-core")
    ]),
    .target(name: "NetworkExamples", dependencies: ["Network"]),
    .testTarget(name: "NetworkTests", dependencies: ["Network"]),
  ]
)
