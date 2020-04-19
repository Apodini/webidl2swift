//
//  Created by Manuel Burghard on 19.04.20.
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
        return lhs.value == rhs.value && lhs.dataType == rhs.dataType
    }
}
