//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class ArrayNode: TypeNode, Equatable {

    var element: NodePointer

    internal init(element: NodePointer) {
        self.element = element
    }

    var isArray: Bool {
        true
    }

    var swiftTypeName: String {
        "[\(unwrapNode(element).swiftTypeName)]"
    }

    var swiftDeclaration: String {
        ""
    }

    var arrayElementSwiftTypeName: String? {
        unwrapNode(element).swiftTypeName
    }

    static func == (lhs: ArrayNode, rhs: ArrayNode) -> Bool {
        lhs.element == rhs.element
    }
}
