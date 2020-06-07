
import XCTest
@testable import WebIDL

final class ParserTests: XCTestCase {

    func test_parseExtendedAttributes() throws {

        let result = try Tokenizer.tokenize("""
        [A]
        interface A {};

        [A=B]
        interface B {};

        [C(A a, B b)]
        interface C {};

        [D=C(A a, B b)]
        interface D {};

        [E=(A,B,C,D)]
        interface E {};
        """)
        let parser = Parser(input: result)
        let definitions = try parser.parse()

        let cArguments: [Argument] = [
            Argument(rest: .nonOptional(.single(.distinguishableType(.identifier("A", false))), false, .identifier("a")), extendedAttributeList: []),
            Argument(rest: .nonOptional(.single(.distinguishableType(.identifier("B", false))), false, .identifier("b")), extendedAttributeList: []),
        ]

        XCTAssertEqual(definitions as! [Interface], [
            Interface(identifier: "A", extendedAttributeList: [.single("A")], inheritance: nil, members: []),
            Interface(identifier: "B", extendedAttributeList: [.identifier("A", "B")], inheritance: nil, members: []),
            Interface(identifier: "C", extendedAttributeList: [.argumentList("C", cArguments)], inheritance: nil, members: []),
            Interface(identifier: "D", extendedAttributeList: [.namedArgumentList("D", "C", cArguments)], inheritance: nil, members: []),
            Interface(identifier: "E", extendedAttributeList: [.identifierList("E", ["A", "B", "C", "D"])], inheritance: nil, members: []),
        ])
    }

    func test_parseInterface() throws {

        let result = try Tokenizer.tokenize("""
        [Exposed=Window]
        interface A {
            constructor();

            const float a = 42.0;
            const unrestricted double b = 42.23;
        };

        [Exposed=Window]
        interface B: A {};
        """)
        let parser = Parser(input: result)
        let definitions = try parser.parse()

        XCTAssertEqual(definitions as! [Interface], [
            Interface(identifier: "A", extendedAttributeList: [.identifier("Exposed", "Window")], inheritance: nil, members: [
                .constructor([], []),
                .const(.init(identifier: "a", constType: .primitiveType(.UnrestrictedFloatType(.restricted(.float))), constValue: .floatLiteral(.decimal(42))), []),
                .const(.init(identifier: "b", constType: .primitiveType(.UnrestrictedFloatType(.unrestricted(.double))), constValue: .floatLiteral(.decimal(42.23))), []),
            ]),
            Interface(identifier: "B", extendedAttributeList: [.identifier("Exposed", "Window")], inheritance: .init(identifier: "A"), members: [])
        ])
    }

    func test_parseNamespace() throws {

        let result = try Tokenizer.tokenize("""
        [Exposed=Window]
        namespace A {

        };
        """)
        let parser = Parser(input: result)
        let definitions = try parser.parse()

        XCTAssertEqual(definitions as! [Namespace], [
            Namespace(identifier: "A", extendedAttributeList: [.identifier("Exposed", "Window")], namespaceMembers: [])
        ])
    }

    func test_parseDictionary() throws {

        let result = try Tokenizer.tokenize("""
        dictionary A {
            required DOMString a;
        };
        dictionary B: A {
            long long b = 42;
        };
        """)
        let parser = Parser(input: result)
        let definitions = try parser.parse()

        let domStringType: DataType = .single(.distinguishableType(.string(.DOMString, false)))
        let longlongType: DataType = .single(.distinguishableType(.primitive(.UnsignedIntegerType(.signed(.longLong)), false)))

        XCTAssertEqual(definitions as! [Dictionary], [
            Dictionary(identifier: "A", extendedAttributeList: [], inheritance: nil, members: [
                .init(identifier: "a", isRequired: true, extendedAttributeList: [], dataType: domStringType, extendedAttributesOfDataType: [], defaultValue: nil)]),
            Dictionary(identifier: "B", extendedAttributeList: [], inheritance: .init(identifier: "A"), members: [
                .init(identifier: "b", isRequired: false, extendedAttributeList: [], dataType: longlongType, extendedAttributesOfDataType: nil, defaultValue: .constValue(.integer(42)))
            ]),
        ])
    }

    func test_parseEnumeration() throws {

        let result = try Tokenizer.tokenize("""
        enum A {
            "a", "b", "c"
        };
        """)
        let parser = Parser(input: result)
        let definitions = try parser.parse()

        XCTAssertEqual(definitions as! [Enum], [
            Enum(identifier: "A", extendedAttributeList: [], enumValues: [.init(string: "a"), .init(string: "b"), .init(string: "c")])
        ])
    }

    func test_parseTypedef() throws {

        let result = try Tokenizer.tokenize("""
        typedef (DOMString or ByteString or USVString) String;
        """)
        let parser = Parser(input: result)
        let definitions = try parser.parse()

        let unionTypes: [UnionMemberType] = [
            .distinguishableType([], .string(.DOMString, false)),
            .distinguishableType([], .string(.ByteString, false)),
            .distinguishableType([], .string(.USVString, false)),
        ]

        XCTAssertEqual(definitions as! [Typedef], [
            Typedef(identifier: "String", dataType: .union(unionTypes, false), extendedAttributeList: [])
        ])
    }

    func test_parseMixin() throws {

        let result = try Tokenizer.tokenize("""
        interface mixin B {};
        A includes B;
        """)
        let parser = Parser(input: result)
        let definitions = try parser.parse()

        XCTAssertEqual(definitions[0] as! Mixin, Mixin(identifier: "B", extendedAttributeList: [], members: []))
        XCTAssertEqual(definitions[1] as! IncludesStatement, IncludesStatement(child: "A", parent: "B", extendedAttributeList: []))
    }

    func test_parseCallbackInterface() throws {

        let result = try Tokenizer.tokenize("""
        callback interface A {
            void handle();
        };
        """)
        let parser = Parser(input: result)
        let definitions = try parser.parse()

        XCTAssertEqual(definitions as! [CallbackInterface], [
            CallbackInterface(identifer: "A", extendedAttributeList: [], callbackInterfaceMembers: [
                .regularOperation(.init(returnType: .void, operationName: .identifier("handle"), argumentList: []), [])
            ])
        ])
    }

    func test_parseCallbackFunction() throws {

        let result = try Tokenizer.tokenize("""
        callback CallbackHandler = void ();
        """)
        let parser = Parser(input: result)
        let definitions = try parser.parse()

        XCTAssertEqual(definitions as! [Callback], [
            Callback(identifier: "CallbackHandler", extendedAttributeList: [], returnType: .void, argumentList: [])
        ])
    }
}
