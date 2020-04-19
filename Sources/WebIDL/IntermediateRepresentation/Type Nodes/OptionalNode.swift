//
//  Created by Manuel Burghard on 19.04.20.
//

import Foundation

class OptionalNode: TypeNode, Equatable {

    let wrapped: NodePointer

    internal init(wrapped: NodePointer) {
        self.wrapped = wrapped
    }

    var isOptional: Bool {
        return true
    }

    var isClosure: Bool {
        return wrapped.node!.isClosure
    }

    var isProtocol: Bool {
        return wrapped.node!.isProtocol
    }

    var swiftTypeName: String {
        return "\(wrapped.node!.swiftTypeName)?"
    }

    var swiftDeclaration: String {
        return ""
    }

    var nonOptionalTypeName: String {
        return wrapped.node!.nonOptionalTypeName
    }

    var typeErasedSwiftType: String {
        return wrapped.node!.typeErasedSwiftType + "?"
    }

    var numberOfClosureArguments: Int {
        wrapped.node!.numberOfClosureArguments
    }

    static func == (lhs: OptionalNode, rhs: OptionalNode) -> Bool {
        return lhs.wrapped == rhs.wrapped
    }
}
