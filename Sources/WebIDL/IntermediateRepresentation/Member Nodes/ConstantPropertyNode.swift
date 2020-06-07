
import Foundation

class ConstantPropertyNode: PropertyNode, Equatable {

    let name: String
    let dataType: NodePointer
    let value: String

    internal init(name: String, dataType: NodePointer, value: String) {
        self.name = name
        self.dataType = dataType
        self.value = value
    }

    func initializationStatement(forContext context: MemberNodeContext) -> String? {
        return nil
    }

    private func _swiftDeclarations(inContext: MemberNodeContext) -> String {

        switch inContext {
        case .classContext:
            return "public let \(escapedName(name)): \(dataType.node!.swiftTypeName)"

        case .protocolContext, .extensionContext, .structContext:
            return "var \(escapedName(name)): \(dataType.node!.swiftTypeName)"

        case .namespaceContext:
            fatalError("Not supported by Web IDL standard!")
        }
    }

    func swiftDeclarations(inContext: MemberNodeContext) -> [String] {

        return [_swiftDeclarations(inContext: inContext)]
    }

    func swiftImplementations(inContext: MemberNodeContext) -> [String] {

        switch inContext {
        case .classContext:
            return ["\(_swiftDeclarations(inContext: inContext)) = \(value)"]

        case .protocolContext, .extensionContext, .structContext:
            return ["\(_swiftDeclarations(inContext: inContext)) {\nreturn \(value)\n}"]

        case .namespaceContext:
            fatalError("Not supported by Web IDL standard!")
        }
    }

    static func == (lhs: ConstantPropertyNode, rhs: ConstantPropertyNode) -> Bool {
        return lhs.name == rhs.name && lhs.value == rhs.value && lhs.dataType == rhs.dataType
    }
}
