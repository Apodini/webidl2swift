
import Foundation

class BasicTypeNode: TypeNode, Equatable {

    let typeName: String

    internal init(typeName: String) {
        self.typeName = typeName
    }

    var swiftTypeName: String {
        return typeName
    }

    var swiftDeclaration: String {
        return ""
    }

    static func == (lhs: BasicTypeNode, rhs: BasicTypeNode) -> Bool {
        return lhs.typeName == rhs.typeName
    }
}
