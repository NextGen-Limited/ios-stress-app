// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Firebase_proxy",
    products: [
        .library(name: "FirebaseAuth_proxied", targets: ["Firebase_FirebaseAuth_shim"]),
        .library(name: "FirebaseCore_proxied", targets: ["Firebase_FirebaseCore_shim"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", revision: "fdc352fabaf5916e7faa1f96ad02b1957e93e5a5")
    ],
    targets: [
        .target(name: "Firebase_FirebaseAuth_shim", dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ], path: "Sources/Firebase_FirebaseAuth_shim"),
        .target(name: "Firebase_FirebaseCore_shim", dependencies: [
                .product(name: "FirebaseCore", package: "firebase-ios-sdk")
            ], path: "Sources/Firebase_FirebaseCore_shim")
    ]
)
