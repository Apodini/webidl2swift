//
//  Created by Manuel Burghard on 19.04.20.
//

import Foundation

class RecordNode: TypeNode, Equatable {

    let value: NodePointer

    internal init(value: NodePointer) {
        self.value = value
    }

    var isRecord: Bool {
        return true
    }

    var swiftTypeName: String {
        return "[String : \(value.node!.swiftTypeName)]"
    }

    var swiftDeclaration: String {
        ""
    }

    static func == (lhs: RecordNode, rhs: RecordNode) -> Bool {
        return lhs.value == rhs.value
    }
}
