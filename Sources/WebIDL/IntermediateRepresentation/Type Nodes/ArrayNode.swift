
import Foundation

class ArrayNode: TypeNode, Equatable {

    var element: NodePointer

    internal init(element: NodePointer) {
        self.element = element
    }

    var isArray: Bool {
        return true
    }

    var swiftTypeName: String {
        return "[\(element.node!.swiftTypeName)]"
    }

    var swiftDeclaration: String {
        return ""
    }

    static func == (lhs: ArrayNode, rhs: ArrayNode) -> Bool {
        return lhs.element == rhs.element
    }
}
