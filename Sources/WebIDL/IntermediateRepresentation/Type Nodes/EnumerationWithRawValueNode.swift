
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

        var declaration = "public enum \(typeName): String, JSValueEncodable, JSValueDecodable"
        declaration += " {\n"
        declaration += casesAndRawValues.map({ "case \($0.0) = \"\($0.1)\"" }).joined(separator: "\n")
        declaration += """


            public init(jsValue: JSValue) {

                switch jsValue.fromJSValue() as String {
                \(casesAndRawValues.map({ "case \"\($0.1)\":\nself = .\($0.0)"}).joined(separator: "\n"))
                default:
                    fatalError()
                }
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
}
