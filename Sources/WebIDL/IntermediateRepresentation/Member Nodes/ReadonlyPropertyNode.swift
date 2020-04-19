//
//  Created by Manuel Burghard on 19.04.20.
//

import Foundation

class ReadonlyPropertyNode: PropertyNode, Equatable {

    let name: String
    let dataType: NodePointer

    internal init(name: String, dataType: NodePointer) {
        self.name = name
        self.dataType = dataType
    }

    func initializationStatement(forContext context: MemberNodeContext) -> String? {
        guard context == .classContext, !dataType.node!.isProtocol else {
            return nil
        }

        return """
        _\(name) = ReadonlyAttribute(objectRef: objectRef, name: "\(name)")
        """
    }

    private func _swiftDeclarations(inContext: MemberNodeContext) -> String {
                let declaration: String

        let dataTypeNode = dataType.node!

        switch inContext {
        case .classContext where dataTypeNode.isProtocol:
            declaration = "public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"

        case .classContext:
            declaration = """
            @ReadonlyAttribute
            public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)
            """

        case .protocolContext:
            declaration = "var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"
        case .extensionContext:
            declaration = "var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"
        case .structContext:
            declaration = "var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"
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



        case .protocolContext, .extensionContext, .structContext:
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
