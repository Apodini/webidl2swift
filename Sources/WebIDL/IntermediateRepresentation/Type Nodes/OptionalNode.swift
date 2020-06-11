//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class OptionalNode: TypeNode, Equatable {

    let wrapped: NodePointer

    internal init(wrapped: NodePointer) {
        self.wrapped = wrapped
    }

    var isOptional: Bool {
        true
    }

    var isClosure: Bool {
        unwrapNode(wrapped).isClosure
    }

    var isProtocol: Bool {
        unwrapNode(wrapped).isProtocol
    }

    var swiftTypeName: String {
        "\(unwrapNode(wrapped).swiftTypeName)?"
    }

    var swiftDeclaration: String {
        ""
    }

    var nonOptionalTypeName: String {
        unwrapNode(wrapped).nonOptionalTypeName
    }

    var typeErasedSwiftType: String {
        unwrapNode(wrapped).typeErasedSwiftType + "?"
    }

    var numberOfClosureArguments: Int {
        unwrapNode(wrapped).numberOfClosureArguments
    }

    static func == (lhs: OptionalNode, rhs: OptionalNode) -> Bool {
        lhs.wrapped == rhs.wrapped
    }
}
