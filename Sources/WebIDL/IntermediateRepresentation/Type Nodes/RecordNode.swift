//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class RecordNode: TypeNode, Equatable {

    let value: NodePointer

    internal init(value: NodePointer) {
        self.value = value
    }

    var isRecord: Bool {
        true
    }

    var swiftTypeName: String {
        "[String : \(unwrapNode(value).swiftTypeName)]"
    }

    var swiftDeclaration: String {
        ""
    }

    func typeCheck(withArgument argument: String) -> String {
         "case .object = \(argument)"
    }

    static func == (lhs: RecordNode, rhs: RecordNode) -> Bool {
        lhs.value == rhs.value
    }
}
