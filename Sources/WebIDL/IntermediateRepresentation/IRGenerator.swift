
import Foundation

public class IRGenerator {

    var ir = IntermediateRepresentation()
    var useSimpleTypes: Bool = false

    public init() {}

    public func generateIR(for definitions: [Definition]) -> IntermediateRepresentation {

        // https://streams.spec.whatwg.org/#rs-class
        ir.registerBasicType(withTypeName: "ReadableStream")

        for definition in definitions {
            if let interface = definition as? Interface {
                handleInterface(interface)
            } else if let typedef = definition as? Typedef {
                handleTypedef(typedef)
            } else if let dictionary = definition as? Dictionary {
                handleDictionary(dictionary)
            } else if let callbackInterface = definition as? CallbackInterface {
                handleCallbackInterface(callbackInterface)
            } else if let callback = definition as? Callback {
                handleCallback(callback)
            } else if let enumeration = definition as? Enum {
                handleEnum(enumeration)
            } else if let mixin = definition as? Mixin {
                handleMixin(mixin)
            } else if let partial = definition as? Partial {
                handlePartial(partial)
            } else if let includeStatement = definition as? IncludesStatement {
                handleIncludesStatement(includeStatement)
            } else if let namespace = definition as? Namespace {
                handleNamespace(namespace)
            }
        }

        let ir = self.ir
        self.ir = IntermediateRepresentation()
        return ir
    }

    func handleNamespace(_ namespace: Namespace) {

        fatalError("Not supported yet")
    }

    func handlePartial(_ partial: Partial) {

        switch partial {

        case .interface(let interface, _):
            handleInterface(interface)
        case .mixin(let mixin, _):
            handleMixin(mixin)
        case .dictionary(let dictionary, _):
            handleDictionary(dictionary)
        case .namespace(let namespace, _):
            handleNamespace(namespace)
        }
    }

    func handleDictionary(_ dictionary: Dictionary) {

        let inheritsFrom = dictionary.inheritance.map { ir.registerIdentifier(withTypeName: $0.identifier) }

        let memberIdentifiers = dictionary.members.map({ $0.identifier })
        _ = ir.registerDictionaryNode(withTypeName: dictionary.identifier, inheritsFrom: inheritsFrom, members: memberIdentifiers)
    }

    func handleIncludesStatement(_ includeStatment: IncludesStatement) {

        let mixinNodePointer = ir.registerIdentifier(withTypeName: includeStatment.parent)
        ir.registerClass(withTypeName: includeStatment.child, inheritsFrom: [mixinNodePointer], members: [])
    }

    func handleMixin(_ mixin: Mixin) {
        var members = [MemberNode]()

        for member in mixin.members {

            switch member {

            case .const(let const, _):
                members.append(handleConst(const))

            case .regularOperation(let regularOperation, _):

                members.append(handleRegularOperation(regularOperation))
            case .stringifier(_, _):
                // TODO: Add support
                break
            case .readOnlyAttributeRest(false, let attributeRest, _):
                let type = handleDataType(attributeRest.typeWithExtendedAttributes.dataType)
                let name = handleAttributeName(attributeRest.attributeName)

                members.append(ReadWritePropertyNode(name: name, dataType: type))

            case .readOnlyAttributeRest(true, let attributeRest, _):
                  let type = handleDataType(attributeRest.typeWithExtendedAttributes.dataType)
                  let name = handleAttributeName(attributeRest.attributeName)

                  members.append(ReadonlyPropertyNode(name: name, dataType: type))
            }
        }

        ir.registerProtocol(withTypeName: mixin.identifier, inheritsFrom: [], requiredMembers: [], defaultImplementations: members)
    }

    func handleEnum(_ enumeration: Enum) {

        ir.registerEnumeration(withTypeName: enumeration.identifier, cases: enumeration.enumValues.map({ $0.string }))
    }

    func handleCallback(_ callback: Callback) {

        let returnType = handleReturnType(callback.returnType)

        let arguments: [NodePointer] = callback.argumentList.map {
            switch $0.rest {
            case .optional(let typeWithExtendedAttributes, _, _):
                return handleDataType(typeWithExtendedAttributes.dataType)
            case .nonOptional(let dataType, _, _):
                return handleDataType(dataType)
            }
        }

        let closureNode = ClosureNode(arguments: arguments, returnType: returnType)
        _ = ir.registerAliasNode(withTypeName: callback.identifier, aliasing: closureNode)
    }

    func handleInterface(_ interface: Interface) {

        var members = [MemberNode]()

        for member in interface.members {

            switch member {
            case .constructor(let arguments, _):
                members.append(ConstructorNode(className: interface.identifier, parameters: handleArgumentList(arguments)))

            case .const(let const, _):
                members.append(handleConst(const))

            case .operation(let operation, _):
                members.append(handleOperation(operation))

            case .readWriteAttribute(let readWriteAttribute, _):

                members.append(handleReadWriteAttribute(readWriteAttribute))

            case .readOnlyMember(let readOnlyMember, _):
                members.append(handleReadOnlyMember(readOnlyMember))

            default:
                continue
            }
        }

        let inheritsFrom: Set<NodePointer> = interface.inheritance.map({ Set([ir.registerIdentifier(withTypeName: $0.identifier)]) }) ?? []

        ir.registerClass(withTypeName: interface.identifier, inheritsFrom: inheritsFrom, members: members)
    }

    func handleCallbackInterface(_ callbackInterface: CallbackInterface) {

        var requiredMembers = [MemberNode]()
        var defaultImplementations = [MemberNode]()

        for member in callbackInterface.callbackInterfaceMembers {
            switch member {

            case .const(let const, _):
                let type = handleConstType(const.constType)
                defaultImplementations.append(ConstantPropertyNode(name: const.identifier, dataType: type, value: handleConstValue(const.constValue)))

            case .regularOperation(let regularOperation, _):
                requiredMembers.append(handleRegularOperation(regularOperation))
            }
        }

        ir.registerProtocol(withTypeName: callbackInterface.identifer, inheritsFrom:  [], requiredMembers: requiredMembers, defaultImplementations: defaultImplementations)
    }

    func handleTypedef(_ typedef: Typedef) {

        let dataType = handleDataType(typedef.dataType)
        _ = ir.registerAliasNode(withTypeName: typedef.identifier, aliasing: dataType.node!)
    }

    func handleUnionMemberTypes(_ members: [UnionMemberType]) -> NodePointer {

        var visitedTypes = [NodePointer]()
        let typeName: String = members.map({
            let type: NodePointer
            switch $0 {
            case .distinguishableType(_, let distinguishableType):
                type = handleDistinguishableType(distinguishableType)

            case .nullableUnionType(let members, true):
                type = insertOptional(for: handleUnionMemberTypes(members))
                
            case .nullableUnionType(let members, false):
                type = handleUnionMemberTypes(members)
            }
            visitedTypes.append(type)
            return type.identifier
            }).joined(separator: "Or")

        let nodePointer = ir.registerEnumerationWithAssociatedValues(withTypeName: typeName, cases: visitedTypes)
        
        return nodePointer
    }

    func handleStringType(_ stringType: StringType) -> NodePointer {

        return ir.registerBasicType(withTypeName: "String")
    }

    func handleDataType(_ dataType: DataType) -> NodePointer {

        switch dataType {

        case .single(let singleType):
            return handleSingleType(singleType)

        case .union(let members, let isNullable):
            let nodePointer = handleUnionMemberTypes(members)
            if isNullable {
               return insertOptional(for: nodePointer)
            }
            return nodePointer
        }
    }

    func handleSingleType(_ singleType: SingleType) -> NodePointer {

        switch singleType {

        case .distinguishableType(let  distinguishableType):
            return handleDistinguishableType(distinguishableType)
        case .any:
            return ir.registerBasicType(withTypeName: "AnyJSValueConvertible")

        case .promiseType(let promise):
            let returnType = handleReturnType(promise.returnType)
            return ir.registerBasicType(withTypeName: "Promise<\(returnType.identifier)>")
        }
    }

    func handleDistinguishableType(_ distinguishableType: DistinguishableType) -> NodePointer {

        func handleBufferRelated(_ name: String, _ scalarType: String, _ isNullable: Bool) -> NodePointer {

            let basicNodePointer = ir.registerBasicType(withTypeName: scalarType)
            let arrayNode = ArrayNode(element: basicNodePointer)
            let aliasPointer = ir.registerAliasNode(withTypeName: name, aliasing: arrayNode)

            if isNullable {
                return insertOptional(for: aliasPointer)
            }
            return aliasPointer
        }

        switch distinguishableType {
        case .primitive(let primitive, let isNullable):
            let nodePointer = handlePrimitiveType(primitive)
            if isNullable {
                return insertOptional(for: nodePointer)
            }
            return nodePointer

        case .string(let stringType, let isNullable):
            let nodePointer = handleStringType(stringType)
            if isNullable {
                return insertOptional(for: nodePointer)
            }
            return nodePointer

        case .identifier(let identifier, let isNullable):
            let nodePointer = handleIdentifier(identifier)
            if isNullable {
                return insertOptional(for: nodePointer)
            }
            return nodePointer

        case .sequence(let typeWithExtendedAttributes, let isNullable):
            let type = handleDataType(typeWithExtendedAttributes.dataType)
//            guard let elementNode = type.node else {
//                fatalError("Usage of unregistered type")
//            }
            let arrayNode = ArrayNode(element: type)
            let aliasPointer = ir.registerAliasNode(withTypeName: "SequenceOf\(type.identifier)", aliasing: arrayNode)

            if isNullable {
                return insertOptional(for: aliasPointer)
            }
            return aliasPointer

        case .object(let isNullable):
            let nodePointer = ir.registerBasicType(withTypeName: "AnyJSValueConvertible")
            if isNullable {
                return insertOptional(for: nodePointer)
            }
            return nodePointer

        case .symbol(_):
            break

        case .bufferRelated(.DataView, let isNullable):
            let nodePointer = ir.registerBasicType(withTypeName: "DataView")
            if isNullable {
                return insertOptional(for: nodePointer)
            }
            return nodePointer

        case .bufferRelated(.ArrayBuffer, let isNullable):
            return handleBufferRelated("ArrayBuffer", "UInt8", isNullable)

        case .bufferRelated(.Int8Array, let isNullable):
            return handleBufferRelated("Int8Array", "Int8", isNullable)
        case .bufferRelated(.Int16Array, let isNullable):
            return handleBufferRelated("Int16Array", "Int16", isNullable)
        case .bufferRelated(.Int32Array, let isNullable):
            return handleBufferRelated("Int32Array", "Int32", isNullable)
        case .bufferRelated(.Uint8Array, let isNullable):
            return handleBufferRelated("Uint8Array", "UInt8", isNullable)
        case .bufferRelated(.Uint16Array, let isNullable):
            return handleBufferRelated("Uint16Array", "UInt16", isNullable)
        case .bufferRelated(.Uint32Array, let isNullable):
            return handleBufferRelated("Uint32Array", "UInt32", isNullable)
        case .bufferRelated(.Uint8ClampedArray, let isNullable):
            return handleBufferRelated("Uint8ClampedArray", "UInt8", isNullable)
        case .bufferRelated(.Float32Array, let isNullable):
            return handleBufferRelated("Float32Array", "Float", isNullable)
        case .bufferRelated(.Float64Array, let isNullable):
            return handleBufferRelated("Float64Array", "Double", isNullable)
        case .frozenArray(let typeWithExtendedAttributes,  let isNullable):
            let type = handleDataType(typeWithExtendedAttributes.dataType)
            let name = "ArrayOf\(type.identifier)"
//            guard let elementNode = type.node else {
//                fatalError("Usage of unregistered type")
//            }
            let arrayNode = ArrayNode(element: type)
            let aliasPointer = ir.registerAliasNode(withTypeName: name, aliasing: arrayNode)
            if isNullable {
                return insertOptional(for: aliasPointer)
            }
            return aliasPointer

        case .record(let record, _):
            return handleRecordType(record)
        }
        fatalError()
    }

    func handleRecordType(_ recordType: RecordType) -> NodePointer {

        let valueType = handleDataType(recordType.typeWithExtendedAttributes.dataType)
        let name = "\(valueType.identifier)Record"

//        guard let keyNode =  typeHierarchy["String"]?.node,
//            let valueNode = valueType.node else {
//                fatalError("Usage of unregistered type")
//        }
        let recordNode = RecordNode(value: valueType)
        let aliasPointer = ir.registerAliasNode(withTypeName: name, aliasing: recordNode)
        return aliasPointer
    }

    func handlePrimitiveType(_ primitive: PrimitiveType) -> NodePointer {

        switch primitive {
        case .UnsignedIntegerType(let integerType):
            return handleUnsignedIntegerType(integerType)
        case .UnrestrictedFloatType(let floatType):
            return handleUnrestrictedFloatType(floatType)
        case .boolean:
            return ir.registerBasicType(withTypeName: "Bool")
        case .byte:
            return ir.registerBasicType(withTypeName: "Int8")
        case .octet:
            return ir.registerBasicType(withTypeName: "UInt8")
        }
    }

    func handleIdentifier(_ identifier: String) -> NodePointer {

        return ir.registerIdentifier(withTypeName: identifier)
    }

    func handleReadOnlyMember(_ readOnlyMember: ReadOnlyMember) -> ReadonlyPropertyNode {

        switch readOnlyMember {

        case .attribute(let attribute):

            let name = attribute.attributeName.codeRepresentation
            let type = handleDataType(attribute.typeWithExtendedAttributes.dataType)

            return ReadonlyPropertyNode(name: name, dataType: type)

        case .maplike(_):
            fatalError()
        case .setlike(_):
            fatalError()
        }
    }

    func handleConst(_ const: Const) -> ConstantPropertyNode {

        return ConstantPropertyNode(name: const.identifier, dataType: handleConstType(const.constType), value: handleConstValue(const.constValue))
    }

    func handleConstType(_ constType: ConstType) -> NodePointer {

        switch constType {

        case .identifier(let identifier):
            return handleIdentifier(identifier)
        case .primitiveType(let primitiveType):
            return handlePrimitiveType(primitiveType)
        }
    }

    func handleConstValue(_ constValue: ConstValue) -> String {

        switch constValue {

        case .booleanLiteral(true):
            return "true"
        case .booleanLiteral(false):
            return "false"
        case .floatLiteral(.decimal(let value)):
            return String(value)
        case .floatLiteral(.infinity):
            return "Double.infinity"
        case .floatLiteral(.negativeInfinity):
            return "-Double.infinity"
        case .floatLiteral(.notANumber):
            return "Double.nan"
        case .integer(let value):
            return String(value)
        }
    }

    func handleDefaultValue(_ defaultValue: DefaultValue) -> String {

        switch defaultValue {

        case .constValue(let constValue):
            return handleConstValue(constValue)
        case .string(let string):
            return "\"\(string)\""
        case .emptyList:
            return "[]"
        case .emptyDictionary:
            return "[:]"
        case .null:
            return "nil"
        }
    }

    func handleOperation(_ operation: Operation) -> MemberNode {

        switch operation {

        case .regular(let regularOperation):
            return handleRegularOperation(regularOperation)
        case .special(let special, let regularOperation):

            let returnType = handleReturnType(regularOperation.returnType)
            let parameters = handleArgumentList(regularOperation.argumentList)
            switch special {
            case .getter:
                return SubscriptNode(returnType: returnType, kind: .getter, nameParameter: parameters[0], valueParameter: nil)

            case .setter:
                return SubscriptNode(returnType: returnType, kind: .setter, nameParameter: parameters[0], valueParameter: parameters[1])

            case .deleter:
                return SubscriptNode(returnType: returnType, kind: .deleter, nameParameter: parameters[0], valueParameter: nil)
            }
        }
    }

    func handleArgumentList(_ argumentList: [Argument]) -> [ParameterNode] {

        return argumentList.map { (argument) -> ParameterNode in

            switch argument.rest {
            case .optional(let typeWithExtendedAttributes, let label, .some(let defaultValue)):
                let dataType = handleDataType(typeWithExtendedAttributes.dataType)
                return ParameterNode(label: label.codeRepresentation, dataType: dataType, isVariadic: false, isOmittable: true, defaultValue: DefaultValueNode(dataType: dataType, value: handleDefaultValue(defaultValue)))

            case .optional(let typeWithExtendedAttributes, let label, .none):
                return ParameterNode(label: label.codeRepresentation, dataType: handleDataType(typeWithExtendedAttributes.dataType), isVariadic: false, isOmittable: true, defaultValue: nil)

            case .nonOptional(let dataType, let ellipsis, let label):
                return ParameterNode(label: label.codeRepresentation, dataType: handleDataType(dataType), isVariadic: ellipsis, isOmittable: ellipsis, defaultValue: nil)
            }
        }
    }

    func handleRegularOperation(_ regularOperation: RegularOperation) -> MemberNode {

        if let operationName = regularOperation.operationName {
            let name = handleOperationName(operationName)
            let returnType = handleReturnType(regularOperation.returnType)

            return MethodNode(name: name, returnType: returnType, parameters: handleArgumentList(regularOperation.argumentList))
        } else {
            fatalError()
        }
    }

    func handleOperationName(_ operationName: OperationName) -> String {

        switch operationName {
        case .identifier(let identifier):
            return identifier

        case .includes:
            fatalError()
        }
    }

    func handleReturnType(_ returnType: ReturnType) -> NodePointer {
        switch returnType {
        case .void:
            return ir.registerBasicType(withTypeName: "Void")

        case .dataType(let dataType):
            return handleDataType(dataType)
        }
    }

    func handleUnsignedIntegerType(_ integerType: UnsignedIntegerType) -> NodePointer {
        guard !useSimpleTypes else {
            return ir.registerBasicType(withTypeName: "Int32")
        }

        switch integerType {
        case .unsigned(.short):
            return ir.registerBasicType(withTypeName: "UInt16")

        case .unsigned(.long):
            return ir.registerBasicType(withTypeName: "UInt32")

        case .unsigned(.longLong):
            return ir.registerBasicType(withTypeName: "UInt64")

        case .signed(.short):
            return ir.registerBasicType(withTypeName: "Int16")

        case .signed(.long):
            return ir.registerBasicType(withTypeName: "Int32")

        case .signed(.longLong):
            return ir.registerBasicType(withTypeName: "Int64")
        }
    }

    func handleUnrestrictedFloatType(_ unrestrictedFloatType: UnrestrictedFloatType) -> NodePointer {

        // TODO: No unrestricted handling
        switch unrestrictedFloatType {
        case .unrestricted(let floatType), .restricted(let floatType):
            return handleFloatType(floatType)
        }
    }

    func handleFloatType(_ floatType: FloatType) -> NodePointer {

        guard !useSimpleTypes else {
            return ir.registerBasicType(withTypeName: "Double")

        }

        switch floatType {
        case .double:
            return ir.registerBasicType(withTypeName: "Double")

        case .float:
            return ir.registerBasicType(withTypeName: "Float")
        }
    }

    func handleReadWriteAttribute(_ readWriteAttribute: ReadWriteAttribute) -> ReadWritePropertyNode {

        switch readWriteAttribute {
        case .inherit(let attributeRest), .notInherit(let attributeRest):
            let type = handleDataType(attributeRest.typeWithExtendedAttributes.dataType)
            let name = handleAttributeName(attributeRest.attributeName)

            return ReadWritePropertyNode(name: name, dataType: type)
        }
    }

    func handleAttributeName(_ attributeName: AttributeName) -> String {

        switch attributeName {
        case .attributeNameKeyword(let keyword):
            return keyword.rawValue
        case .identifier(let identifier):
            return identifier
        }
    }

    func insertOptional(for nodePointer: NodePointer) -> NodePointer {

        let aliasPointer = ir.registerOptional(for: nodePointer)
        return aliasPointer
    }
}

extension ArgumentName {

    var swiftKeyWords: [String : String] { [
        "init" : "`init`",
        "where" : "`where`",
        "protocol" : "`protocol`",
        "struct" : "`struct`",
        "class" : "`class`",
        "enum" : "`enum`",
        "func" : "`func`",
        "static" : "`static`",
        ]
    }

    var codeRepresentation: String {
        switch self {
        case .identifier(let identifier):
            return swiftKeyWords[identifier] ?? identifier
        case .argumentNameKeyword(let keyword):
            return keyword.rawValue
        }
    }
}

extension AttributeName {

    var codeRepresentation: String {
        switch self {
        case .attributeNameKeyword(let keyword): return keyword.rawValue
        case .identifier(let identifier): return identifier
        }
    }
}
