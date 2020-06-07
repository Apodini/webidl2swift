
import Foundation

class NamespaceNode: TypeNode, Equatable {

    let typeName: String

    var members: [MemberNode]

    internal init(typeName: String, members: [MemberNode]) {
        self.typeName = typeName
        self.members = members
    }

    var swiftTypeName: String {

        return typeName
    }

    var isNamespace: Bool { true }

    var swiftDeclaration: String {

        let context = MemberNodeContext.namespaceContext(typeName)

        var declaration = """
        public enum \(typeName) {

            public static var objectRef: JSObjectRef {
                return JSObjectRef.global.\(typeName).object!
            }
        """

        declaration += members
            .flatMap({
                return $0.swiftImplementations(inContext: context)
            })
            .joined(separator: "\n\n")

        declaration += "\n}"

        return declaration
    }

    static func == (lhs: NamespaceNode, rhs: NamespaceNode) -> Bool {
        return lhs.typeName == rhs.typeName
    }

    func typeCheck(withArgument argument: String) -> String {
        return "false"
    }
}
