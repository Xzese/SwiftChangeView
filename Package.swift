// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ChangeView",
    platforms: [.iOS(.v17)],
    products: [.library(name: "ChangeView", targets: ["ChangeView"])],
    targets: [
        .target(name: "ChangeView"),
        .testTarget(name: "ChangeViewTests", dependencies: ["ChangeView"]),
    ]
)
