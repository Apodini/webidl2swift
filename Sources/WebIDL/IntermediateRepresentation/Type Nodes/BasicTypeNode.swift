
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

    func typeCheck(withArgument argument: String) -> String {
        return "false"
    }

    static func == (lhs: BasicTypeNode, rhs: BasicTypeNode) -> Bool {
        return lhs.typeName == rhs.typeName
    }
}

class BasicArrayTypeNode: TypeNode, Equatable {

    let typeName: String
    let scalarType: String

    internal init(typeName: String, scalarType: String) {
        self.typeName = typeName
        self.scalarType = scalarType
    }

    var isArray: Bool {
        return true
    }

    var swiftTypeName: String {
        return typeName
    }

    var arrayElementSwiftTypeName: String? {
        return scalarType
    }

    var swiftDeclaration: String {
        return ""
    }

    static func == (lhs: BasicArrayTypeNode, rhs: BasicArrayTypeNode) -> Bool {
        return lhs.typeName == rhs.typeName &&
            lhs.scalarType == rhs.scalarType
    }

    func typeCheck(withArgument argument: String) -> String {
        return "\(argument).instanceOf(\"\(typeName)\")"
    }
}
