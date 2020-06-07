
import Foundation

public protocol TypeNode: class {

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

    var arrayElementSwiftTypeName: String? {get}
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

func equal(_ lhs: TypeNode, _ rhs: TypeNode) -> Bool {

    if let l = lhs as? ArrayNode, let r = rhs as? ArrayNode {
        return l == r
    } else if let l = lhs as? OptionalNode, let r = rhs as? OptionalNode {
        return l == r
    } else if let l = lhs as? DictionaryNode, let r = rhs as? DictionaryNode {
        return l == r
    } else if let l = lhs as? ClosureNode, let r = rhs as? ClosureNode {
        return l == r
    } else if let l = lhs as? AliasNode, let r = rhs as? AliasNode {
        return l == r
    } else if let l = lhs as? EnumerationWithRawValueNode, let r = rhs as? EnumerationWithRawValueNode {
        return l == r
    } else if let l = lhs as? BasicTypeNode, let r = rhs as? BasicTypeNode {
            return l == r
    } else if let l = lhs as? BasicArrayTypeNode, let r = rhs as? BasicArrayTypeNode {
            return l == r
    } else if let l = lhs as? EnumerationWithAssociatedValuesNode, let r = rhs as? EnumerationWithAssociatedValuesNode {
        return l == r
    } else if let l = lhs as? ClassNode, let r = rhs as? ClassNode {
        return l == r
    } else if let l = lhs as? NamespaceNode, let r = rhs as? NamespaceNode {
        return l == r
    } else if let l = lhs as? ProtocolNode, let r = rhs as? ProtocolNode {
        return l == r
    } else if let l = lhs as? TypeErasedWrapperStructNode, let r = rhs as? TypeErasedWrapperStructNode {
        return l == r
    } else if let l = lhs as? RecordNode, let r = rhs as? RecordNode {
        return l == r
    } else {
        return false
    }
}
