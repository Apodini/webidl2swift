//
//  Created by Manuel Burghard on 19.04.20.
//

import Foundation

class EnumerationWithAssociatedValuesNode: TypeNode, Equatable {

    let typeName: String
    let cases: [NodePointer]

    internal init(typeName: String, cases: [NodePointer]) {
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

        var protocolConfromances = Set<String>()

        var protocolImplementations = [String]()
        var caseNames = [String]()

        var numberOfAssociateValuesOfArrayType = 0
        var numberOfAssociateValueOfDictionaryType = 0
        var numberOfAssociateValueOfStringType = 0
        var numberOfAssociateValueOfBoolType = 0
        for c in cases {
            let node = c.node!
            if node.isArray { numberOfAssociateValuesOfArrayType += 1}
            else if node.isDictionary || node.isRecord { numberOfAssociateValueOfDictionaryType += 1}
            else if c.identifier == "String" { numberOfAssociateValueOfStringType += 1}
            else if c.identifier == "Bool" { numberOfAssociateValueOfBoolType += 1}
        }

        for c in cases {

            let caseName = String(c.identifier.first!.lowercased() + c.identifier.dropFirst())
            caseNames.append(caseName)

            let node = c.node!

            if numberOfAssociateValuesOfArrayType == 1, node.isArray {
                protocolConfromances.insert("ExpressibleByArrayLiteral")
                protocolImplementations.append("""
                    public init(arrayLiteral elements: \(c.identifier).Element...) {
                    self = .\(caseName)(elements)
                }
                """)
            } else if numberOfAssociateValueOfDictionaryType == 1, node.isDictionary {
                protocolConfromances.insert("ExpressibleByDictionaryLiteral")
                protocolImplementations.append("""
                public init(dictionaryLiteral elements: (\(c.identifier).Key, \(c.identifier).Value)...) {
                    self = .\(caseName)(.init(uniqueKeysWithValues: elements))
                }
                """)

            } else if numberOfAssociateValueOfDictionaryType == 1, node.isRecord {
                protocolConfromances.insert("ExpressibleByDictionaryLiteral")
                protocolImplementations.append("""
                public init(dictionaryLiteral elements: (String, \(c.identifier).Value)...) {
                    self = .\(caseName)(.init(uniqueKeysWithValues: elements))
                }
                """)

            } else if numberOfAssociateValueOfStringType == 1, c.identifier == "String" {
                protocolConfromances.insert("ExpressibleByStringLiteral")
                protocolImplementations.append("""
                public init(stringLiteral value: String) {
                    self = .\(caseName)(value)
                }
                """)
            } else if numberOfAssociateValueOfBoolType == 1, c.identifier == "Bool" {
                protocolConfromances.insert("ExpressibleByBooleanLiteral")
                protocolImplementations.append("""
                public init(booleanLiteral value: Bool) {
                    self = .\(caseName)(value)
                }
                """)
            }
        }

        let inheritance = ["JSValueEncodable", "JSValueDecodable"] + protocolConfromances.sorted()

        var declaration = "public enum \(typeName): \(inheritance.joined(separator: ", "))"
        declaration += " {\n"

        var initMap = [String]()
        declaration += zip(caseNames, cases)
            .map({

            let (caseName, nodePointer) = $0

            initMap.append("""
            if jsValue.instanceOf("\(nodePointer.identifier)") {
                self = .\(caseName)(jsValue.fromJSValue())
            }
            """)

            return "case \(caseName)(\(nodePointer.identifier))"
            })
            .joined(separator: "\n")

        initMap.append("""
            {
                fatalError()
            }
            """)

        declaration += """


        public init(jsValue: JSValue) {

        """
        declaration += initMap.joined(separator: " else ")
        declaration += "\n}"

        declaration += "\n\n"
        declaration += protocolImplementations.joined(separator: "\n\n")
        declaration += "\n\n"

        declaration += """
        public func jsValue() -> JSValue {

            switch self {
            \(caseNames.map({ "case .\($0)(let v): return v.jsValue()" }).joined(separator: "\n"))
            }
        }
        """

        declaration += "\n}"

        return declaration
    }

    static func == (lhs: EnumerationWithAssociatedValuesNode, rhs: EnumerationWithAssociatedValuesNode) -> Bool {
        return lhs.cases == rhs.cases
    }
}
