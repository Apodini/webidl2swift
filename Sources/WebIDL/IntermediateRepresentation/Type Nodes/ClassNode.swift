//
//  Created by Manuel Burghard on 19.04.20.
//

import Foundation

class ClassNode: TypeNode, Equatable {

    let typeName: String
    var inheritsFrom: Set<NodePointer>

    var members: [MemberNode]

    internal init(typeName: String, inheritsFrom: Set<NodePointer>, members: [MemberNode]) {
        self.typeName = typeName
        self.inheritsFrom = inheritsFrom
        self.members = members
    }

    var swiftTypeName: String {

        return typeName
    }

    var isClass: Bool { true }

    var swiftDeclaration: String {

        let (namedSubscript, indexedSubscript) = SubscriptNode.mergedSubscriptNodes( members.filter({ $0.isSubscript }) as! [SubscriptNode])

        let propertyNodes = members.compactMap({ $0 as? PropertyNode })

        var declaration: String

        let inheritance: String
        let isBaseClass: Bool

        let sorted = inheritsFrom.sorted {

            if $0.node!.isClass && !$1.node!.isClass {
                return true
            } else if !$0.node!.isClass && $1.node!.isClass {
                return false
            } else {
                return $0.identifier < $1.identifier
            }
        }

        if let first = sorted.first, first.node!.isClass {
            isBaseClass = false
            inheritance = sorted.map({ $0.node!.swiftTypeName }).joined(separator: ", ")
        } else {
            isBaseClass = true
            inheritance = (["JSBridgedType"] + sorted.map({ $0.node!.swiftTypeName })).joined(separator: ", ")
        }

        if isBaseClass {
            declaration = """
            public class \(typeName): \(inheritance) {

                public let objectRef: JSObjectRef

                public required init(objectRef: JSObjectRef) {
                    \(propertyNodes.compactMap({ $0.initializationStatement(forContext: .classContext) }).joined(separator: "\n"))
                    self.objectRef = objectRef
                }

            """
        } else {
            declaration = """
            public class \(typeName): \(inheritance) {

                public required init(objectRef: JSObjectRef) {
                    \(propertyNodes.compactMap({ $0.initializationStatement(forContext: .classContext) }).joined(separator: "\n"))
                    super.init(objectRef: objectRef)
                }

            """
        }

        declaration += "\n"
        namedSubscript.map { declaration += $0.swiftImplementations(inContext: .classContext).joined(separator: "\n\n")}
        declaration += "\n"
        indexedSubscript.map { declaration += $0.swiftImplementations(inContext: .classContext).joined(separator: "\n\n")}
        declaration += "\n"

        declaration += members
            .filter({ !$0.isSubscript })
            .flatMap({
                return $0.swiftImplementations(inContext: .classContext)
            })
            .joined(separator: "\n\n")

        declaration += "\n}"

        return declaration
    }

    static func == (lhs: ClassNode, rhs: ClassNode) -> Bool {
        return lhs.typeName == rhs.typeName
    }
}
