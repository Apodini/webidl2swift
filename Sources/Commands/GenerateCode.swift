
import Foundation

import WebIDL

import ArgumentParser
import SwiftFormat
import SwiftFormatConfiguration

public struct GenerateCode: ParsableCommand {

    @Option(name: .shortAndLong, help: "The path to the directory containing Web IDL files.")
    var inputDirectory: String

    @Option(name: .shortAndLong, help: "The path to the output directory.")
    var ouputDirectory: String

    @Flag(name: .long, default: true, inversion: .prefixedNo, help: "Create a file for each definition.")
    var createSeparateFiles: Bool

    @Flag(help: "Print verbose output")
    var verbose: Bool

    @Flag(name: .long, default: true, inversion: .prefixedNo, help: "Run swift-format over output.")
    var prettyPrint: Bool

    public init() {}

    public func run() throws {

        if verbose {
            print("inputDirectory: \(inputDirectory)")
            print("ouputDirectory: \(ouputDirectory)")
            print("createSeparateFiles: \(createSeparateFiles)")
        }

        guard let tokenisationResult = try Tokenizer.tokenize(filesInDirectoryAt: URL(fileURLWithPath: inputDirectory)) else {
            print("Error tokenizing input files.")
            Self.exit(withError: ExitCode.failure)
        }

        let parser = Parser(input: tokenisationResult)
        let definitions: [Definition]
        do {
            definitions = try parser.parse()
        } catch let error as Parser.Error {
            print(error.localizedDescription)
            Self.exit(withError: ExitCode.failure)
        } catch {
            throw error
        }

        var configuration = Configuration()
        configuration.indentation = .spaces(4)
        let formatter = SwiftFormatter(configuration: configuration)

        let codeGenerator = IRGenerator()
        let ir = codeGenerator.generateIR(for: definitions)

        let undefinedTypes = ir.undefinedTypes

        guard undefinedTypes.isEmpty else {
            print("Error: The following types are undefined:")
            print(undefinedTypes.map({"\t- \($0.0)"}).joined(separator: "\n"))
            Self.exit(withError: ExitCode.failure)
        }

        let preamble = """

        /*
         * The following code is auto generated using webidl2swift
         */

        import JavaScriptKit
        import ECMAScript


        """

        let packageDirectory = URL(fileURLWithPath: ouputDirectory).appendingPathComponent("WebAPI")
        let sourcesDirectory = packageDirectory.appendingPathComponent("Sources").appendingPathComponent("WebAPI")

        let fileManager = FileManager.default

        try fileManager.createDirectory(at: sourcesDirectory, withIntermediateDirectories: true)

        let packageSwift = """
        // swift-tools-version:5.2
        // The swift-tools-version declares the minimum version of Swift required to build this package.

        import PackageDescription

        let package = Package(
            name: "WebAPI",
            products: [
                .library(name: "WebAPI", targets: ["WebAPI"]),
            ],
            dependencies: [
                .package(name: "JavaScriptKit", url: "https://github.com/Unkaputtbar/JavaScriptKit.git", .branch("feature/webidl-support")),
                .package(name: "ECMAScript", path: "../ECMAScript"),
            ],
            targets: [
                .target(name: "WebAPI", dependencies: ["JavaScriptKit", "ECMAScript"])
            ]
        )
        """

        try Data(packageSwift.utf8).write(to: packageDirectory.appendingPathComponent("Package.swift"), options: .atomicWrite)

        let swiftDeclarations: [(String, String)] = ir.sorted(by: { $0.key < $1.key })
            .map({ (k, v) in

                return (k, v.node!.swiftDeclaration)
            })
            .filter({ !$0.1.isEmpty })

        if createSeparateFiles {
            DispatchQueue.concurrentPerform(iterations: swiftDeclarations.count) { (index) in

                let declaration = swiftDeclarations[index]
                let name = declaration.0
                let content = preamble + declaration.1

                var output = ""
                if prettyPrint {
                    do {
                        try formatter.format(source: content, assumingFileURL: nil, to: &output)
                    } catch {
                        Self.exit(withError: ExitCode.failure)
                    }
                } else {
                    output = content
                }

                let data = Data(output.utf8)
                do {
                    try data.write(to: sourcesDirectory.appendingPathComponent("\(name).swift"), options: .atomicWrite)
                } catch {
                    Self.exit(withError: ExitCode.failure)
                }
            }
        } else {
            let generated = preamble + swiftDeclarations.map({ $0.1 }).joined(separator: "\n\n")
            var output = ""
            if prettyPrint {
                try formatter.format(source: generated, assumingFileURL: nil, to: &output)
            } else {
                output = generated
            }

            let data = Data(output.utf8)
            try data.write(to: sourcesDirectory.appendingPathComponent("WebAPI.swift"), options: .atomicWrite)
        }
    }
}
