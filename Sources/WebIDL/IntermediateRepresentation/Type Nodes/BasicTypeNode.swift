//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class BasicTypeNode: TypeNode, Equatable {

    let typeName: String

    internal init(typeName: String) {
        self.typeName = typeName
    }

    var swiftTypeName: String {
        typeName
    }

    var swiftDeclaration: String {
        ""
    }

    func typeCheck(withArgument argument: String) -> String {
        "false"
    }

    static func == (lhs: BasicTypeNode, rhs: BasicTypeNode) -> Bool {
        lhs.typeName == rhs.typeName
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
        true
    }

    var swiftTypeName: String {
        "JSTypedArray<\(scalarType)>"
    }

    var arrayElementSwiftTypeName: String? {
        scalarType
    }

    var swiftDeclaration: String {
        ""
    }

    static func == (lhs: BasicArrayTypeNode, rhs: BasicArrayTypeNode) -> Bool {
        lhs.typeName == rhs.typeName && lhs.scalarType == rhs.scalarType
    }

    func typeCheck(withArgument argument: String) -> String {
        "\(argument).instanceOf(\"\(typeName)\")"
    }
}
