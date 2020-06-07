
import Foundation

class EnumerationWithRawValueNode: TypeNode, Equatable {

    let typeName: String
    let cases: [String]

    internal init(typeName: String, cases: [String]) {
        self.typeName = typeName
        self.cases = cases
    }

    var isEnum: Bool {
        return true
    }

    var swiftTypeName: String {
        return typeName
    }

    var swiftDeclaration: String {

        let casesAndRawValues: [(String, String)] = cases.map({ c in

            guard !c.isEmpty else {
                return ("empty", c)
            }

            return (String(c.first!.lowercased() + c.dropFirst()), c)
        })

        var declaration = """
        public enum \(typeName): String, JSValueCodable {

            public static func canDecode(from jsValue: JSValue) -> Bool {
                return jsValue.isString
            }

        """

        declaration += casesAndRawValues.map({ "case \($0.0) = \"\($0.1)\"" }).joined(separator: "\n")
        declaration += """


            public init(jsValue: JSValue) {

                guard let value = \(typeName)(rawValue: jsValue.fromJSValue()) else {
                    fatalError()
                }
                self = value
            }

            public func jsValue() -> JSValue {
                return rawValue.jsValue()
            }
        }
        """

        return declaration
    }

    static func == (lhs: EnumerationWithRawValueNode, rhs: EnumerationWithRawValueNode) -> Bool {
        return lhs.cases == rhs.cases
    }

    func typeCheck(withArgument argument: String) -> String {

        return "case .string(let string) = \(argument), \(cases).contains(string)"
    }
}
