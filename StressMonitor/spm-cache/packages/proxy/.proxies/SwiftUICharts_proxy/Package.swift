// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftUICharts_proxy",
    products: [
        .library(name: "SwiftUICharts", targets: ["SwiftUICharts_SwiftUICharts_shim"])
    ],
    dependencies: [
        .package(url: "https://github.com/willdale/SwiftUICharts.git", revision: "c16f47217d1e32900f6b37c322d419945fadae9c")
    ],
    targets: [
        .target(name: "SwiftUICharts_SwiftUICharts_shim", dependencies: [
                .product(name: "SwiftUICharts", package: "SwiftUICharts")
            ], path: "Sources/SwiftUICharts_SwiftUICharts_shim")
    ]
)