// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GoogleSignIn-iOS_proxy",
    products: [
        .library(name: "GoogleSignIn_proxied", targets: ["GoogleSignIn-iOS_GoogleSignIn_shim"]),
        .library(name: "GoogleSignInSwift_proxied", targets: ["GoogleSignIn-iOS_GoogleSignInSwift_shim"])
    ],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", revision: "08d8dcecafb575f98879ffdbb8302c1b9ad65d19")
    ],
    targets: [
        .target(name: "GoogleSignIn-iOS_GoogleSignIn_shim", dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ], path: "Sources/GoogleSignIn-iOS_GoogleSignIn_shim"),
        .target(name: "GoogleSignIn-iOS_GoogleSignInSwift_shim", dependencies: [
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS")
            ], path: "Sources/GoogleSignIn-iOS_GoogleSignInSwift_shim")
    ]
)