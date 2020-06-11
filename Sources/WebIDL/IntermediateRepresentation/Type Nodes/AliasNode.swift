//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class AliasNode: TypeNode, Equatable {

    let typeName: String
    let aliased: TypeNode

    internal init(typeName: String, aliased: TypeNode) {
        self.typeName = typeName
        self.aliased = aliased
    }

    var isOptional: Bool {
        aliased.isOptional
    }

    var isClosure: Bool {
        aliased.isClosure
    }

    var isEnum: Bool {
        aliased.isEnum
    }

    var isArray: Bool {
        aliased.isArray
    }

    var isDictionary: Bool {
        aliased.isDictionary
    }

    var swiftTypeName: String {
        typeName
    }

    var isProtocol: Bool {
        aliased.isProtocol
    }

    var swiftDeclaration: String {
        "public typealias \(typeName) = \(aliased.swiftTypeName)"
    }

    var nonOptionalTypeName: String {
        aliased.nonOptionalTypeName
    }

    var typeErasedSwiftType: String {
        aliased.typeErasedSwiftType
    }

    var numberOfClosureArguments: Int {
        aliased.numberOfClosureArguments
    }

    static func == (lhs: AliasNode, rhs: AliasNode) -> Bool {

        lhs.typeName == rhs.typeName && equal(lhs.aliased, rhs.aliased)
    }
}
