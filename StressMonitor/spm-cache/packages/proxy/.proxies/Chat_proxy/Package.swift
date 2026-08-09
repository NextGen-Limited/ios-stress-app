// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Chat_proxy",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ExyteChatProxy", targets: ["Chat_ExyteChat_shim"])
    ],
    dependencies: [
        .package(url: "https://github.com/exyte/Chat.git", revision: "2ea8fc57f719d59940cab6551bcd518e2ec6191c")
    ],
    targets: [
        .target(name: "Chat_ExyteChat_shim", dependencies: [
                .product(name: "ExyteChat", package: "Chat")
            ], path: "Sources/Chat_ExyteChat_shim")
    ]
)
