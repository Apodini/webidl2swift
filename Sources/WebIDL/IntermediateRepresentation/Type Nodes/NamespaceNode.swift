//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class NamespaceNode: TypeNode, Equatable {

    let typeName: String

    var members: [MemberNode]

    internal init(typeName: String, members: [MemberNode]) {
        self.typeName = typeName
        self.members = members
    }

    var swiftTypeName: String {

        typeName
    }

    var isNamespace: Bool {
        true
    }

    var swiftDeclaration: String {

        let context = MemberNodeContext.namespaceContext(typeName)

        var declaration = """
        public enum \(typeName) {

            public static var objectRef: JSObjectRef {
                return JSObjectRef.global.\(typeName).object!
            }
        """

        declaration += members
            .flatMap {
                $0.swiftImplementations(inContext: context)
            }
            .joined(separator: "\n\n")

        declaration += "\n}"

        return declaration
    }

    static func == (lhs: NamespaceNode, rhs: NamespaceNode) -> Bool {
        lhs.typeName == rhs.typeName
    }

    func typeCheck(withArgument argument: String) -> String {
        "false"
    }
}
