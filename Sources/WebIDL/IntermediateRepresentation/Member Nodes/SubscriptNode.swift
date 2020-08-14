//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class SubscriptNode: MemberNode, Equatable {

    struct Kind: OptionSet {

        let rawValue: Int

        static let getter = Kind(rawValue: 1 << 0)
        static let setter = Kind(rawValue: 1 << 1)
        static let deleter = Kind(rawValue: 1 << 2)
    }

    let returnType: NodePointer
    var kind: Kind
    let nameParameter: ParameterNode
    var valueParameter: ParameterNode?

    internal init(returnType: NodePointer, kind: Kind, nameParameter: ParameterNode, valueParameter: ParameterNode?) {
        self.returnType = returnType
        self.kind = kind
        self.nameParameter = nameParameter
        self.valueParameter = valueParameter
    }

    var isSubscript: Bool {
        true
    }

    var isIndexed: Bool {

        nameParameter.dataType.identifier == "UInt64"
    }

    var isNamed: Bool {

        nameParameter.dataType.identifier == "String"
    }

    var isGetter: Bool {
        kind.contains(.getter)
    }

    var isSetter: Bool {
        kind.contains(.setter)
    }

    var isDeleter: Bool {
        kind.contains(.deleter)
    }

    // swiftlint:disable function_body_length
    private func _swiftDeclaration(inContext: MemberNodeContext, withImplementation: Bool) -> [String] {

        var declaration: String
        if case .classContext = inContext {
            declaration = "public subscript"
        } else {
            declaration = "subscript"
        }
        let returnTypeNode = unwrapNode(returnType)

        declaration += "(\(nameParameter.label): \(unwrapNode(nameParameter.dataType).swiftTypeName)) -> \(returnTypeNode.swiftTypeName)?"

        if withImplementation {
            let lookup: String
            declaration += " {\n"
            if isNamed {
                lookup = "objectRef.\(escapedName(nameParameter.label))"
            } else {
                lookup = "objectRef[\(nameParameter.label)]"
            }

            if returnTypeNode.isProtocol {
                declaration += """
                get {
                    return \(lookup).fromJSValue()! as \(returnTypeNode.typeErasedSwiftType)
                }
                """
            } else {
                declaration += """
                get {
                    return \(lookup).fromJSValue()!
                }
                """
            }

            if isSetter && isDeleter {
                declaration += """
                
                set {
                    \(lookup) = newValue.jsValue()
                }
                """
            } else if isSetter {
                declaration += """

                set {
                    if let newValue = newValue  {
                        \(lookup) = newValue.jsValue()
                    }
                }
                """
            } else if isDeleter {
                declaration += """

                set {
                    \(lookup) = .null
                }
                """
            }

            declaration += "\n}"
        }

        return [declaration]
    }
    // swiftlint:enable function_body_length

    func swiftDeclarations(inContext: MemberNodeContext) -> [String] {

        _swiftDeclaration(inContext: inContext, withImplementation: false)
    }

    func swiftImplementations(inContext: MemberNodeContext) -> [String] {

        _swiftDeclaration(inContext: inContext, withImplementation: true)
    }

    static func == (lhs: SubscriptNode, rhs: SubscriptNode) -> Bool {
        lhs.returnType == rhs.returnType && lhs.kind == rhs.kind && lhs.nameParameter == rhs.nameParameter && lhs.valueParameter == rhs.valueParameter
    }

    static func mergedSubscriptNodes(_ subscriptMembers: [SubscriptNode]) -> (SubscriptNode?, SubscriptNode?) {

        let namedSubscript: SubscriptNode? = subscriptMembers.first(where: { $0.isGetter && $0.isNamed })
        let indexedSubscript: SubscriptNode? = subscriptMembers.first(where: { $0.isGetter && $0.isIndexed })

        for subscriptMember in subscriptMembers {
            // swiftlint:disable force_unwrapping
            switch subscriptMember.kind {
            case let value where value.contains(.setter) && subscriptMember.isNamed && subscriptMember.valueParameter?.dataType == namedSubscript!.returnType:
                namedSubscript!.kind.insert(.setter)
                namedSubscript!.valueParameter = subscriptMember.valueParameter

            case let value where value.contains(.deleter) && subscriptMember.isNamed:
                namedSubscript!.kind.insert(.deleter)

            case let value where value.contains(.setter) && subscriptMember.isIndexed && subscriptMember.valueParameter?.dataType == indexedSubscript!.returnType:
                indexedSubscript!.kind.insert(.setter)
                indexedSubscript!.valueParameter = subscriptMember.valueParameter

            case let value where value.contains(.deleter) && subscriptMember.isIndexed:
                indexedSubscript!.kind.insert(.deleter)

            default:
                continue
            }
            // swiftlint:enable force_unwrapping
        }

        return (namedSubscript, indexedSubscript)
    }
}
