
import Foundation

let swiftKeyWords: [String : String] = [
    "init" : "`init`",
    "where" : "`where`",
    "protocol" : "`protocol`",
    "struct" : "`struct`",
    "class" : "`class`",
    "enum" : "`enum`",
    "func" : "`func`",
    "static" : "`static`",
    "is" : "`is`",
]

func escapedName(_ string: String ) -> String {
    return swiftKeyWords[string, default: string]
}

public class NodePointer: Hashable {

    public let identifier: String
    public var node: TypeNode?

    init(identifier: String, node: TypeNode?) {
        self.identifier = identifier
        self.node = node
    }

    public func hash(into hasher: inout Hasher) {
        identifier.hash(into: &hasher)
    }

    public static func ==(lhs: NodePointer, rhs: NodePointer) -> Bool {
        switch (lhs.node, rhs.node) {
        case (let lhsNode?, let rhsNode?) where equal(lhsNode, rhsNode):
            return lhs.identifier == rhs.identifier
        case (nil, nil):
            return lhs.identifier == rhs.identifier
        default:
            return false
        }
    }
}

public class IntermediateRepresentation: Collection {

    public typealias Index = Swift.Dictionary<String, NodePointer>.Index
    public typealias Element = Swift.Dictionary<String, NodePointer>.Element

    public func index(after i: Index) -> Index {

        nodes.index(after: i)
    }

    public var startIndex: Index {
        return nodes.startIndex
    }

    public var endIndex: Index {
        return nodes.endIndex
    }

    private var nodes = [String : NodePointer]()

    init() {}

    subscript(typeName: String) -> NodePointer? {
        return nodes[typeName]
    }

    public subscript(index: Index) -> Element {
        return nodes[index]
    }

    public var undefinedTypes: [Element]  {
        return filter {
            $0.value.node == nil
        }
    }

    private func existingOrNewNodePointer(for typeName: String) -> NodePointer {

        if let alreadyRegisterd = nodes[typeName] {
            return alreadyRegisterd
        } else {
            let nodePointer = NodePointer(identifier: typeName, node: nil)
            nodes[typeName] = nodePointer
            return nodePointer
        }
    }

    func registerIdentifier(withTypeName typeName: String) -> NodePointer {
        return existingOrNewNodePointer(for: typeName)
    }

    @discardableResult
    func registerBasicType(withTypeName typeName: String) -> NodePointer {

        let nodePointer = existingOrNewNodePointer(for: typeName)
        if let alreadyRegisterd = nodePointer.node {
            guard alreadyRegisterd is BasicTypeNode else {
                fatalError("Type mismatch for already registered Type!")
            }
        } else {
            nodePointer.node = BasicTypeNode(typeName: typeName)
        }

        return nodePointer
    }

    @discardableResult
    func registerBasicArrayType(withTypeName typeName: String, scalarType: String) -> NodePointer {

        let nodePointer = existingOrNewNodePointer(for: typeName)
        if let alreadyRegisterd = nodePointer.node {
            guard alreadyRegisterd is BasicArrayTypeNode else {
                fatalError("Type mismatch for already registered Type!")
            }
        } else {
            nodePointer.node = BasicArrayTypeNode(typeName: typeName, scalarType: scalarType)
        }

        return nodePointer
    }

    @discardableResult
    func registerArrayNode(withTypeName typeName: String, element: NodePointer) -> NodePointer {

        let nodePointer = existingOrNewNodePointer(for: typeName)
        if let alreadyRegisterd = nodePointer.node {
            guard let arrayNode = alreadyRegisterd as? ArrayNode, arrayNode.element == element else {
                fatalError("Type mismatch for already registered Type!")
            }
        } else {
            nodePointer.node = ArrayNode(element: element)
        }

        return nodePointer
    }


    func registerAliasNode(withTypeName typeName: String, aliasing: TypeNode) -> NodePointer {

        let nodePointer = existingOrNewNodePointer(for: typeName)
        if let alreadyRegisterd = nodePointer.node {
            guard let existingAliasNode = alreadyRegisterd as? AliasNode,
                equal(existingAliasNode.aliased, aliasing) else {
                fatalError("Type mismatch for already registered Type!")
            }
        } else {
            nodePointer.node = AliasNode(typeName: typeName, aliased: aliasing)
        }

        return nodePointer
    }

    func registerDictionaryNode(withTypeName typeName: String, inheritsFrom: NodePointer?, members: [String]) -> NodePointer {

        let nodePointer = existingOrNewNodePointer(for: typeName)
        if let alreadyRegisterd = nodePointer.node {
            guard let existingDictionaryNode = alreadyRegisterd as? DictionaryNode else {
                fatalError("Type mismatch for already registered Type!")
            }
            if existingDictionaryNode.inheritsFrom == nil {
                existingDictionaryNode.inheritsFrom = inheritsFrom
            } else {
                guard existingDictionaryNode.inheritsFrom == inheritsFrom else {
                    fatalError("Type mismatch for inheritsFrom property!")
                }
            }
            existingDictionaryNode.members += members
        } else {
            nodePointer.node = DictionaryNode(typeName: typeName, inheritsFrom: inheritsFrom, members: members)
        }

        return nodePointer
    }

    func registerOptional(for nonOptional: NodePointer) -> NodePointer {

        let typeName = "Optional\(nonOptional.identifier)"
//        return registerAliasNode(withTypeName: typeName, aliasing: OptionalNode(wrapped: nodePointer))

        let nodePointer = existingOrNewNodePointer(for: typeName)
        if let alreadyRegisterd = nodePointer.node {
            guard let optionalNode = alreadyRegisterd as? OptionalNode,
            optionalNode.wrapped == nonOptional else {
                fatalError("Type mismatch for already registered Type!")
            }
        } else {
            nodePointer.node = OptionalNode(wrapped: nonOptional)
        }

        return nodePointer
    }

    @discardableResult
    func registerEnumeration(withTypeName typeName: String, cases: [String]) -> NodePointer {

        let nodePointer = existingOrNewNodePointer(for: typeName)
        if let alreadyRegisterd = nodePointer.node {
            guard let existingEnumeration = alreadyRegisterd as? EnumerationWithRawValueNode,
                existingEnumeration.cases == cases else {
                    fatalError("Type mismatch for already registered Type!")
            }
        } else {
            nodePointer.node = EnumerationWithRawValueNode(typeName: typeName, cases: cases)
        }
        
        return nodePointer
    }

    @discardableResult
    func registerEnumerationWithAssociatedValues(withTypeName typeName: String, cases: [NodePointer]) -> NodePointer {

        let nodePointer = existingOrNewNodePointer(for: typeName)
        if let alreadyRegisterd = nodePointer.node {
            guard let existingEnumeration = alreadyRegisterd as? EnumerationWithAssociatedValuesNode,
                existingEnumeration.cases == cases else {
                    fatalError("Type mismatch for already registered Type!")
            }
        } else {
            nodePointer.node = EnumerationWithAssociatedValuesNode(typeName: typeName, cases: cases)
        }

        return nodePointer
    }

    @discardableResult
    func registerProtocol(withTypeName typeName: String, inheritsFrom: Set<NodePointer>, requiredMembers: [MemberNode], defaultImplementations: [MemberNode]) -> NodePointer {

        let nodePointer = existingOrNewNodePointer(for: typeName)
        let typeErasedPointer = existingOrNewNodePointer(for: "Any\(typeName)")
        if let alreadyRegisterd = nodePointer.node {
            guard let existingProtocolNode = alreadyRegisterd as? ProtocolNode else {
                    fatalError("Type mismatch for already registered Type!")
            }
            existingProtocolNode.inheritsFrom.formUnion(inheritsFrom)
            existingProtocolNode.requiredMembers.append(contentsOf: requiredMembers)
            existingProtocolNode.defaultImplementations.append(contentsOf: defaultImplementations)
        } else {
            nodePointer.node = ProtocolNode(typeName: typeName, inheritsFrom: inheritsFrom, requiredMembers: requiredMembers, defaultImplementations: defaultImplementations)
            typeErasedPointer.node = TypeErasedWrapperStructNode(wrapped: nodePointer)
        }

        return nodePointer
    }

    @discardableResult
    func registerClass(withTypeName typeName: String, inheritsFrom: Set<NodePointer>, members: [MemberNode]) -> NodePointer {

        let nodePointer = existingOrNewNodePointer(for: typeName)
        if let alreadyRegisterd = nodePointer.node {
            guard let existingClass = alreadyRegisterd as? ClassNode else {
                    fatalError("Type mismatch for already registered Type!")
            }
            existingClass.inheritsFrom.formUnion(inheritsFrom)
            existingClass.members.append(contentsOf: members)
        } else {
            nodePointer.node = ClassNode(typeName: typeName, inheritsFrom: inheritsFrom, members: members)
        }

        return nodePointer
    }

    @discardableResult
    func registerNamespace(withTypeName typeName: String, members: [MemberNode]) -> NodePointer {

        let nodePointer = existingOrNewNodePointer(for: typeName)
        if let alreadyRegisterd = nodePointer.node {
            guard let existingNamespace = alreadyRegisterd as? NamespaceNode else {
                    fatalError("Type mismatch for already registered Type!")
            }
            existingNamespace.members.append(contentsOf: members)
        } else {
            nodePointer.node = NamespaceNode(typeName: typeName, members: members)
        }

        return nodePointer
    }
}
