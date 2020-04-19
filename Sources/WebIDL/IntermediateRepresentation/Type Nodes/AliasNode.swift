//
//  Created by Manuel Burghard on 19.04.20.
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
        return aliased.isOptional
    }

    var isClosure: Bool {
        return aliased.isClosure
    }

    var isEnum: Bool {
        return aliased.isEnum
    }

    var isArray: Bool {
        return aliased.isArray
    }

    var isDictionary: Bool {
        return aliased.isDictionary
    }

    var swiftTypeName: String {
        return typeName
    }

    var isProtocol: Bool {
        return aliased.isProtocol
    }

    var swiftDeclaration: String {
        return "public typealias \(typeName) = \(aliased.swiftTypeName)"
    }

    var nonOptionalTypeName: String {
        return aliased.nonOptionalTypeName
    }

    var typeErasedSwiftType: String {
        return aliased.typeErasedSwiftType
    }

    var numberOfClosureArguments: Int {
        aliased.numberOfClosureArguments
    }

    static func == (lhs: AliasNode, rhs: AliasNode) -> Bool {

        return lhs.typeName == rhs.typeName && equal(lhs.aliased, rhs.aliased)
    }
}
