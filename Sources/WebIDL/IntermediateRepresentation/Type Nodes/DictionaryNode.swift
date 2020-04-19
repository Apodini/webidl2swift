//
//  Created by Manuel Burghard on 19.04.20.
//

import Foundation

class DictionaryNode: TypeNode, Equatable {

    let typeName: String
    var inheritsFrom: NodePointer?
    var members: [String]

    internal init(typeName: String, inheritsFrom: NodePointer?, members: [String]) {
        self.typeName = typeName
        self.inheritsFrom = inheritsFrom
        self.members = members
    }

    var isDictionary: Bool {
        return true
    }

    var swiftTypeName: String {
        return typeName
    }

    var cases: [String] {

        if let baseNode = inheritsFrom?.node {
            guard let baseDictionaryNode = baseNode as? DictionaryNode else {
                fatalError("Expected Dictionary as base of other Dictionary")
            }

            struct Orderer<Element: Hashable>: Hashable {

                static func == (lhs: Orderer<Element>, rhs: Orderer<Element>) -> Bool {
                    return lhs.value == rhs.value
                }

                let value: Element
                let index: Int

                func hash(into hasher: inout Hasher) {
                    hasher.combine(value)
                }
            }
            var counter = 0
            var orderedSet = Set<Orderer<String>>(baseDictionaryNode.cases.map({ let r = Orderer(value: $0, index: counter); counter += 1; return r}))
            orderedSet.formUnion(members.map({ let r = Orderer(value: $0, index: counter); counter += 1; return r}))

            return orderedSet.sorted(by: { $0.index < $1.index }).map({ $0.value })
        } else {
            return members
        }
    }

    var swiftDeclaration: String {

        let cases = self.cases

        return """
        public struct \(swiftTypeName): ExpressibleByDictionaryLiteral, JSValueEncodable, JSValueDecodable {

            public enum Key: String, Hashable {

                case \(cases.map(escapedName).joined(separator: ", "))
            }

            public typealias Value = AnyJSValueConvertible

            private let dictionary: [String : AnyJSValueConvertible]

            public init(uniqueKeysWithValues elements: [(Key, Value)]) {
                self.dictionary = Dictionary(uniqueKeysWithValues: elements.map({ ($0.0.rawValue, $0.1) }))
            }

            public init(dictionaryLiteral elements: (Key, AnyJSValueConvertible)...) {
                self.dictionary = Dictionary(uniqueKeysWithValues: elements.map({ ($0.0.rawValue, $0.1) }))
            }

            subscript(_ key: Key) -> AnyJSValueConvertible? {
                dictionary[key.rawValue]
            }

            public init(jsValue: JSValue) {

                self.dictionary = jsValue.fromJSValue()
            }

            public func jsValue() -> JSValue {
                return dictionary.jsValue()
            }
        }
        """
    }

    static func == (lhs: DictionaryNode, rhs: DictionaryNode) -> Bool {
        return lhs.typeName == rhs.typeName
    }
}
