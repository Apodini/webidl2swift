//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class DefaultValueNode: ExpressionNode, Equatable {

    let dataType: NodePointer
    let value: String

    internal init(dataType: NodePointer, value: String) {
        self.dataType = dataType
        self.value = value
    }

    static func == (lhs: DefaultValueNode, rhs: DefaultValueNode) -> Bool {
        lhs.value == rhs.value && lhs.dataType == rhs.dataType
    }
}
