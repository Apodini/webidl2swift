
import Foundation

public class IRGenerator {

    var ir = IntermediateRepresentation()
    var useSimpleTypes: Bool = false

    public init() {}

    public func generateIR(for definitions: [Definition]) -> IntermediateRepresentation {

        // https://streams.spec.whatwg.org/#rs-class
        ir.registerBasicType(withTypeName: "ReadableStream")
        ir.registerBasicArrayType(withTypeName: "Float64Array", scalarType: "Double")
        ir.registerBasicArrayType(withTypeName: "Float32Array", scalarType: "Float")
        ir.registerBasicArrayType(withTypeName: "Uint32Array", scalarType: "UInt32")
        ir.registerBasicArrayType(withTypeName: "Uint16Array", scalarType: "UInt16")
        ir.registerBasicArrayType(withTypeName: "Uint8Array", scalarType: "UInt8")
        ir.registerBasicArrayType(withTypeName: "Uint8ClampedArray", scalarType: "UInt8")
        ir.registerBasicArrayType(withTypeName: "Int32Array", scalarType: "Int32")
        ir.registerBasicArrayType(withTypeName: "Int16Array", scalarType: "Int16")
        ir.registerBasicArrayType(withTypeName: "Int8Array", scalarType: "Int8")
        ir.registerBasicType(withTypeName: "ArrayBuffer")
        ir.registerBasicType(withTypeName: "DataView")

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

        let members = namespace.namespaceMembers.map { (member) -> MemberNode in

            switch member {

            case .regularOperation(let regularOperation, _):
                return handleRegularOperation(regularOperation)
            case .readonlyAttribute(let attributeRest):
                let dataType = handleDataType(attributeRest.typeWithExtendedAttributes.dataType)
                let name = handleAttributeName(attributeRest.attributeName)
                return ReadonlyPropertyNode(name: name, dataType: dataType, isStatic: false)
            }
        }

        ir.registerNamespace(withTypeName: namespace.identifier, members: members)
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

                members.append(ReadWritePropertyNode(name: name, dataType: type, isOverride: false, isStatic: false))

            case .readOnlyAttributeRest(true, let attributeRest, _):
                  let type = handleDataType(attributeRest.typeWithExtendedAttributes.dataType)
                  let name = handleAttributeName(attributeRest.attributeName)

                  members.append(ReadonlyPropertyNode(name: name, dataType: type, isStatic: false))
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

            case .stringifier(_, _):
                // Not required: JSBridgedType conforms to CustomStringConvertible
                break

            case .staticMember(let staticMember, _):
                if let member = handleStaticMember(staticMember) {
                    members.append(member)
                }

            case .iterable(let iterable, _):
                members.append(handleIterable(iterable))

            case .asyncIterable(_, _),
                 .readWriteMaplike(_, _),
                 .readWriteSetlike(_, _):
                // Not implemented yet.
                break
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
            return ir.registerBasicType(withTypeName: "AnyJSValueCodable")

        case .promiseType(let promise):
            let returnType = handleReturnType(promise.returnType)
            return ir.registerBasicType(withTypeName: "Promise<\(returnType.identifier)>")
        }
    }

    func handleDistinguishableType(_ distinguishableType: DistinguishableType) -> NodePointer {

        func handleBufferRelated(_ name: String, _ isNullable: Bool) -> NodePointer {

            let basicNodePointer = ir.registerBasicType(withTypeName: name)
            if isNullable {
                return insertOptional(for: basicNodePointer)
            }
            return basicNodePointer
        }

        func handleBufferRelatedWithScalarType(_ name: String, _ scalarType: String, _ isNullable: Bool) -> NodePointer {

            let basicNodePointer = ir.registerBasicArrayType(withTypeName: name, scalarType: scalarType)
            if isNullable {
                return insertOptional(for: basicNodePointer)
            }
            return basicNodePointer
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
            let arrayNode = ir.registerArrayNode(withTypeName: "\(type.identifier)Sequence", element: type)

            if isNullable {
                return insertOptional(for: arrayNode)
            }
            return arrayNode

        case .object(let isNullable):
            let nodePointer = ir.registerBasicType(withTypeName: "AnyJSValueCodable")
            if isNullable {
                return insertOptional(for: nodePointer)
            }
            return nodePointer

        case .symbol(_):
            break

        case .bufferRelated(.DataView, let isNullable):
            return handleBufferRelated("DataView", isNullable)

        case .bufferRelated(.ArrayBuffer, let isNullable):
            return handleBufferRelated("ArrayBuffer", isNullable)

        case .bufferRelated(.Int8Array, let isNullable):
            return handleBufferRelatedWithScalarType("Int8Array", "Int8", isNullable)
        case .bufferRelated(.Int16Array, let isNullable):
            return handleBufferRelatedWithScalarType("Int16Array", "Int16", isNullable)
        case .bufferRelated(.Int32Array, let isNullable):
            return handleBufferRelatedWithScalarType("Int32Array", "Int32", isNullable)
        case .bufferRelated(.Uint8Array, let isNullable):
            return handleBufferRelatedWithScalarType("Uint8Array", "UInt8", isNullable)
        case .bufferRelated(.Uint16Array, let isNullable):
            return handleBufferRelatedWithScalarType("Uint16Array", "UInt16", isNullable)
        case .bufferRelated(.Uint32Array, let isNullable):
            return handleBufferRelatedWithScalarType("Uint32Array", "UInt32", isNullable)
        case .bufferRelated(.Uint8ClampedArray, let isNullable):
            return handleBufferRelatedWithScalarType("Uint8ClampedArray", "UInt8", isNullable)
        case .bufferRelated(.Float32Array, let isNullable):
            return handleBufferRelatedWithScalarType("Float32Array", "Float", isNullable)
        case .bufferRelated(.Float64Array, let isNullable):
            return handleBufferRelatedWithScalarType("Float64Array", "Double", isNullable)
        case .frozenArray(let typeWithExtendedAttributes,  let isNullable):
            let type = handleDataType(typeWithExtendedAttributes.dataType)
            let name = "\(type.identifier)Array"
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

            return ReadonlyPropertyNode(name: name, dataType: type, isStatic: false)

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
        case .inherit(let attributeRest):
            let type = handleDataType(attributeRest.typeWithExtendedAttributes.dataType)
            let name = handleAttributeName(attributeRest.attributeName)

            return ReadWritePropertyNode(name: name, dataType: type, isOverride: true, isStatic: false)

        case .notInherit(let attributeRest):
            let type = handleDataType(attributeRest.typeWithExtendedAttributes.dataType)
            let name = handleAttributeName(attributeRest.attributeName)

            return ReadWritePropertyNode(name: name, dataType: type, isOverride: false, isStatic: false)
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

    func handleIterable(_ iterable: Iterable) -> MemberNode {

        switch (iterable.typeWithExtendedAttributes0.dataType, iterable.typeWithExtendedAttributes1?.dataType) {
        case (_, let second?):
            return PairIterableNode(dataType: handleDataType(second))

        case (let first, nil):
            return ValueIterableNode(dataType: handleDataType(first))
        }
    }

    func handleStaticMember(_ staticMember: StaticMember) -> MemberNode? {

        switch staticMember {

        case .readOnlyAttributeRest(false, let attributeRest):
            let type = handleDataType(attributeRest.typeWithExtendedAttributes.dataType)
            let name = handleAttributeName(attributeRest.attributeName)

            return ReadWritePropertyNode(name: name, dataType: type, isOverride: false, isStatic: true)

        case .readOnlyAttributeRest(true, let attributeRest):
            let type = handleDataType(attributeRest.typeWithExtendedAttributes.dataType)
            let name = handleAttributeName(attributeRest.attributeName)

            return ReadonlyPropertyNode(name: name, dataType: type, isStatic: true)
            
        case .regularOperation(let operation):
            // Not supported. Cannot be looked up
            return nil
        }
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
