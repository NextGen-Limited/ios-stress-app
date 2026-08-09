// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "spm_cache_proxy",
    products: [
        .library(name: "spm_cache_proxy", targets: ["spm_cache_root"])
    ],
    dependencies: [
        .package(path: ".proxies/Chat_proxy"),
        .package(path: ".proxies/SwiftUICharts_proxy")
    ],
    targets: [
        .target(name: "spm_cache_root", dependencies: [
            .product(name: "ExyteChatProxy", package: "Chat_proxy"),
            .product(name: "SwiftUIChartsProxy", package: "SwiftUICharts_proxy")
        ], path: "src/root")
    ]
)
