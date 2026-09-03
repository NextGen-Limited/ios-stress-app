// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "spm_cache_proxy",
    products: [
        .library(name: "spm_cache_proxy", targets: ["spm_cache_root"])
    ],
    dependencies: [
        .package(path: ".proxies/GoogleSignIn-iOS_proxy"),
        .package(path: ".proxies/Firebase_proxy")
    ],
    targets: [
        .target(name: "spm_cache_root", dependencies: [
            .product(name: "GoogleSignIn_proxied", package: "GoogleSignIn-iOS_proxy"),
                    .product(name: "GoogleSignInSwift_proxied", package: "GoogleSignIn-iOS_proxy"),
                .product(name: "FirebaseAuth_proxied", package: "Firebase_proxy"),
                .product(name: "FirebaseCore_proxied", package: "Firebase_proxy")
        ], path: "src/root")
    ]
)