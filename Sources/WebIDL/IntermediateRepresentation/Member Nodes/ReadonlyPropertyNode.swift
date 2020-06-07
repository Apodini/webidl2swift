
import Foundation

class ReadonlyPropertyNode: PropertyNode, Equatable {

    let name: String
    let dataType: NodePointer
    let isStatic: Bool

    internal init(name: String, dataType: NodePointer, isStatic: Bool) {
        self.name = name
        self.dataType = dataType
        self.isStatic = isStatic
    }

    func initializationStatement(forContext context: MemberNodeContext) -> String? {
        guard case .classContext = context, !dataType.node!.isProtocol, !isStatic else {
            return nil
        }

        return """
        _\(name) = ReadonlyAttribute(objectRef: objectRef, name: "\(name)")
        """
    }

    private func _swiftDeclarations(inContext: MemberNodeContext) -> String {
                let declaration: String

        let dataTypeNode = dataType.node!

        switch (inContext, isStatic) {
        case (.classContext, false) where dataTypeNode.isProtocol:
            declaration = "public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"

        case (.classContext, false):
            declaration = """
            @ReadonlyAttribute
            public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)
            """

        case (.classContext, true) where dataTypeNode.isProtocol:
            declaration = "public static var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"

        case (.classContext, true):
            declaration = """
            @ReadonlyAttribute(objectRef: Self.classRef, name: "\(name)")
            public static var \(escapedName(name)): \(dataTypeNode.swiftTypeName)
            """

        case (.protocolContext, _):
            declaration = "var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"
        case (.extensionContext, _):
            declaration = "var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"
        case (.structContext, _):
            declaration = "var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"

        case (.namespaceContext, _):
            declaration = "public static var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"
        }

        return declaration
    }

    func swiftDeclarations(inContext: MemberNodeContext) -> [String] {

        return [_swiftDeclarations(inContext: inContext)]
    }

    func swiftImplementations(inContext: MemberNodeContext) -> [String] {
               let dataTypeNode = dataType.node!
        switch inContext {
        case .classContext where dataTypeNode.isProtocol,
             .protocolContext where dataTypeNode.isProtocol,
             .extensionContext where dataTypeNode.isProtocol,
             .structContext where dataTypeNode.isProtocol:
            return [
                _swiftDeclarations(inContext: inContext) + """
                 {
                    get {
                        return objectRef.\(name).fromJSValue() as \(dataTypeNode.typeErasedSwiftType)
                    }
                }
                """
        ]

        case .classContext:
            return [_swiftDeclarations(inContext: inContext)]



        case .protocolContext, .extensionContext, .structContext, .namespaceContext:
            return [
                _swiftDeclarations(inContext: inContext) + """
                 {
                    get {
                        return objectRef.\(name).fromJSValue()
                    }
                }
                """
            ]
        }
    }

    static func == (lhs: ReadonlyPropertyNode, rhs: ReadonlyPropertyNode) -> Bool {
        return lhs.name == rhs.name && lhs.dataType == rhs.dataType
    }
}
