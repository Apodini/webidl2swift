// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HelloWorld",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "HelloWorld",
            targets: ["HelloWorld"]),
    ],
    dependencies: [
        .package(name: "JavaScriptKit", url: "https://github.com/Unkaputtbar/JavaScriptKit.git", .branch("feature/webidl-support")),
        .package(name: "ECMAScript", url: "https://github.com/Unkaputtbar/ECMAScript.git", .branch("develop")),
        .package(name: "WebAPI", path: "../WebAPI/WebAPI"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "HelloWorld",
            dependencies: ["JavaScriptKit", "ECMAScript", "WebAPI"]
        ),
    ]
)
