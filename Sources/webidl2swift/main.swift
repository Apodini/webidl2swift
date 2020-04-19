//
//  Created by Manuel Burghard on 18.04.20.
//

import Foundation

import WebIDL

import ArgumentParser
import SwiftFormat
import SwiftFormatConfiguration

struct WebIDL2Swift: ParsableCommand {

    @Option(name: .shortAndLong, help: "The path to the directory containing Web IDL files.")
    var inputDirectory: String

    @Option(name: .shortAndLong, help: "The path to the output directory.")
    var ouputDirectory: String

    @Flag(help: "Create a file for each definition.")
    var createSeparateFiles: Bool

    @Flag(help: "Print verbose output")
    var verbose: Bool

    @Flag(help: "Run swift-format over output.")
    var prettyPrint: Bool


    func run() throws {

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
        let definitions = try parser.parse()

        var configuration = Configuration()
        configuration.indentation = .spaces(4)
        let formatter = SwiftFormatter(configuration: configuration)

        let codeGenerator = IRGenerator()
        let ir = codeGenerator.generateIR(for: definitions)

        let undefinedTypes = ir.filter {
            $0.value.node == nil
        }

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

            ],
            targets: [
                .target(name: "WebAPI", dependencies: [])
            ]
        )
        """

        try Data(packageSwift.utf8).write(to: packageDirectory.appendingPathComponent("Package.swift"), options: .atomicWrite)

        let swiftDeclarations: [(String, String)] = try ir.sorted(by: { $0.key < $1.key })
            .map({ (k, v) in
                //print(k, v.node!.swiftDeclaration)

                let input = v.node!.swiftDeclaration
                var output = ""
                if prettyPrint {
                    try formatter.format(source: input, assumingFileURL: nil, to: &output)
                } else {
                    output = input
                }
                return (k, output)
            })
            .filter({ !$0.1.isEmpty })

        if createSeparateFiles {
            for declaration in swiftDeclarations {
                let name = declaration.0
                let content = preamble + declaration.1
                let data = Data(content.utf8)
                try data.write(to: sourcesDirectory.appendingPathComponent("\(name).swift"), options: .atomicWrite)
            }

        } else {
            let generated = preamble + swiftDeclarations.map({ $0.1 }).joined(separator: "\n\n")

            let data = Data(generated.utf8)
            try data.write(to: sourcesDirectory.appendingPathComponent("WebAPI.swift"), options: .atomicWrite)
        }
    }
}

WebIDL2Swift.main()
