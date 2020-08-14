//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class EnumerationWithRawValueNode: TypeNode, Equatable {

    let typeName: String
    let cases: [String]

    internal init(typeName: String, cases: [String]) {
        self.typeName = typeName
        self.cases = cases
    }

    var isEnum: Bool {
        true
    }

    var swiftTypeName: String {
        typeName
    }

    var swiftDeclaration: String {

        let casesAndRawValues: [(String, String)] = cases.map { theCase in

            guard !theCase.isEmpty else {
                return ("empty", theCase)
            }
            
            // swiftlint:disable:next force_unwrapping
            return (String(theCase.first!.lowercased() + theCase.dropFirst()), theCase)
        }

        var declaration = """
        public enum \(typeName): String, JSValueCodable {

            public static func construct(from jsValue: JSValue) -> \(typeName)? {
                if let string = jsValue.string,
                   let value = \(typeName)(rawValue: string) {
                    return value
                }
                return nil
            }

        """

        declaration += casesAndRawValues.map { "case \($0.0) = \"\($0.1)\"" }.joined(separator: "\n")
        declaration += """

            public func jsValue() -> JSValue {
                return rawValue.jsValue()
            }
        }
        """

        return declaration
    }

    static func == (lhs: EnumerationWithRawValueNode, rhs: EnumerationWithRawValueNode) -> Bool {
        lhs.cases == rhs.cases
    }

    func typeCheck(withArgument argument: String) -> String {

        "case .string(let string) = \(argument), \(cases).contains(string)"
    }
}
