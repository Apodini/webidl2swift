// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "webidl2swift",
    platforms: [.macOS(.v10_14)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(name: "webidl2swift", targets: ["webidl2swift", ]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
        .package(name: "swift-format", url: "https://github.com/apple/swift-format.git", .branch("swift-5.2-branch")),
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .branch("swift-5.2-branch")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "webidl2swift",
            dependencies: [
                .target(name: "Commands"),
        ],
            linkerSettings: [
            .unsafeFlags([
                // Fix for missing rpath for lib_InternalSwiftSyntaxParser.dylib when building from within Xcode.
                // lib_InternalSwiftSyntaxParser.dylib is linked by SwiftSyntax.
                "-Xlinker",  "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx/"
            ])
            ]
        ),
        .target(
            name: "WebIDL",
            dependencies: [],
            path: "Sources/WebIDL"
        ),
        .target(
            name: "Commands",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftFormat", package: "swift-format"),
                .product(name: "SwiftSyntax", package: "SwiftSyntax"),
                .target(name: "WebIDL"),
            ],
            // Ran into linker issues: GenerateCode was not usable in tests when it is declared in webidl2swift
            path: "Sources/Commands",
            linkerSettings: [
                .unsafeFlags([
                    // Fix for missing rpath for lib_InternalSwiftSyntaxParser.dylib when building from within Xcode.
                    // lib_InternalSwiftSyntaxParser.dylib is linked by SwiftSyntax.
                    "-Xlinker",  "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx/"
                ])
            ]
        ),
        .testTarget(
            name: "webidl2swiftTests",
            dependencies: [
                "webidl2swift",
            ],
            linkerSettings: [
                .unsafeFlags([
                    // Fix for missing rpath for lib_InternalSwiftSyntaxParser.dylib when building from within Xcode.
                    // lib_InternalSwiftSyntaxParser.dylib is linked by SwiftSyntax.
                    "-Xlinker",  "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx/"
                ])
            ]
        ),
    ]
)
