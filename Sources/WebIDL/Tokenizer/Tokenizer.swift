//
//  Created by Manuel Burghard. Licensed unter MIT.
//

// swiftlint:disable file_length

import Foundation
import SwiftSyntax

///
public typealias Tokens = [Token]

public struct TokenizationResult: CustomStringConvertible {

    public let tokens: Tokens
    public let identifiers: [String]
    public let integers: [Int]
    public let decimals: [Double]
    public let strings: [String]
    public let others: [String]

    func merging(_ other: TokenizationResult) -> TokenizationResult {

        TokenizationResult(tokens: tokens + other.tokens,
                           identifiers: identifiers + other.identifiers,
                           integers: integers + other.integers,
                           decimals: decimals + other.decimals,
                           strings: strings + other.strings,
                           others: others + other.others)
    }

    public var description: String {

        var identifiers = self.identifiers
        var integers = self.integers
        var decimals = self.decimals
        var strings = self.strings
        var others = self.others

        var stringValues = [String]()

        var iterator = tokens.makeIterator()
        while let token = iterator.next() {

            switch token.kind {
            case .terminal(.closingSquareBracket): stringValues.append("]\n")
            case .terminal(.openingCurlyBraces): stringValues.append("{\n")
            case .terminal(.semicolon): stringValues.append(";\n")
            case .terminal(let symbol): stringValues.append(symbol.rawValue)
            case .identifier: stringValues.append(identifiers.removeFirst())
            case .integer: stringValues.append(String(integers.removeFirst()))
            case .decimal: stringValues.append(String(decimals.removeFirst()))
            case .string: stringValues.append("\"\(strings.removeFirst())\"")
            case .comment(let comment): stringValues.append("// \(comment)\n")
            case .multilineComment(let comment): stringValues.append("/*\n\(comment)\n*/")
            case .other: stringValues.append(others.removeFirst())
            }
        }

        return stringValues.joined(separator: " ")
    }
}

extension NSRegularExpression {

    func match(_ string: String) -> Bool {
        let fullRange = NSRange(string.startIndex ..< string.endIndex, in: string)
        guard let firstMatch = self.firstMatch(in: string, options: [], range: fullRange) else {
            return false
        }
        return firstMatch.range == fullRange
    }
}

// swiftlint:disable type_body_length
/// `Tokenizer` converts an input string, file, or directory with files into a token stream.
public enum Tokenizer {

    // swiftlint:disable force_try
    static let integerRegex = try! NSRegularExpression(pattern: #"-?([1-9][0-9]*|0[Xx][0-9A-Fa-f]+|0[0-7]*)"#)
    static let decimalRegex = try! NSRegularExpression(pattern: #"-?(([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([Ee][+-]?[0-9]+)?|[0-9]+[Ee][+-]?[0-9]+)"#)
    static let identifierRegex = try! NSRegularExpression(pattern: #"[_-]?[A-Za-z][0-9A-Z_a-z-]*"#)
    static let otherRegex = try! NSRegularExpression(pattern: #"[^\t\n\r 0-9A-Za-z]"#)
    // swiftlint:enable force_try

    /// Tokenize all `.idl` files in the given directory
    /// - Parameter directoryURL: An URL to a directory that contains `.idl` files
    /// - Throws: Any error related to the file operations or the tokenization operation.
    /// - Returns: A `TokenizationResult` instance containing the token stream for the given files.
    public static func tokenize(filesInDirectoryAt directoryURL: URL) throws -> TokenizationResult? {

        var tokenizationResult = TokenizationResult(tokens: [], identifiers: [], integers: [], decimals: [], strings: [], others: [])
        let files = try FileManager.default.contentsOfDirectory(at: directoryURL,
                                                                includingPropertiesForKeys: nil,
                                                                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants])
        for file in files where file.pathExtension == "idl" {

            guard let result = try Tokenizer.tokenize(fileAt: file) else {
                continue
            }
            tokenizationResult = tokenizationResult.merging(result)
        }
        return tokenizationResult
    }

    /// Tokenize a single Web IDL file
    /// - Parameter fileURL: An URL to a file containing Web IDL definitions.
    /// - Throws: Any error related to the file operations or the tokenization operation.
    /// - Returns: A `TokenizationResult` instance containing the token stream for the given file.
    public static func tokenize(fileAt fileURL: URL) throws -> TokenizationResult? {

        let fileData = try Data(contentsOf: fileURL)
        guard let string = String(data: fileData, encoding: .utf8) else {
            return nil
        }
        return try tokenize(string, filePath: fileURL.path)
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    /// Tokenize Web IDL definitions
    /// - Parameter string: A string containing Web IDL definitions.
    /// - Parameter filePath: A path to the file containing Web IDL definitions.
    /// - Throws: Any error related to the file operations or the tokenization operation.
    /// - Returns: A `TokenizationResult` instance containing the token stream for the given file.
    public static func tokenize(_ string: String, filePath: String = "<unknown>") throws -> TokenizationResult {

        var tokens = Tokens()

        var state = State.regular
        var buffer = ""
        var tokenStartOffset = 0
        var currentIndex = string.utf8.startIndex
        var currentOffset = 0

        func reset() {
            state = .regular
            buffer = ""
        }

        var identifiers: [String] = []
        var integers: [Int] = []
        var decimals: [Double] = []
        var strings: [String] = []
        var others: [String] = []

        func currentRange() -> SourceRange {
            let converter = SourceLocationConverter(file: filePath, source: string)

            return .init(
                start: .init(offset: tokenStartOffset, converter: converter),
                end: .init(offset: currentOffset, converter: converter)
            )
        }

        func appendToken(_ kind: Token.Kind) {
            tokens.append(.init(kind: kind, range: currentRange()))
            tokenStartOffset = currentOffset + 1
        }

        func appendIntegerLiteral() {
            defer { reset() }
            guard let integer = Int(buffer) else {
                return
            }
            appendToken(.integer)
            integers.append(integer)
        }

        func appendHexLiteral() {
            defer { reset() }
            guard let integer = Int(buffer, radix: 16) else {
                return
            }
            appendToken(.integer)
            integers.append(integer)
        }

        func appendDecimalLiteral() {
            defer { reset() }
            guard let double = Double(buffer) else {
                return
            }
            appendToken(.decimal)
            decimals.append(double)
        }

        func appendIdentifier() {
            if let symbol = Terminal(rawValue: buffer) {
                appendToken(.terminal(symbol))
            } else if identifierRegex.match(buffer) {
                appendToken(.identifier)
                identifiers.append(buffer)
            } else if integerRegex.match(buffer), let integer = Int(buffer) ?? Int(buffer, radix: 16) {
                appendToken(.integer)
                integers.append(integer)
            } else if decimalRegex.match(buffer), let double = Double(buffer) {
                appendToken(.decimal)
                decimals.append(double)
            } else if otherRegex.match(buffer) {
                appendToken(.other)
                others.append(buffer)
            } else {
                print("[\(filePath):\(currentRange())] Undefined sequence: \(buffer)")
            }
            reset()
        }

        while currentIndex < string.utf8.endIndex, let character = String(
                decoding: [string.utf8[currentIndex]],
                as: UTF8.self
        ).first {
            defer {
                if currentOffset < string.utf8.count - 1 {
                    currentOffset += 1
                }
                currentIndex = string.utf8.index(after: currentIndex)
            }

            switch (state, character) {
            case (.identifier, "["):
                appendIdentifier()
                appendToken(.terminal(.openingSquareBracket))

            case (.regular, "["):
                appendToken(.terminal(.openingSquareBracket))

            case (.identifier, "]"):
                appendIdentifier()
                fallthrough

            case (.regular, "]"):
                appendToken(.terminal(.closingSquareBracket))

            case (.identifier, "("):
                appendIdentifier()
                fallthrough

            case (.regular, "("):
                appendToken(.terminal(.openingParenthesis))

            case (.identifier, ")"):
                appendIdentifier()
                appendToken(.terminal(.closingParenthesis))

            case (.integerLiteral, ")"):
                appendIntegerLiteral()
                appendToken(.terminal(.closingParenthesis))

            case (.hexLiteral, ")"):
                appendHexLiteral()
                appendToken(.terminal(.closingParenthesis))

            case (.regular, ")"):
                appendToken(.terminal(.closingParenthesis))

            case (.identifier, "<"):
                appendIdentifier()
                appendToken(.terminal(.openingAngleBracket))

            case (.regular, "<"):
                appendToken(.terminal(.openingAngleBracket))

            case (.identifier, ">"):
                appendIdentifier()
                appendToken(.terminal(.closingAngleBracket))

            case (.regular, ">"):
                appendToken(.terminal(.closingAngleBracket))

            case (.identifier, "{"):
                appendIdentifier()
                appendToken(.terminal(.openingCurlyBraces))

            case (.regular, "{"):
                appendToken(.terminal(.openingCurlyBraces))

            case (.identifier, "}"):
                appendIdentifier()
                appendToken(.terminal(.closingCurlyBraces))

            case (.regular, "}"):
                appendToken(.terminal(.closingCurlyBraces))

            case (.identifier, "?"):
                appendIdentifier()
                appendToken(.terminal(.questionMark))

            case (.regular, "?"):
                appendToken(.terminal(.questionMark))

            case (.identifier, "="):
                appendIdentifier()
                appendToken(.terminal(.equalSign))

            case (.regular, "="):
                appendToken(.terminal(.equalSign))

            case (.identifier, ","):
                appendIdentifier()
                appendToken(.terminal(.comma))

            case (.integerLiteral, ","):
                appendIntegerLiteral()
                appendToken(.terminal(.comma))

            case (.hexLiteral, ","):
                appendHexLiteral()
                appendToken(.terminal(.comma))

            case (.decimalLiteral, ","):
                appendDecimalLiteral()
                appendToken(.terminal(.comma))

            case (.regular, ","):
                appendToken(.terminal(.comma))

            case (.identifier, ";"):
                appendIdentifier()
                appendToken(.terminal(.semicolon))

            case (.integerLiteral, ";"):
                appendIntegerLiteral()
                appendToken(.terminal(.semicolon))

            case (.integerLiteral, "."):
                state = .decimalLiteral
                buffer.append(".")

            case (.hexLiteral, ";"):
                appendHexLiteral()
                appendToken(.terminal(.semicolon))

            case (.decimalLiteral, ";"):
                appendDecimalLiteral()
                appendToken(.terminal(.semicolon))

            case (.regular, ";"):
                appendToken(.terminal(.semicolon))

            case (.identifier, ":"):
                appendIdentifier()
                appendToken(.terminal(.colon))

            case (.identifier, "."):
                appendIdentifier()
                state = .startOfEllipsis

            case (.regular, ":"):
                appendToken(.terminal(.colon))

            case (.regular, "."):
                state = .startOfEllipsis

            case (.startOfEllipsis, "."):
                state = .ellipsis

            case (.startOfEllipsis, let char) where char.isWhitespace || char.isNewline:
                appendToken(.terminal(.dot))
                reset()

            case (.ellipsis, "."):
                appendToken(.terminal(.ellipsis))
                reset()

            case (.ellipsis, let char) where char.isWhitespace || char.isNewline:
                appendToken(.terminal(.dot))
                appendToken(.terminal(.dot))
                reset()

            case (.integerLiteral, let char) where buffer.count == 1 && char.lowercased() == "x":
                state = .hexLiteral
                buffer = ""

            case (.hexLiteral, let char) where char.isHexDigit:
                buffer.append(char)

            case (.regular, "-"):
                buffer.append("-")

            case (.regular, let char) where char.isNumber,
                 (.integerLiteral, let char) where char.isNumber:
                state = .integerLiteral
                buffer.append(char)

            case (.decimalLiteral, let char) where char.isNumber:
                buffer.append(char)

            case (.decimalLiteral, "e") where !buffer.contains("e"),
                 (.decimalLiteral, "E") where !buffer.contains("e"),
                 (.integerLiteral, "e") where !buffer.contains("e"),
                 (.integerLiteral, "E") where !buffer.contains("e"):
                state = .decimalLiteral
                buffer.append("e")
                
            case (.decimalLiteral, "+") where buffer.last == "e":
                buffer.append("+")

            case (.integerLiteral, let char) where char.isWhitespace || char.isNewline:
                appendIntegerLiteral()

            case (.hexLiteral, let char) where char.isWhitespace || char.isNewline:
                appendHexLiteral()

            case (.decimalLiteral, let char) where char.isWhitespace || char.isNewline:
                appendDecimalLiteral()

            case (.regular, "/"):
                state = .startOfComment

            case (.startOfComment, "/"):
                state = .comment
                buffer = ""

            case (.comment, let char):
                if buffer.isEmpty, char.isWhitespace { continue }
                if char.isNewline {
                    appendToken(.comment(buffer))
                    reset()
                    continue
                }
                buffer.append(char)

            case (.startOfComment, "*"):
                state = .multilineComment
                buffer = ""

            case (.multilineComment, "*"):
                state = .maybeEndOfMultilineComment

            case (.maybeEndOfMultilineComment, "/"):
                appendToken(.multilineComment(buffer))
                reset()

            case (.maybeEndOfMultilineComment, "*"):
                buffer.append("*")

            case (.maybeEndOfMultilineComment, let char):
                state = .multilineComment
                buffer.append("*")
                buffer.append(char)

            case (.multilineComment, let char):
                buffer.append(char)

            case (.regular, let char) where char.isLetter || "_" == char:
                state = .identifier
                buffer.append(char)

            case (.identifier, let char) where char.isWhitespace || char.isNewline:
                appendIdentifier()

            case (.identifier, let char) where char.isLetter || ["_", "-"].contains(char) || char.isNumber:
                buffer.append(char)

            case (.regular, "\""):
                buffer = ""
                state = .stringLiteral

            case (.stringLiteral, "\\"):
                state = .escapedChar

            case (.escapedChar, "\""):
                state = .stringLiteral

            case (.stringLiteral, "\""):
                appendToken(.string)
                strings.append(buffer)
                reset()

            case (.stringLiteral, let char):
                buffer.append(char)

            default:
                tokenStartOffset += 1
                continue
            }
        }

        switch state {
        case .regular:
            break
        case .identifier:
            appendIdentifier()
        case .integerLiteral:
            appendIntegerLiteral()
        case .hexLiteral:
            appendHexLiteral()
        case .decimalLiteral:
            appendDecimalLiteral()
        case .stringLiteral:
            break
        case .escapedChar:
            break
        case .comment:
            appendToken(.comment(buffer))
        case .multilineComment:
            appendToken(.multilineComment(buffer))
        case .startOfComment, .maybeEndOfMultilineComment:
            fatalError("Unterminated start of comment")
        case .startOfEllipsis:
            appendToken(.terminal(.dot))
        case .ellipsis:
            appendToken(.terminal(.dot))
            appendToken(.terminal(.dot))
        }

        return TokenizationResult(tokens: tokens, identifiers: identifiers, integers: integers, decimals: decimals, strings: strings, others: others)
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
}
// swiftlint:enable type_body_length
