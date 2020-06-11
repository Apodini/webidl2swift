//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class ClosureNode: TypeNode, Equatable {

    let arguments: [NodePointer]
    let returnType: NodePointer

    internal init(arguments: [NodePointer], returnType: NodePointer) {
        self.arguments = arguments
        self.returnType = returnType
    }

    var isClosure: Bool {
        true
    }

    var numberOfClosureArguments: Int {
        arguments.count
    }

    var swiftTypeName: String {

        let argumentDeclarations = arguments.map {
            unwrapNode($0).swiftTypeName
        }
        .joined(separator: ", ")
        return "((\(argumentDeclarations)) -> \(unwrapNode(returnType).swiftTypeName))"
    }

    var swiftDeclaration: String {
        ""
    }

    func typeCheck(withArgument argument: String) -> String {
        "false"
    }

    static func == (lhs: ClosureNode, rhs: ClosureNode) -> Bool {
        lhs.returnType == rhs.returnType &&
            lhs.arguments.count == rhs.arguments.count &&
            lhs.arguments == rhs.arguments
    }
}
