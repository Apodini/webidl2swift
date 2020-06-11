//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

public protocol TypeNode: AnyObject {

    var isOptional: Bool { get }
    var isClosure: Bool { get }

    var isArray: Bool { get }
    var isDictionary: Bool { get }
    var isEnum: Bool { get }
    var isProtocol: Bool { get }
    var isClass: Bool { get }
    var isNamespace: Bool { get }

    var isRecord: Bool { get }

    var nonOptionalTypeName: String { get }

    var swiftTypeName: String { get }
    var swiftDeclaration: String { get }

    var typeErasedSwiftType: String { get }

    var numberOfClosureArguments: Int { get }

    var arrayElementSwiftTypeName: String? { get }
}

extension TypeNode {

    var isOptional: Bool { false }

    var isClosure: Bool { false }

    var isArray: Bool { false }

    var isDictionary: Bool { false }

    var isEnum: Bool { false }

    var isProtocol: Bool { false }
    var isClass: Bool { false }

    var isNamespace: Bool { false }

    var isRecord: Bool { false }

    var nonOptionalTypeName: String { swiftTypeName }

    var typeErasedSwiftType: String { swiftTypeName }

    var numberOfClosureArguments: Int { 0 }

    var arrayElementSwiftTypeName: String? { nil }
}

// swiftlint:disable cyclomatic_complexity
func equal(_ lhs: TypeNode, _ rhs: TypeNode) -> Bool {

    if let lhs = lhs as? ArrayNode, let rhs = rhs as? ArrayNode {
        return lhs == rhs
    } else if let lhs = lhs as? OptionalNode, let rhs = rhs as? OptionalNode {
        return lhs == rhs
    } else if let lhs = lhs as? DictionaryNode, let rhs = rhs as? DictionaryNode {
        return lhs == rhs
    } else if let lhs = lhs as? ClosureNode, let rhs = rhs as? ClosureNode {
        return lhs == rhs
    } else if let lhs = lhs as? AliasNode, let rhs = rhs as? AliasNode {
        return lhs == rhs
    } else if let lhs = lhs as? EnumerationWithRawValueNode, let rhs = rhs as? EnumerationWithRawValueNode {
        return lhs == rhs
    } else if let lhs = lhs as? BasicTypeNode, let rhs = rhs as? BasicTypeNode {
            return lhs == rhs
    } else if let lhs = lhs as? BasicArrayTypeNode, let rhs = rhs as? BasicArrayTypeNode {
            return lhs == rhs
    } else if let lhs = lhs as? EnumerationWithAssociatedValuesNode, let rhs = rhs as? EnumerationWithAssociatedValuesNode {
        return lhs == rhs
    } else if let lhs = lhs as? ClassNode, let rhs = rhs as? ClassNode {
        return lhs == rhs
    } else if let lhs = lhs as? NamespaceNode, let rhs = rhs as? NamespaceNode {
        return lhs == rhs
    } else if let lhs = lhs as? ProtocolNode, let rhs = rhs as? ProtocolNode {
        return lhs == rhs
    } else if let lhs = lhs as? TypeErasedWrapperStructNode, let rhs = rhs as? TypeErasedWrapperStructNode {
        return lhs == rhs
    } else if let lhs = lhs as? RecordNode, let rhs = rhs as? RecordNode {
        return lhs == rhs
    } else {
        return false
    }
}
// swiftlint:enable cyclomatic_complexity
