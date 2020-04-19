//
//  Created by Manuel Burghard on 19.04.20.
//

import Foundation

class ParameterNode: Equatable {

    let label: String
    let dataType: NodePointer
    let isVariadic: Bool
    let isOmittable: Bool
    let defaultValue: DefaultValueNode?

    internal init(label: String, dataType: NodePointer, isVariadic: Bool, isOmittable: Bool, defaultValue: DefaultValueNode?) {
        self.label = label
        self.dataType = dataType
        self.isVariadic = isVariadic
        self.isOmittable = isOmittable
        self.defaultValue = defaultValue
    }

    static func == (lhs: ParameterNode, rhs: ParameterNode) -> Bool {
        return lhs.label == rhs.label &&
            lhs.isVariadic == rhs.isVariadic &&
            lhs.isOmittable == rhs.isOmittable &&
            lhs.defaultValue == rhs.defaultValue &&
            lhs.dataType == rhs.dataType
    }
}

func equal(_ lhs: ParameterNode?, _ rhs: ParameterNode?) -> Bool {

    if let l = lhs, let r = rhs {
        return l == r
    } else {
        return false
    }
}
