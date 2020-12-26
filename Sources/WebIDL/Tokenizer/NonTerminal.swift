//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

// swiftlint:disable identifier_name
public enum NonTerminal: String, Equatable, CustomStringConvertible {

    public var description: String {
        rawValue
    }

    case Definitions = "Definitions"
    case Definition = "Definition"
    case ArgumentNameKeyword = "ArgumentNameKeyword"
    case CallbackOrInterfaceOrMixin = "CallbackOrInterfaceOrMixin"
    case InterfaceOrMixin = "InterfaceOrMixin"
    case InterfaceRest = "InterfaceRest"
    case Partial = "Partial"
    case PartialDefinition = "PartialDefinition"
    case PartialInterfaceOrPartialMixin = "PartialInterfaceOrPartialMixin"
    case PartialInterfaceRest = "PartialInterfaceRest"
    case InterfaceMembers = "InterfaceMembers"
    case InterfaceMember = "InterfaceMember"
    case PartialInterfaceMembers = "PartialInterfaceMembers"
    case PartialInterfaceMember = "PartialIntrerfaceMember"
    case Inheritance = "Inheritance"
    case MixinRest = "MixinRest"
    case MixinMembers = "MixinMembers"
    case MixinMember = "MixinMember"
    case IncludesStatement = "IncludesStatement"
    case CallbackRestOrInterface = "CallbackRestOrInterface"
    case CallbackInterfaceMembers = "CallbackInterfaceMembers"
    case CallbackInterfaceMember = "CallbackInterfaceMember"
    case Const = "Const"
    case ConstValue = "ConstValue"
    case BooleanLiteral = "BooleanLiteral"
    case FloatLiteral = "FloatLiteral"
    case ConstType = "ConstType"
    case ReadOnlyMember = "ReadOnlyMember"
    case ReadOnlyMemberRest = "ReadOnlyMemberRest"
    case ReadWriteAttribute = "ReadWriteAttribute"
    case AttributeRest = "AttributeRest"
    case AttributeName = "AttributeName"
    case AttributeNameKeyword = "AttributeNameKeyword"
    case ReadOnly = "ReadOnly"
    case DefaultValue = "DefaultValue"
    case Operation = "Operation"
    case RegularOperation = "RegularOperation"
    case SpecialOperation = "SpecialOperation"
    case Special = "Special"
    case OperationRest = "OperationRest"
    case OptionalOperationName = "OptionalOperationName"
    case OperationName = "OperationName"
    case OperationNameKeyword = "OperationNameKeyword"
    case ArgumentList = "ArgumentList"
    case Arguments = "Arguments"
    case Argument = "Argument"
    case ArgumentRest = "ArgumentRest"
    case ArgumentName = "ArgumentName"
    case Ellipsis = "Ellipsis"
    case Constructor = "Constructor"
    case Stringifier = "Stringifier"
    case StringifierRest = "StringifierRest"
    case StaticMember = "StaticMember"
    case StaticMemberRest = "StaticMemberRest"
    case Iterable = "Iterable"
    case OptionalType = "OptionalType"
    case AsyncIterable = "AsyncIterable"
    case ReadWriteMaplike = "ReadWriteMaplike"
    case MaplikeRest = "MaplikeRest"
    case ReadWriteSetlike = "ReadWriteSetlike"
    case SetlikeRest = "SetlikeRest"
    case Namespace = "Namespace"
    case NamespaceMembers = "NamespaceMembers"
    case NamespaceMember = "NamespaceMember"
    case Dictionary = "Dictionary"
    case DictionaryMembers = "DictionaryMembers"
    case DictionaryMember = "DictionaryMember"
    case DictionaryMemberRest = "DictionaryMemberRest"
    case PartialDictionary = "PartialDictionary"
    case Default = "Default"
    case Enum = "Enum"
    case EnumValueList = "EnumValueList"
    case EnumValueListComma = "EnumValueListComma"
    case EnumValueListString = "EnumValueListString"
    case CallbackRest = "CallbackRest"
    case Typedef = "Typedef"
    case `Type` = "`Type`"
    case TypeWithExtendedAttributes = "TypeWithExtendedAttributes"
    case SingleType = "SingleType"
    case UnionType = "UnionType"
    case UnionMemberType = "UnionMemberType"
    case UnionMemberTypes = "UnionMemberTypes"
    case DistinguishableType = "DistinguishableType"
    case PrimitiveType = "PrimitiveType"
    case UnrestrictedFloatType = "UnrestrictedFloatType"
    case FloatType = "FloatType"
    case UnsignedIntegerType = "UnsignedIntegerType"
    case IntegerType = "IntegerType"
    case OptionalLong = "OptionalLong"
    case StringType = "StringType"
    case PromiseType = "PromiseType"
    case RecordType = "RecordType"
    case Null = "Null"
    case BufferRelatedType = "BufferRelatedType"
    case ExtendedAttributeList = "ExtendedAttributeList"
    case ExtendedAttributes = "ExtendedAttributes"
    case ExtendedAttribute = "ExtendedAttribute"
    case ExtendedAttributeRest = "ExtendedAttributeRest"
    case ExtendedAttributeInner = "ExtendedAttributeInner"
    case Other = "Other"
    case OtherOrComma = "OtherOrComma"
    case IdentifierList = "IdentifierList"
    case Identifiers = "Identifiers"
    case ExtendedAttributeNoArgs = "ExtendedAttributeNoArgs"
    case ExtendedAttributeArgList = "ExtendedAttributeArgList"
    case ExtendedAttributeIdent = "ExtendedAttributeIdent"
    case ExtendedAttributeIdentList = "ExtendedAttributeIdentList"
    case ExtendedAttributeNamedArgList = "ExtendedAttributeNamedArgList"
}
// swiftlint:enable identifier_name
