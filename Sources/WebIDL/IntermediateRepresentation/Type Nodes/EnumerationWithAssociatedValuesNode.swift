//
//  Created by Manuel Burghard. Licensed unter MIT.
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
        true
    }

    var swiftTypeName: String {
        typeName
    }

    var swiftDeclaration: String {

        var protocolConfromances = Set<String>()

        var protocolImplementations = [String]()
        var caseNames = [String]()

        var numberOfAssociateValuesOfArrayType = 0
        var numberOfAssociateValueOfDictionaryType = 0
        var numberOfAssociateValueOfStringType = 0
        var numberOfAssociateValueOfBoolType = 0
        for theCase in cases {
            let node = unwrapNode(theCase)
            if node.isArray {
                numberOfAssociateValuesOfArrayType += 1
            } else if node.isDictionary || node.isRecord {
                numberOfAssociateValueOfDictionaryType += 1
            } else if theCase.identifier == "String" {
                numberOfAssociateValueOfStringType += 1
            } else if theCase.identifier == "Bool" {
                numberOfAssociateValueOfBoolType += 1
            }
        }

        for theCase in cases {

            // swiftlint:disable:next force_unwrapping
            let caseName = String(theCase.identifier.first!.lowercased() + theCase.identifier.dropFirst())
            caseNames.append(caseName)

            let node = unwrapNode(theCase)

            if numberOfAssociateValuesOfArrayType == 1, node.isArray {

                protocolConfromances.insert("ExpressibleByArrayLiteral")
                // swiftlint:disable force_unwrapping
                protocolImplementations.append("""
                    public init(arrayLiteral elements: \(node.arrayElementSwiftTypeName!)...) {
                    self = .\(caseName)(elements)
                }
                """)
                // swiftlint:enable force_unwrapping
            } else if numberOfAssociateValueOfDictionaryType == 1, node.isDictionary {
                protocolConfromances.insert("ExpressibleByDictionaryLiteral")
                protocolImplementations.append("""
                public init(dictionaryLiteral elements: (\(theCase.identifier).Key, \(theCase.identifier).Value)...) {
                    self = .\(caseName)(.init(uniqueKeysWithValues: elements))
                }
                """)
            } else if numberOfAssociateValueOfDictionaryType == 1, node.isRecord {
                protocolConfromances.insert("ExpressibleByDictionaryLiteral")
                protocolImplementations.append("""
                public init(dictionaryLiteral elements: (String, \(theCase.identifier).Value)...) {
                    self = .\(caseName)(.init(uniqueKeysWithValues: elements))
                }
                """)
            } else if numberOfAssociateValueOfStringType == 1, theCase.identifier == "String" {
                protocolConfromances.insert("ExpressibleByStringLiteral")
                protocolImplementations.append("""
                public init(stringLiteral value: String) {
                    self = .\(caseName)(value)
                }
                """)
            } else if numberOfAssociateValueOfBoolType == 1, theCase.identifier == "Bool" {
                protocolConfromances.insert("ExpressibleByBooleanLiteral")
                protocolImplementations.append("""
                public init(booleanLiteral value: Bool) {
                    self = .\(caseName)(value)
                }
                """)
            }
        }

        let inheritance = ["JSValueEncodable", "JSValueDecodable"] + protocolConfromances.sorted()

        var declaration = """
            public enum \(typeName): \(inheritance.joined(separator: ", ")) {

                public static func canDecode(from jsValue: JSValue) -> Bool {
                    return \(cases.map { "\(unwrapNode($0).swiftTypeName).canDecode(from: jsValue)" }.joined(separator: " || "))
                }

            
            """

        var initMap = [String]()
        declaration += zip(caseNames, cases)
            .map {
                let (caseName, nodePointer) = $0
                let typeName = unwrapNode(nodePointer).swiftTypeName

                initMap.append("""
                    if \(typeName).canDecode(from: jsValue) {
                        self = .\(caseName)(jsValue.fromJSValue())
                    }
                    """)

                return "case \(caseName)(\(typeName))"
            }
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
            \(caseNames.map { "case .\($0)(let v): return v.jsValue()" }.joined(separator: "\n"))
            }
        }
        """

        declaration += "\n}"

        return declaration
    }

    static func == (lhs: EnumerationWithAssociatedValuesNode, rhs: EnumerationWithAssociatedValuesNode) -> Bool {
        lhs.cases == rhs.cases
    }
}
