//
//  File.swift
//  
//
//  Created by Manuel Burghard on 19.04.20.
//

import Foundation

class TypeErasedWrapperStruct: TypeNode, Equatable {

    let wrapped: NodePointer

    internal init(wrapped: NodePointer) {
        self.wrapped = wrapped
    }

    var swiftTypeName: String {

        return "TypeErased\(wrapped.identifier)"
    }

    var swiftDeclaration: String {

        let protocolNode = wrapped.node as! ProtocolNode
        let members = protocolNode.requiredMembers

        let (namedSubscript, indexedSubscript) = SubscriptNode.mergedSubscriptNodes(members.filter({ $0.isSubscript }) as! [SubscriptNode])

        var declaration = """
        struct \(swiftTypeName): JSBridgedType, \(wrapped.node!.swiftTypeName) {

            let objectRef: JSObjectRef

            init(objectRef: JSObjectRef) {
                self.objectRef = objectRef
            }

        """

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

    static func == (lhs: TypeErasedWrapperStruct, rhs: TypeErasedWrapperStruct) -> Bool {
        return lhs.wrapped == rhs.wrapped
    }
}
