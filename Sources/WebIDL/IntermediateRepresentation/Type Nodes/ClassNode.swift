//
//  Created by Manuel Burghard. Licensed unter MIT.
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

        typeName
    }

    var isClass: Bool { true }

    var swiftDeclaration: String {

        let context = MemberNodeContext.classContext(typeName)

        // swiftlint:disable force_cast
        let (namedSubscript, indexedSubscript) = SubscriptNode.mergedSubscriptNodes( members.filter { $0.isSubscript } as! [SubscriptNode])
        // swiftlint:enable force_cast

        let propertyNodes = members.compactMap { $0 as? PropertyNode }

        var declaration: String

        let inheritance: String
        let isBaseClass: Bool

        let sorted = inheritsFrom.sorted {

            let firstNode = unwrapNode($0)
            let secondNode = unwrapNode($1)

            if firstNode.isClass && !secondNode.isClass {
                return true
            } else if !firstNode.isClass && secondNode.isClass {
                return false
            } else {
                return $0.identifier < $1.identifier
            }
        }

        let adoptedProtocols = members.flatMap { $0.adoptedProtocols }

        if let first = sorted.first, unwrapNode(first).isClass {
            isBaseClass = false
            inheritance = (sorted.map { unwrapNode($0).swiftTypeName } + adoptedProtocols).joined(separator: ", ")
        } else {
            isBaseClass = true
            inheritance = (["JSBridgedType"] + sorted.map { unwrapNode($0).swiftTypeName } + adoptedProtocols).joined(separator: ", ")
        }

        if isBaseClass {
            declaration = """
            public class \(typeName): \(inheritance) {

                public class var classRef: JSFunctionRef { JSObjectRef.global.\(typeName).function! }

                public let objectRef: JSObjectRef

                public required init(objectRef: JSObjectRef) {
                    \(propertyNodes.compactMap { $0.initializationStatement(forContext: context) }.joined(separator: "\n"))
                    self.objectRef = objectRef
                }

            """
        } else {
            declaration = """
            public class \(typeName): \(inheritance) {

                public override class var classRef: JSFunctionRef { JSObjectRef.global.\(typeName).function! }

                public required init(objectRef: JSObjectRef) {
                    \(propertyNodes.compactMap { $0.initializationStatement(forContext: context) }.joined(separator: "\n"))
                    super.init(objectRef: objectRef)
                }

            """
        }

        declaration += "\n"
        members.forEach { declaration += $0.typealiases.joined(separator: "\n") }
        declaration += "\n"

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

    func typeCheck(withArgument argument: String) -> String {

        "\(argument).instanceOf(\"\(typeName)\")"
    }

    static func == (lhs: ClassNode, rhs: ClassNode) -> Bool {
        lhs.typeName == rhs.typeName
    }
}
