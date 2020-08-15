//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class ProtocolNode: TypeNode, Equatable {

    let typeName: String
    var inheritsFrom: Set<NodePointer>
    let kind: ProtocolKind

    var requiredMembers: [MemberNode]
    var defaultImplementations: [MemberNode]

    internal init(typeName: String, inheritsFrom: Set<NodePointer>, requiredMembers: [MemberNode], defaultImplementations: [MemberNode], kind: ProtocolKind) {
        self.typeName = typeName
        self.inheritsFrom = inheritsFrom
        self.requiredMembers = requiredMembers
        self.defaultImplementations = defaultImplementations
        self.kind = kind
    }

    var isProtocol: Bool {
        true
    }

    var swiftTypeName: String {

        typeName
    }

    var typeErasedSwiftType: String {
        "Any\(swiftTypeName)"
    }

    var swiftDeclaration: String {

        let context = MemberNodeContext.protocolContext(typeName)

        // swiftlint:disable force_cast
        let (namedSubscript, indexedSubscript) = SubscriptNode.mergedSubscriptNodes(requiredMembers.filter { $0.isSubscript } as! [SubscriptNode])
        // swiftlint:enable force_cast

        let primaryType: String
        switch kind {
        case .callback:
            primaryType = "JSBridgedType"
        case .mixin:
            primaryType = "JSBridgedClass"
        }

        let inheritsFrom = [primaryType] + self.inheritsFrom.map { unwrapNode($0).swiftTypeName }.sorted()
        var declaration =  """
        public protocol \(typeName): \(inheritsFrom.joined(separator: ", ")) {

        """

        declaration += "\n"
        namedSubscript.map { declaration += $0.swiftDeclarations(inContext: context).joined(separator: "\n\n") }
        declaration += "\n"
        indexedSubscript.map { declaration += $0.swiftDeclarations(inContext: context).joined(separator: "\n\n") }
        declaration += "\n"

        declaration += requiredMembers
            .filter { !$0.isSubscript }
            .flatMap { $0.swiftDeclarations(inContext: context) }
            .joined(separator: "\n\n")

        declaration += "\n}"

        if !defaultImplementations.isEmpty {

            // swiftlint:disable force_cast
            let (namedSubscript, indexedSubscript) = SubscriptNode.mergedSubscriptNodes(requiredMembers.filter { $0.isSubscript } as! [SubscriptNode])
            // swiftlint:enable force_cast
            
            declaration += """


            public extension \(typeName) {


            """

            declaration += "\n"
            namedSubscript.map { declaration += $0.swiftImplementations(inContext: context).joined(separator: "\n\n") }
            declaration += "\n"
            indexedSubscript.map { declaration += $0.swiftImplementations(inContext: context).joined(separator: "\n\n") }
            declaration += "\n"

            declaration += defaultImplementations
                       .filter { !$0.isSubscript }
                       .flatMap {
                           $0.swiftImplementations(inContext: context)
                       }
                       .joined(separator: "\n\n")

            declaration += "\n}"
        }

        return declaration
    }

    func typeCheck(withArgument argument: String) -> String {
        "false"
    }

    static func == (lhs: ProtocolNode, rhs: ProtocolNode) -> Bool {
        lhs.typeName == rhs.typeName
    }
}
