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
    targets: [
        .target(
            name: "OtplessSDKSwift",
            path: "OtplessSDK/Classes",
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
