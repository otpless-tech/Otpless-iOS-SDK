// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Otpless-iOS-SDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Otpless-iOS-SDK",
            targets: ["OtplessSDKSwift", "OtplessSDKObjc"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "8.1.0-vwg-eap-1.0.0"),
        .package(url: "https://github.com/facebook/facebook-ios-sdk.git", from: "17.4.0")
    ],
    targets: [
        .target(
            name: "OtplessSDKSwift",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "FacebookCore", package: "facebook-ios-sdk"),
                .product(name: "FacebookLogin", package: "facebook-ios-sdk")
            ], path: "OtplessSDK/Classes",
            sources: ["SwiftSources"]
        ),
        .target(
            name: "OtplessSDKObjc",
            path: "OtplessSDK/Classes",
            sources: ["ObjcSources"]
        )
    ],
    swiftLanguageVersions: [.v4, .v5]
)
