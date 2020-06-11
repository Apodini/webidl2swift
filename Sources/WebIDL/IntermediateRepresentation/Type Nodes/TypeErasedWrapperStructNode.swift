//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class TypeErasedWrapperStructNode: TypeNode, Equatable {

    let wrapped: NodePointer

    internal init(wrapped: NodePointer) {
        self.wrapped = wrapped
    }

    var swiftTypeName: String {

        "Any\(wrapped.identifier)"
    }

    var swiftDeclaration: String {

        let context = MemberNodeContext.classContext(swiftTypeName)
        // swiftlint:disable force_cast
        let protocolNode = unwrapNode(wrapped) as! ProtocolNode
        let members = protocolNode.requiredMembers

        let (namedSubscript, indexedSubscript) = SubscriptNode.mergedSubscriptNodes(members.filter { $0.isSubscript } as! [SubscriptNode])
        // swiftlint:enable force_cast

        var declaration = """
        class \(swiftTypeName): JSBridgedType, \(unwrapNode(wrapped).swiftTypeName) {

            let objectRef: JSObjectRef

            required init(objectRef: JSObjectRef) {
                self.objectRef = objectRef
            }

        """

        declaration += "\n"
        namedSubscript.map { declaration += $0.swiftImplementations(inContext: context).joined(separator: "\n\n") }
        declaration += "\n"
        indexedSubscript.map { declaration += $0.swiftImplementations(inContext: context).joined(separator: "\n\n") }
        declaration += "\n"

        declaration += members
            .filter { !$0.isSubscript }
            .flatMap { $0.swiftImplementations(inContext: context) }
            .joined(separator: "\n\n")

        declaration += "\n}"

        return declaration
    }
    
    static func == (lhs: TypeErasedWrapperStructNode, rhs: TypeErasedWrapperStructNode) -> Bool {
        lhs.wrapped == rhs.wrapped
    }
}
