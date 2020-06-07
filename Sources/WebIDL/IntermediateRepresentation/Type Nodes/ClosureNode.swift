
import Foundation

class ClosureNode: TypeNode, Equatable {

    let arguments: [NodePointer]
    let returnType: NodePointer

    internal init(arguments: [NodePointer], returnType: NodePointer) {
        self.arguments = arguments
        self.returnType = returnType
    }

    var isClosure: Bool {
        return true
    }

    var numberOfClosureArguments: Int { arguments.count }

    var swiftTypeName: String {

        return "((\(arguments.map({ $0.node!.swiftTypeName }).joined(separator: ", "))) -> \(returnType.node!.swiftTypeName))"
    }

    var swiftDeclaration: String {
        return ""
    }

    static func == (lhs: ClosureNode, rhs: ClosureNode) -> Bool {
        return lhs.returnType == rhs.returnType && lhs.arguments.count == rhs.arguments.count && lhs.arguments == rhs.arguments
    }
}
