//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import XCTest
@testable import WebIDL

final class TokenizerTests: XCTestCase {

    func test_ellipsis() throws {
        XCTAssertEqual(
            try Tokenizer.tokenize("...").tokens,
            [
                .init(
                    kind: .terminal(.ellipsis),
                    range: .init(
                        start: .init(line: 1, column: 1, offset: 0, file: "<unknown>"),
                        end: .init(line: 1, column: 3, offset: 2, file: "<unknown>")
                    )
                )
            ]
        )
        XCTAssertEqual(
            try Tokenizer.tokenize(" ... ").tokens,
            [
                .init(
                    kind: .terminal(.ellipsis),
                    range: .init(
                        start: .init(line: 1, column: 2, offset: 1, file: "<unknown>"),
                        end: .init(line: 1, column: 4, offset: 3, file: "<unknown>")
                    )
                )
            ]
        )
    }

    func test_dot() throws {

        XCTAssertEqual(try Tokenizer.tokenize(".").tokens.map(\.kind), [.terminal(.dot)])
        XCTAssertEqual(try Tokenizer.tokenize(" . ").tokens.map(\.kind), [.terminal(.dot)])
    }

    func test_dotDot() throws {

        XCTAssertEqual(try Tokenizer.tokenize("..").tokens.map(\.kind), [.terminal(.dot), .terminal(.dot)])
        XCTAssertEqual(try Tokenizer.tokenize(" .. ").tokens.map(\.kind), [.terminal(.dot), .terminal(.dot)])
    }

    func test_dotDotDot() throws {

        XCTAssertEqual(try Tokenizer.tokenize(".. .").tokens.map(\.kind), [.terminal(.dot), .terminal(.dot), .terminal(.dot)])
        XCTAssertEqual(try Tokenizer.tokenize(" . . . ").tokens.map(\.kind), [.terminal(.dot), .terminal(.dot), .terminal(.dot)])
    }

    func test_integer() throws {

        var result: TokenizationResult

        result = try Tokenizer.tokenize("0 ")
        XCTAssertEqual(result.tokens.map(\.kind), [.integer])
        XCTAssertEqual(result.integers, [0])

        result = try Tokenizer.tokenize("1\n")
        XCTAssertEqual(result.tokens.map(\.kind), [.integer])
        XCTAssertEqual(result.integers, [1])

        result = try Tokenizer.tokenize("0xf")
        XCTAssertEqual(result.tokens.map(\.kind), [.integer])
        XCTAssertEqual(result.integers, [0xf])

        result = try Tokenizer.tokenize("0XFF, 0XFF; 0XFF")
        XCTAssertEqual(result.tokens.map(\.kind), [.integer, .terminal(.comma), .integer, .terminal(.semicolon), .integer])
        XCTAssertEqual(result.integers, [0xff, 0xff, 0xff])

        result = try Tokenizer.tokenize("-1, -1; -1")
        XCTAssertEqual(result.tokens.map(\.kind), [.integer, .terminal(.comma), .integer, .terminal(.semicolon), .integer])
        XCTAssertEqual(result.integers, [-1, -1, -1])
    }

    func test_decimal() throws {

        var result: TokenizationResult

        result = try Tokenizer.tokenize("0.0 ")
        XCTAssertEqual(result.tokens.map(\.kind), [.decimal])
        XCTAssertEqual(result.decimals, [0.0])

        result = try Tokenizer.tokenize("0.1\n")
        XCTAssertEqual(result.tokens.map(\.kind), [.decimal])
        XCTAssertEqual(result.decimals, [0.1])

        result = try Tokenizer.tokenize("-1.0")
        XCTAssertEqual(result.tokens.map(\.kind), [.decimal])
        XCTAssertEqual(result.decimals, [-1.0])

        result = try Tokenizer.tokenize("1e+10")
        XCTAssertEqual(result.tokens.map(\.kind), [.decimal])
        XCTAssertEqual(result.decimals, [1e+10])

        result = try Tokenizer.tokenize("1E+10")
        XCTAssertEqual(result.tokens.map(\.kind), [.decimal])
        XCTAssertEqual(result.decimals, [1e+10])

        result = try Tokenizer.tokenize("1.5E+10, 1.5E+10; 1.5E+10")
        XCTAssertEqual(result.tokens.map(\.kind), [.decimal, .terminal(.comma), .decimal, .terminal(.semicolon), .decimal])
        XCTAssertEqual(result.decimals, [1.5e+10, 1.5e+10, 1.5e+10])
    }

    func test_identifier() throws {

        var result: TokenizationResult

        result = try Tokenizer.tokenize("abc ")
        XCTAssertEqual(result.tokens.map(\.kind), [.identifier])
        XCTAssertEqual(result.identifiers, ["abc"])

        result = try Tokenizer.tokenize("abc...")
        XCTAssertEqual(result.tokens.map(\.kind), [.identifier, .terminal(.ellipsis)])
        XCTAssertEqual(result.identifiers, ["abc"])

        result = try Tokenizer.tokenize("ABC1\n")
        XCTAssertEqual(result.tokens.map(\.kind), [.identifier])
        XCTAssertEqual(result.identifiers, ["ABC1"])

        result = try Tokenizer.tokenize("-abc1")
        XCTAssertEqual(result.tokens.map(\.kind), [.identifier])
        XCTAssertEqual(result.identifiers, ["-abc1"])

        result = try Tokenizer.tokenize("_ab-1c, _ab-1c; _ab-1c")
        XCTAssertEqual(result.tokens.map(\.kind), [.identifier, .terminal(.comma), .identifier, .terminal(.semicolon), .identifier])
        XCTAssertEqual(result.identifiers, ["_ab-1c", "_ab-1c", "_ab-1c"])
    }

    func test_comments() throws {

        let result = try Tokenizer.tokenize("""
        // SingleLine
        /*
        MultiLine
        **/
        """)

        XCTAssertEqual(
            result.tokens,
            [
                .init(
                    kind: .comment("SingleLine"),
                    range: .init(
                        start: .init(line: 1, column: 1, offset: 0, file: "<unknown>"),
                        end: .init(line: 1, column: 14, offset: 13, file: "<unknown>")
                    )
                ),
                .init(
                    kind: .multilineComment("\nMultiLine\n*"),
                    range: .init(
                        start: .init(line: 2, column: 1, offset: 14, file: "<unknown>"),
                        end: .init(line: 4, column: 3, offset: 29, file: "<unknown>")
                    )
                )
            ]
        )
    }
}
