// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppAd",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [.library(name: "AppAd", targets: ["AppAd"])],
    targets: [
        .target(name: "AppAd", resources: [.process("Resources/app-ads.json"), .copy("Resources/Icons"),
                                                  .process("Resources/en.lproj"),
                                                  .process("Resources/zh-Hans.lproj"),
                                                  .process("Resources/zh-Hant.lproj")]),
        .testTarget(name: "AppAdTests", dependencies: ["AppAd"])
    ]
)
