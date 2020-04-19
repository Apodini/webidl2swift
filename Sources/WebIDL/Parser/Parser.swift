
import Foundation

public class Parser {

    var tokens: Tokens
    var identifiers: [String]
    var integers: [Int]
    var decimals: [Double]
    var strings: [String]
    var others: [String]

    public init(input: TokenisationResult) {
        self.tokens = input.tokens.filter({

            switch $0 {
            case .comment, .multilineComment:
                return false
            default:
                return true
            }
        })
        self.identifiers = input.identifiers
        self.integers = input.integers
        self.decimals = input.decimals
        self.strings = input.strings
        self.others = input.others
    }

    func expect(next: Token) {

        while case .comment = tokens.first {
            print("Skipping comment")
            tokens.removeFirst()
        }
        
        guard let nextCharacter = tokens.first else {
            fatalError("No input left")
        }

        guard nextCharacter == next else {
            fatalError("Wrong token: Expected \(next), but got \(nextCharacter)")
        }

        tokens.removeFirst()
    }

    func check(forNext next: Token) -> Bool {

        guard let nextCharacter = tokens.first else {
            return false
        }

        guard nextCharacter == next else {
            return false
        }
        tokens.removeFirst()
        return true
    }

    public func parse() throws -> [Definition] {

        return try parseDefinitions()
    }

    func parseDefinitions() throws -> [Definition] {

        /*
         Definitions ::
         ExtendedAttributeList Definition Definitions
         ε
         */

        guard tokens.isEmpty == false else {
            return []
        }

        let extendedAttributeList = try parseExtendedAttributeList()

        let definition = try parseDefinition(extendedAttributeList: extendedAttributeList)

        return try [definition] + parseDefinitions()
    }

    func parseDefinition(extendedAttributeList: ExtendedAttributeList) throws -> Definition {
        /*
         Definition ::
         CallbackOrInterfaceOrMixin
         Namespace
         Partial
         Dictionary
         Enum
         Typedef
         IncludesStatement
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .CallbackOrInterfaceOrMixin).contains(t):
            return try parseCallbackOrInterfaceOrMixin(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .Namespace).contains(t):
            return try parseNamespace(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .Partial).contains(t):
            return try parsePartial(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .Dictionary).contains(t):
            return try parseDictionary(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .Enum).contains(t):
            return try parseEnum(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .Typedef).contains(t):
            return try parseTypedef(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .IncludesStatement).contains(t):
            return try parseIncludesStatement(extendedAttributeList: extendedAttributeList)

        case let t:
            try unexpected(t)
        }
    }

    func parseArgumentNameKeyword() throws -> ArgumentNameKeyword {

        /*
         ArgumentNameKeyword ::
         async
         attribute
         callback
         const
         constructor
         deleter
         dictionary
         enum
         getter
         includes
         inherit
         interface
         iterable
         maplike
         mixin
         namespace
         partial
         readonly
         required
         setlike
         setter
         static
         stringifier
         typedef
         unrestricted
         */

        switch tokens.removeFirst() {
        case .terminal(.async): return .async
        case .terminal(.attribute): return .attribute
        case .terminal(.callback): return .callback
        case .terminal(.const): return .const
        case .terminal(.constructor): return .constructor
        case .terminal(.deleter): return .deleter
        case .terminal(.dictionary): return .dictionary
        case .terminal(.enum): return .enum
        case .terminal(.getter): return .getter
        case .terminal(.includes): return .includes
        case .terminal(.inherit): return .inherit
        case .terminal(.interface): return .interface
        case .terminal(.iterable): return .iterable
        case .terminal(.maplike): return .maplike
        case .terminal(.mixin): return .mixin
        case .terminal(.namespace): return .namespace
        case .terminal(.partial): return .partial
        case .terminal(.readonly): return .readonly
        case .terminal(.required): return .required
        case .terminal(.setlike): return .setlike
        case .terminal(.setter): return .setter
        case .terminal(.static): return .static
        case .terminal(.stringifier): return .stringifier
        case .terminal(.typedef): return .typedef
        case .terminal(.unrestricted): return .unrestricted
        case let t:
            try unexpected(t)
        }
    }

    func parseCallbackOrInterfaceOrMixin(extendedAttributeList: ExtendedAttributeList) throws -> Definition {

        /*
         CallbackOrInterfaceOrMixin ::
         callback CallbackRestOrInterface
         interface InterfaceOrMixin
         */
        switch tokens.removeFirst() {
        case .terminal(.callback):
            return try parseCallbackRestOrInterface(extendedAttributeList: extendedAttributeList)

        case .terminal(.interface):
            return try parseInterfaceOrMixin(extendedAttributeList: extendedAttributeList)

        case let t:
            try unexpected(t)
        }
    }

    func unwrap<Type>(_ input: Type?) throws -> Type {

        guard let input = input else {
            fatalError("Unexpected end of input!")
        }
        return input
    }

    func unexpected<Type>(_ input: Type) throws -> Never {
        fatalError("Unexpected Token: \(input)")
    }

    func parseInterfaceOrMixin(extendedAttributeList: ExtendedAttributeList) throws -> Definition {

        /*
         InterfaceOrMixin ::
         InterfaceRest
         MixinRest
         */
        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .InterfaceRest).contains(t):
            return try parseInterfaceRest(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .MixinRest).contains(t):
            return try parseMixinRest(extendedAttributeList: extendedAttributeList)

        case let t:
            try unexpected(t)
        }
    }

    func parseInterfaceRest(extendedAttributeList: ExtendedAttributeList) throws -> Interface {

        let identifier = try parseIdentifier()
        let inheritance = try parseInheritance()
        expect(next: .terminal(.openingCurlyBraces))
        let interfaceMembers = try parseInterfaceMembers()
        expect(next: .terminal(.closingCurlyBraces))
        expect(next: .terminal(.semicolon))

        return Interface(identifier: identifier, extendedAttributeList: extendedAttributeList, inheritance: inheritance, members: interfaceMembers)
    }

    func parseExtendedAttributeList() throws -> ExtendedAttributeList {

        /*
         ExtendedAttributeList ::
         [ ExtendedAttribute ExtendedAttributes ]
         ε
         */
        guard check(forNext: .terminal(.openingSquareBracket)) else {
            return []
        }

        let extendedAttribute = try parseExtendedAttribute()

        let list = try [extendedAttribute] + parseExtendedAttributes()

        expect(next: .terminal(.closingSquareBracket))

        return list
    }

    func parseExtendedAttribute() throws -> ExtendedAttribute {

        //        /*
        //         ExtendedAttribute ::
        //            ( ExtendedAttributeInner ) ExtendedAttributeRest
        //            [ ExtendedAttributeInner ] ExtendedAttributeRest
        //            { ExtendedAttributeInner } ExtendedAttributeRest
        //            Other ExtendedAttributeRest
        //         */
        //
        //        switch try unwrap(tokens.first) {
        //        case .terminal(.openingParenthesis):
        //            expect(next: .terminal(.openingParenthesis))
        //            try parseExtendedAttributeInner()
        //            expect(next: .terminal(.closingParenthesis))
        //            try parseExtendedAttributeRest()
        //
        //        case .terminal(.openingSquareBracket):
        //            expect(next: .terminal(.openingSquareBracket))
        //            try parseExtendedAttributeInner()
        //            expect(next: .terminal(.closingSquareBracket))
        //            try parseExtendedAttributeRest()
        //
        //        case .terminal(.openingCurlyBraces):
        //            expect(next: .terminal(.openingCurlyBraces))
        //            try parseExtendedAttributeInner()
        //            expect(next: .terminal(.closingCurlyBraces))
        //            try parseExtendedAttributeRest()
        //
        //        case let t where firstSet(for: .Other).contains(t):
        //            try parseOther()
        //            try parseExtendedAttributeRest()
        //
        //        case let t:
        //            try unexpected(t)
        //        }
        //

        // Workaround for [Default] being tokenized to .nonTerminal(.Default) instead of .identifier
        let identifier: String
        switch try unwrap(tokens.first) {
        case .identifier:
            tokens.removeFirst()
            identifier = identifiers.removeFirst()

        case .nonTerminal(.Default):
            tokens.removeFirst()
            identifier = "Default"

        case let t:
            try unexpected(t)
        }

        switch try unwrap(tokens.first) {
        case .terminal(.openingParenthesis):
            return try parseExtendedAttributeArgList(withIdentifier: identifier)

        case .terminal(.equalSign):
            return try parseExtendedAttributeIntermediate(withIdentifier: identifier)

        case .terminal(.comma), .terminal(.closingSquareBracket):
            return try parseExtendedAttributeNoArgs(withIdentifier: identifier)

        case let t:
            try unexpected(t)
        }
    }

    func parseExtendedAttributeNoArgs(withIdentifier identifier: String) throws -> ExtendedAttribute {
        /*
         ExtendedAttributeNoArgs ::
         identifier
         */
        return .single(identifier)
    }

    func parseExtendedAttributeArgList(withIdentifier identifier: String) throws -> ExtendedAttribute {
        /*
         ExtendedAttributeArgList ::
         identifier ( ArgumentList )
         */
        expect(next: .terminal(.openingParenthesis))
        let argumentList = try parseArgumentList()
        expect(next: .terminal(.closingParenthesis))

        return .argumentList(identifier, argumentList)
    }

    func parseExtendedAttributeIntermediate(withIdentifier identifier: String) throws -> ExtendedAttribute {

        expect(next: .terminal(.equalSign))

        switch try unwrap(tokens.first) {
        case .terminal(.openingParenthesis):
            return try parseExtendedAttributeIdentList(withIdentifier: identifier)

        case .identifier:
            return try parseExtendedAttributeIntermediateWithIdentifierPrefix(withIdentifier: identifier)

        case let t:
            try unexpected(t)
        }
    }

    func parseExtendedAttributeIntermediateWithIdentifierPrefix(withIdentifier identifier: String) throws -> ExtendedAttribute {

        let otherIdentifier = try parseIdentifier()

        if case .terminal(.openingParenthesis) = try unwrap(tokens.first) {
            return try parseExtendedAttributeNamedArgList(withIdentifier: identifier, otherIdentifier: otherIdentifier)
        } else {
            return try parseExtendedAttributeIdent(withIdentifier: identifier, otherIdentifier: otherIdentifier)
        }
    }

    func parseExtendedAttributeIdent(withIdentifier identifier: String, otherIdentifier: String) throws -> ExtendedAttribute {
        /*
         ExtendedAttributeIdent ::
         identifier = identifier
         */

        return .identifier(identifier, otherIdentifier)
    }

    func parseExtendedAttributeIdentList(withIdentifier identifier: String) throws -> ExtendedAttribute {
        /*
         ExtendedAttributeIdentList ::
         identifier = ( IdentifierList )
         */
        expect(next: .terminal(.openingParenthesis))
        let identifierList = try parseIdentifierList()
        expect(next: .terminal(.closingParenthesis))

        return .identifierList(identifier, identifierList)
    }

    func parseExtendedAttributeNamedArgList(withIdentifier identifier: String, otherIdentifier: String) throws -> ExtendedAttribute {
        /*
         ExtendedAttributeNamedArgList ::
         identifier = identifier ( ArgumentList )
         */

        expect(next: .terminal(.openingParenthesis))
        let argumentList = try parseArgumentList()
        expect(next: .terminal(.closingParenthesis))

        return .namedArgumentList(identifier, otherIdentifier, argumentList)
    }

    func parseExtendedAttributes() throws -> [ExtendedAttribute] {

        /*
         ExtendedAttributes ::
         , ExtendedAttribute ExtendedAttributes
         ε
         */
        guard check(forNext: .terminal(.comma)) else {
            return []
        }

        let extendedAttribute = try parseExtendedAttribute()
        return try [extendedAttribute] + parseExtendedAttributes()
    }

//    func parseExtendedAttributeRest() throws -> ExtendedAttribute? {
//        /*
//         ExtendedAttributeRest ::
//         ExtendedAttribute
//         ε
//         */
//
//        if let nextCharacter = tokens.first,
//            firstSet(for: .ExtendedAttribute).contains(nextCharacter) {
//            return try parseExtendedAttribute()
//        }
//
//        return nil
//    }

//    func parseExtendedAttributeInner() throws -> ExtendedAttribute? {
//        /*
//         ExtendedAttributeInner ::
//         ( ExtendedAttributeInner ) ExtendedAttributeInner
//         [ ExtendedAttributeInner ] ExtendedAttributeInner
//         { ExtendedAttributeInner } ExtendedAttributeInner
//         OtherOrComma ExtendedAttributeInner
//         ε
//         */
//
//        switch try unwrap(tokens.first) {
//        case .terminal(.openingParenthesis):
//            expect(next: .terminal(.openingParenthesis))
//            let inner0 = try parseExtendedAttributeInner()
//            expect(next: .terminal(.closingParenthesis))
//            let inner1 = try parseExtendedAttributeInner()
//            // TODO:
//            return nil
//
//        case .terminal(.openingSquareBracket):
//            expect(next: .terminal(.openingSquareBracket))
//            let inner0 = try parseExtendedAttributeInner()
//            expect(next: .terminal(.closingSquareBracket))
//            let inner1 = try parseExtendedAttributeInner()
//            // TODO:
//            return nil
//
//        case .terminal(.openingCurlyBraces):
//            expect(next: .terminal(.openingCurlyBraces))
//            let inner0 = try parseExtendedAttributeInner()
//            expect(next: .terminal(.closingCurlyBraces))
//            let inner1 = try parseExtendedAttributeInner()
//            // TODO:
//            return nil
//
//        case let t where firstSet(for: .OtherOrComma).contains(t):
//            try parseOtherOrComma()
//            try parseExtendedAttributeInner()
//
//        default:
//            return nil
//        }
//
//        return nil
//    }

    func parseIdentifierList() throws -> [String] {

        /*
         IdentifierList ::
         identifier Identifiers
         */

        let identifier = try parseIdentifier()

        return try [identifier] + parseIdentifiers()
    }

    func parseIdentifiers() throws -> [String] {
        /*
         Identifiers ::
         , identifier Identifiers
         ε
         */

        guard check(forNext: .terminal(.comma)) else {
            return []
        }

        let identifier = try parseIdentifier()
        return try [identifier] + parseIdentifiers()
    }

//    func parseOther() throws -> Void {
//
//        // TODO;
//
//
//        switch try unwrap(tokens.first) {
//        case .identifier:
//            identifiers.removeFirst()
//
//        case .integer:
//            integers.removeFirst()
//
//        case .decimal:
//            decimals.removeFirst()
//
//        case .string:
//            strings.removeFirst()
//
//        case .other:
//            others.removeFirst()
//
//        default:
//            break
//        }
//
//        tokens.removeFirst()
//    }
//
//    func parseOtherOrComma() throws -> Void {
//        guard check(forNext: .terminal(.comma)) else {
//            return try parseOther()
//        }
//    }

    func parseCallbackRestOrInterface(extendedAttributeList: ExtendedAttributeList) throws -> Definition {

        /*
         CallbackRestOrInterface ::
         CallbackRest
         interface identifier { CallbackInterfaceMembers } ;
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .CallbackRest).contains(t):
            return try parseCallbackRest(extendedAttributeList: extendedAttributeList)

        case .terminal(.interface):
            expect(next: .terminal(.interface))
            let identifer = try parseIdentifier()
            expect(next: .terminal(.openingCurlyBraces))
            let callbackInterfaceMembers = try parseCallbackInterfaceMembers()
            expect(next: .terminal(.closingCurlyBraces))
            expect(next: .terminal(.semicolon))
            return CallbackInterface(identifer: identifer, extendedAttributeList: extendedAttributeList, callbackInterfaceMembers: callbackInterfaceMembers)

        case let t:
            try unexpected(t)
        }
    }

    func parseCallbackRest(extendedAttributeList: ExtendedAttributeList) throws -> Callback {

        let identifier = try parseIdentifier()
        expect(next: .terminal(.equalSign))
        let returnType = try parseReturnType()
        expect(next: .terminal(.openingParenthesis))
        let argumentList = try parseArgumentList()
        expect(next: .terminal(.closingParenthesis))
        expect(next: .terminal(.semicolon))

        return Callback(identifier: identifier, extendedAttributeList: extendedAttributeList, returnType: returnType, argumentList: argumentList)
    }

    func parseCallbackInterfaceMembers() throws -> [CallbackInterfaceMember] {

        /*
         CallbackInterfaceMembers ::
         ExtendedAttributeList CallbackInterfaceMember CallbackInterfaceMembers
         ε
         */

        guard union(firstSet(for: .ExtendedAttributeList), firstSet(for: .CallbackInterfaceMember)).contains(try unwrap(tokens.first)) else {
            return []
        }
        let extendedAttributeList = try parseExtendedAttributeList()
        return try [parseCallbackInterfaceMember(extendedAttributeList: extendedAttributeList)] + parseCallbackInterfaceMembers()
    }

    func parseCallbackInterfaceMember(extendedAttributeList: ExtendedAttributeList) throws -> CallbackInterfaceMember {

        /*
         CallbackInterfaceMember ::
         Const
         RegularOperation
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .Const).contains(t):
            let const = try parseConst()
            return .const(const, extendedAttributeList)

        case let t where firstSet(for: .RegularOperation).contains(t):
            let regularOperation = try parseRegularOperation()
            return .regularOperation(regularOperation, extendedAttributeList)

        case let t:
            try unexpected(t)
        }
    }

    func parseMixinRest(extendedAttributeList: ExtendedAttributeList) throws -> Mixin {

        /*
         MixinRest ::
         mixin identifier { MixinMembers } ;
         */
        expect(next: .terminal(.mixin))
        let identifer = try parseIdentifier()
        expect(next: .terminal(.openingCurlyBraces))
        let mixinMembers = try parseMixinMembers()
        expect(next: .terminal(.closingCurlyBraces))
        expect(next: .terminal(.semicolon))
        return Mixin(identifier: identifer, extendedAttributeList: extendedAttributeList, members: mixinMembers)
    }

    func parseMixinMembers() throws -> [MixinMember] {

        /*
        MixinMembers ::
            ExtendedAttributeList MixinMember MixinMembers
            ε
         */
        guard union(firstSet(for: .ExtendedAttributeList), firstSet(for: .MixinMember)).contains(try unwrap(tokens.first)) else {
            return []
        }

        let extendedAttributeList = try parseExtendedAttributeList()
        return try [parseMixinMember(extendedAttributeList: extendedAttributeList)] + parseMixinMembers()
    }

    func parseMixinMember(extendedAttributeList: ExtendedAttributeList) throws -> MixinMember {

        /*
         MixinMember ::
             Const
             RegularOperation
             Stringifier
             ReadOnly AttributeRest
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .Const).contains(t):
            return .const(try parseConst(), extendedAttributeList)

        case let t where firstSet(for: .RegularOperation).contains(t):
            return .regularOperation(try parseRegularOperation(), extendedAttributeList)

        case let t where firstSet(for: .Stringifier).contains(t):
            return .stringifier(try parseStringifier(), extendedAttributeList)

        case let t where union(firstSet(for: .ReadOnly), firstSet(for: .AttributeRest)).contains(t):
            return .readOnlyAttributeRest(try parseReadOnly(), try parseAttributeRest(), extendedAttributeList)

        case let t:
            try unexpected(t)
        }
    }

    func parseInheritance() throws -> Inheritance? {

        guard check(forNext: .terminal(.colon)) else {
            return nil
        }
        let identifier = try parseIdentifier()
        return Inheritance(identifier: identifier)
    }

    func parseInterfaceMembers() throws -> [InterfaceMember] {

        guard union(firstSet(for: .ExtendedAttributeList), firstSet(for: .InterfaceMember)).contains(try unwrap(tokens.first)) else {
            return []
        }

        let extendedAttributeList = try parseExtendedAttributeList()

        return try [parseInterfaceMember(extendedAttributeList: extendedAttributeList)] + parseInterfaceMembers()
    }

    func parseInterfaceMember(extendedAttributeList: ExtendedAttributeList) throws -> InterfaceMember {

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .PartialInterfaceMember).contains(t):
            return try parsePartialInterfaceMember(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .Constructor).contains(t):
            return try parseConstructor(extendedAttributeList: extendedAttributeList)

        case let t:
            try unexpected(t)
        }
    }

    func parsePartialInterfaceMembers() throws -> [InterfaceMember] {
        /*
        PartialInterfaceMembers ::
            ExtendedAttributeList PartialInterfaceMember PartialInterfaceMembers
            ε
         */

        guard union(firstSet(for: .ExtendedAttributeList), firstSet(for: .PartialInterfaceMember)).contains(try unwrap(tokens.first)) else {
            return []
        }
        let extendedAttributeList = try parseExtendedAttributeList()
        let partialInterfaceMember = try parsePartialInterfaceMember(extendedAttributeList: extendedAttributeList)
        return try [partialInterfaceMember] + parsePartialInterfaceMembers()
    }

    func parsePartialInterfaceMember(extendedAttributeList: ExtendedAttributeList) throws -> InterfaceMember {
        /*
        PartialInterfaceMember ::
            Const
            Operation
            Stringifier
            StaticMember
            Iterable
            AsyncIterable
            ReadOnlyMember
            ReadWriteAttribute
            ReadWriteMaplike
            ReadWriteSetlike
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .Const).contains(t):
            return .const(try parseConst(), extendedAttributeList)

        case let t where firstSet(for: .Operation).contains(t):
            return try parseOperation(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .Stringifier).contains(t):
            return .stringifier(try parseStringifier(), extendedAttributeList)

        case let t where firstSet(for: .StaticMember).contains(t):
            return .staticMember(try parseStaticMember(), extendedAttributeList)

        case let t where firstSet(for: .Iterable).contains(t):
            return .iterable(try parseIterable(), extendedAttributeList)

        case let t where firstSet(for: .AsyncIterable).contains(t):
            return .asyncIterable(try parseAsyncIterable(), extendedAttributeList)

        case let t where firstSet(for: .ReadOnlyMember).contains(t):
            return try parseReadOnlyMember(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .ReadWriteAttribute).contains(t):
            return try parseReadWriteAttribute(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .ReadWriteMaplike).contains(t):
            return .readWriteMaplike(try parseReadWriteMaplike(), extendedAttributeList)

        case let t where firstSet(for: .ReadWriteSetlike).contains(t):
            return .readWriteSetlike(try parseReadWriteSetlike(), extendedAttributeList)

        case let t:
            try unexpected(t)
        }
    }

    func parseOperation(extendedAttributeList: ExtendedAttributeList) throws -> InterfaceMember {

        /*
         Operation ::
         RegularOperation
         SpecialOperation
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .RegularOperation).contains(t):
            let regularOperation = try parseRegularOperation()
            return .operation(.regular(regularOperation), extendedAttributeList)

        case let t where firstSet(for: .SpecialOperation).contains(t):
            let specialOperation = try parseSpecialOperation()
            return .operation(specialOperation, extendedAttributeList)

        case let t:
            try unexpected(t)
        }
    }

    func parseRegularOperation() throws -> RegularOperation {

        /*
         RegularOperation ::
         ReturnType OperationRest
         */

        let returnType = try parseReturnType()
        let operationRest = try parseOperationRest()

        return RegularOperation(returnType: returnType, operationName: operationRest.optioalOperationName, argumentList: operationRest.argumentList)
    }

    func parseOperationRest() throws -> OperationRest {

        let name = try parseOptionalOperationName()
        expect(next: .terminal(.openingParenthesis))
        let arguments = try parseArgumentList()
        expect(next: .terminal(.closingParenthesis))
        expect(next: .terminal(.semicolon))

        return OperationRest(optioalOperationName: name, argumentList: arguments)
    }

    func parseOptionalOperationName() throws -> OperationName? {

        /*
         OptionalOperationName ::
         OperationName
         ε
         */

        let next = try unwrap(tokens.first)
        guard firstSet(for: .OperationName).contains(next) else {
            return nil
        }
        return try parseOperationName()
    }

    func parseOperationName() throws -> OperationName {

        /*
         OperationName ::
         OperationNameKeyword
         identifier
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .OperationNameKeyword).contains(t):
            return try parseOperationNameKeyword()

        case .identifier:
            return .identifier(try parseIdentifier())

        case let t:
            try unexpected(t)
        }
    }

    func parseOperationNameKeyword() throws -> OperationName {

        /*
         OperationNameKeyword ::
         includes
         */

        expect(next: .terminal(.includes))
        return .includes
    }

    func parseSpecialOperation() throws -> Operation {

        let special = try parseSpecial()
        let regularOperation = try parseRegularOperation()

        return .special(special, regularOperation)
    }

    func parseSpecial() throws -> Special {

        /*
         Special ::
         getter
         setter
         deleter
         */
        switch try unwrap(tokens.first) {
        case .terminal(.getter):
            tokens.removeFirst()
            return .getter

        case .terminal(.setter):
            tokens.removeFirst()
            return .setter

        case .terminal(.deleter):
            tokens.removeFirst()
            return .deleter

        case let t:
            try unexpected(t)
        }
    }

    func parseStringifier() throws -> Stringifier {

        /*
         Stringifier ::
             stringifier StringifierRest
         */

        expect(next: .terminal(.stringifier))
        return try parseStringifierRest()
    }

    func parseStringifierRest() throws -> Stringifier {
        /*
         StringifierRest ::
         ReadOnly AttributeRest
         RegularOperation
         ;
         */

        switch try unwrap(tokens.first) {
        case let t where union(firstSet(for: .ReadOnly), firstSet(for: .AttributeRest)).contains(t):
            let readOnly = try parseReadOnly()
            let attributeRest = try parseAttributeRest()
            return .readOnlyAttributeRest(readOnly, attributeRest.typeWithExtendedAttributes, attributeRest.attributeName)

        case let t where firstSet(for: .RegularOperation).contains(t):
            let regularOperation = try parseRegularOperation()
            return .regular(regularOperation)

        case .terminal(.semicolon):
            tokens.removeFirst()
            return .empty

        case let t:
            try unexpected(t)
        }
    }

    func parseReadOnly() throws -> Bool {

        /*
         ReadOnly ::
         readonly
         ε
         */

        return check(forNext: .terminal(.readonly))
    }

    func parseAttributeRest() throws -> AttributeRest {

        /*
         attribute TypeWithExtendedAttributes AttributeName ;
         */

        expect(next: .terminal(.attribute))
        let typeWithExtendedAttributes = try parseTypeWithExtendedAttributes()
        let attributeName = try parseAttributeName()
        expect(next: .terminal(.semicolon))
        return AttributeRest(typeWithExtendedAttributes: typeWithExtendedAttributes, attributeName: attributeName)
    }

    func parseAttributeName() throws -> AttributeName {

        /*
         AttributeName ::
         AttributeNameKeyword
         identifier
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .AttributeNameKeyword).contains(t):
            return .attributeNameKeyword(try parseAttributeNameKeyword())

        case .identifier:
            return .identifier(try parseIdentifier())

        case let t:
            try unexpected(t)
        }
    }

    func parseAttributeNameKeyword() throws -> AttributeNameKeyword {

        /*
         AttributeNameKeyword ::
         async
         required
         */

        switch try unwrap(tokens.first) {
        case .terminal(.async):
            tokens.removeFirst()
            return .async

        case .terminal(.required):
            tokens.removeFirst()
            return .required

        case let t:
            try unexpected(t)
        }
    }

    func parseStaticMember() throws -> StaticMember {

        /*
         StaticMember ::
         static StaticMemberRest
         */
        expect(next: .terminal(.static))
        return try parseStaticMemberRest()
    }

    func parseStaticMemberRest() throws -> StaticMember {
        /*
         StaticMemberRest ::
         ReadOnly AttributeRest
         RegularOperation
         */

        switch try unwrap(tokens.first) {
        case let t where union(firstSet(for: .ReadOnly), firstSet(for: .AttributeRest)).contains(t):
            return .readOnlyAttributeRest(try parseReadOnly(), try parseAttributeRest())

        case let t where firstSet(for: .RegularOperation).contains(t):
            return .regularOperation(try parseRegularOperation())

        case let t:
            try unexpected(t)
        }
    }

    func parseIterable() throws -> Iterable {

        /*
         Iterable ::
         iterable < TypeWithExtendedAttributes OptionalType > ;
         */
        expect(next: .terminal(.iterable))
        expect(next: .terminal(.openingAngleBracket))
        let typeWithExtendedAttributes0 = try parseTypeWithExtendedAttributes()
        let optionalType = try parseOptionalType()
        expect(next: .terminal(.closingAngleBracket))
        expect(next: .terminal(.semicolon))

        return Iterable(typeWithExtendedAttributes0: typeWithExtendedAttributes0, typeWithExtendedAttributes1: optionalType)
    }

    func parseOptionalType() throws -> TypeWithExtendedAttributes? {

        /*
         OptionalType ::
         , TypeWithExtendedAttributes
         ε
         */
        guard check(forNext: .terminal(.comma)) else {
            return nil
        }
        return try parseTypeWithExtendedAttributes()
    }

    func parseAsyncIterable() throws -> AsyncIterable {

        /*
         AsyncIterable ::
         async iterable < TypeWithExtendedAttributes , TypeWithExtendedAttributes > ;
         */
        expect(next: .terminal(.async))
        expect(next: .terminal(.iterable))
        expect(next: .terminal(.openingAngleBracket))
        let typeWithExtendedAttributes0 = try parseTypeWithExtendedAttributes()
        expect(next: .terminal(.comma))
        let typeWithExtendedAttribute1 = try parseTypeWithExtendedAttributes()
        expect(next: .terminal(.closingAngleBracket))
        expect(next: .terminal(.semicolon))

        return AsyncIterable(typeWithExtendedAttributes0: typeWithExtendedAttributes0, typeWithExtendedAttributes1: typeWithExtendedAttribute1)
    }

    func parseReadOnlyMember(extendedAttributeList: ExtendedAttributeList) throws -> InterfaceMember {

        expect(next: .terminal(.readonly))
        let readOnlyMember = try parseReadOnlyMemberRest()
        return .readOnlyMember(readOnlyMember, extendedAttributeList)
    }

    func parseReadOnlyMemberRest() throws -> ReadOnlyMember {

        /*
         ReadOnlyMemberRest ::
         AttributeRest
         MaplikeRest
         SetlikeRest
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .AttributeRest).contains(t):
            return .attribute(try parseAttributeRest())

        case let t where firstSet(for: .MaplikeRest).contains(t):
            return .maplike(try parseMaplikeRest())

        case let t where firstSet(for: .SetlikeRest).contains(t):
            return .setlike(try parseSetlikeRest())

        case let t:
            try unexpected(t)
        }
    }

    func parseMaplikeRest() throws -> MaplikeRest {

        /*
         MaplikeRest ::
         maplike < TypeWithExtendedAttributes , TypeWithExtendedAttributes > ;
         */
        expect(next: .terminal(.maplike))
        expect(next: .terminal(.openingAngleBracket))
        let keyType = try parseTypeWithExtendedAttributes()
        expect(next: .terminal(.comma))
        let valueType = try parseTypeWithExtendedAttributes()
        expect(next: .terminal(.closingAngleBracket))
        expect(next: .terminal(.semicolon))
        return MaplikeRest(keyType: keyType, valueType: valueType)
    }

    func parseSetlikeRest() throws -> SetlikeRest {

        /*
         SetlikeRest ::
         setlike < TypeWithExtendedAttributes > ;
         */
        expect(next: .terminal(.setlike))
        expect(next: .terminal(.openingAngleBracket))
        let typeWithExtendedAttributes = try parseTypeWithExtendedAttributes()
        expect(next: .terminal(.closingAngleBracket))
        expect(next: .terminal(.semicolon))

        return SetlikeRest(dataType: typeWithExtendedAttributes)
    }

    func parseReadWriteAttribute(extendedAttributeList: ExtendedAttributeList) throws -> InterfaceMember {

        guard check(forNext: .terminal(.inherit)) else {
            let attributeRest = try parseAttributeRest()
            return .readWriteAttribute(.notInherit(attributeRest), extendedAttributeList)
        }

        let attributeRest = try parseAttributeRest()
        return .readWriteAttribute(.inherit(attributeRest), extendedAttributeList)
    }

    func parseReadWriteMaplike() throws -> ReadWriteMaplike {

        return ReadWriteMaplike(maplike: try parseMaplikeRest())
    }

    func parseReadWriteSetlike() throws -> ReadWriteSetlike {

        return ReadWriteSetlike(setlike: try parseSetlikeRest())
    }

    func parseIdentifier() throws -> String {

        expect(next: .identifier)
        return identifiers.removeFirst()
    }

    func parseConst() throws -> Const {

        expect(next: .terminal(.const))
        let constType = try parseConstType()
        let identifier = try parseIdentifier()
        expect(next: .terminal(.equalSign))
        let constValue = try parseConstValue()
        expect(next: .terminal(.semicolon))
        return Const(identifier: identifier, constType: constType, constValue: constValue)
    }

    func parseConstType() throws -> ConstType {

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .PrimitiveType).contains(t):
            return .primitiveType(try parsePrimitiveType())

        case .identifier:
            expect(next: .identifier)
            return .identifier(identifiers.removeFirst())

        case let t:
            try unexpected(t)
        }
    }

    func parseConstructor(extendedAttributeList: ExtendedAttributeList) throws -> InterfaceMember {

        expect(next: .terminal(.constructor))
        expect(next: .terminal(.openingParenthesis))
        let arguments = try parseArgumentList()
        expect(next: .terminal(.closingParenthesis))
        expect(next: .terminal(.semicolon))
        return .constructor(arguments, extendedAttributeList)
    }

    func parseArgumentList() throws -> [Argument] {

        guard try firstSet(for: .Argument).contains(unwrap(tokens.first)) else {
            return []
        }

        let argument = try parseArgument()
        return try [argument] + parseArguments()
    }

    func parseArguments() throws -> [Argument] {

        guard check(forNext: .terminal(.comma)) else {
            return []
        }

        let argument = try parseArgument()
        return try [argument] + parseArguments()
    }

    func parseArgument() throws -> Argument {

        let extendedAttributeList = try parseExtendedAttributeList()

        let argumentRest = try parseArgumentRest()
        return Argument(rest: argumentRest, extendedAttributeList: extendedAttributeList)
    }

    func parseArgumentRest() throws -> ArgumentRest {

        /*
         ArgumentRest ::
         optional TypeWithExtendedAttributes ArgumentName Default
         Type Ellipsis ArgumentName
         */
        switch try unwrap(tokens.first) {
        case .terminal(.optional):
            expect(next: .terminal(.optional))
            let typeWithExtendedAttributes = try parseTypeWithExtendedAttributes()
            let argumentName = try parseArgumentName()
            let defaultValue = try parseDefault()
            return .optional(typeWithExtendedAttributes, argumentName, defaultValue)

        case let t where firstSet(for: .Type).contains(t):
            let dataType = try parseType()
            let ellipsis = try parseEllipsis()
            let argumentName = try parseArgumentName()
            return .nonOptional(dataType, ellipsis, argumentName)

        case let t:
            try unexpected(t)

        }
    }

    func parseArgumentName() throws -> ArgumentName {

        /*
         ArgumentName ::
         ArgumentNameKeyword
         identifier
         */
        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .ArgumentNameKeyword).contains(t):
            return .argumentNameKeyword(try parseArgumentNameKeyword())

        case .identifier:
            return .identifier(try parseIdentifier())

        case let t:
            try unexpected(t)

        }
    }

    func parseEllipsis() throws -> Bool {

        /*
         Ellipsis ::
         ...
         ε
         */

        return check(forNext: .terminal(.ellipsis))
    }

    func parseDefault() throws -> DefaultValue? {

        guard check(forNext: .terminal(.equalSign)) else {
            return nil
        }

        return try parseDefaultValue()
    }

    func parseDefaultValue() throws -> DefaultValue {
        /*
         DefaultValue ::
             ConstValue
             string
             [ ]
             { }
             null
         */

        switch try unwrap(tokens.first) {
        case .string:
            expect(next: .string)
            return .string(strings.removeFirst())

        case .terminal(.null):
            expect(next: .terminal(.null))
            return .null

        case .terminal(.openingSquareBracket):
            expect(next: .terminal(.openingSquareBracket))
            expect(next: .terminal(.closingSquareBracket))
            return .emptyList

        case .terminal(.openingCurlyBraces):
            expect(next: .terminal(.openingCurlyBraces))
            expect(next: .terminal(.closingCurlyBraces))
            return .emptyDictionary

        case let t where firstSet(for: .ConstValue).contains(t):
            return .constValue(try parseConstValue())

        case let t:
            try unexpected(t)
        }
    }

    func parseConstValue() throws -> ConstValue {

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .BooleanLiteral).contains(t):
            return .booleanLiteral(try parseBooleanLiteral())

        case let t where firstSet(for: .FloatLiteral).contains(t):
            return .floatLiteral(try parseFloatLiteral())

        case .integer:
            expect(next: .integer)
            return .integer(integers.removeFirst())

        case let t:
            try unexpected(t)
        }
    }

    func parseBooleanLiteral() throws -> Bool {

        switch try unwrap(tokens.first) {
        case .terminal(.true):
            expect(next: .terminal(.true))
            return true

        case .terminal(.false):
            expect(next: .terminal(.false))
            return false

        case let t:
            try unexpected(t)
        }
    }

    func parseFloatLiteral() throws -> FloatLiteral {

        switch try unwrap(tokens.first) {

        case .decimal:
            expect(next: .decimal)
            return .decimal(decimals.removeFirst())

        case .terminal(.negativeInfinity):
            expect(next: .terminal(.negativeInfinity))
            return .negativeInfinity

        case .terminal(.infinity):
            expect(next: .terminal(.infinity))
            return .infinity

        case .terminal(.nan):
        expect(next: .terminal(.nan))
        return .notANumber
            
        case let t:
            try unexpected(t)
        }
    }

    func parseNamespace(extendedAttributeList: ExtendedAttributeList) throws -> Namespace {

        /*
         Namespace ::
             namespace identifier { NamespaceMembers } ;
         */

        expect(next: .terminal(.namespace))
        let identifier = try parseIdentifier()
        expect(next: .terminal(.openingCurlyBraces))
        let namespaceMembers = try parseNamespaceMembers()
        expect(next: .terminal(.closingCurlyBraces))
        expect(next: .terminal(.semicolon))

        return Namespace(identifier: identifier, extendedAttributeList: extendedAttributeList, namespaceMembers: namespaceMembers)
    }

    func parseNamespaceMembers() throws -> [NamespaceMember] {

        /*
         NamespaceMembers ::
             ExtendedAttributeList NamespaceMember NamespaceMembers
             ε
         */

        guard union(firstSet(for: .ExtendedAttributeList), firstSet(for: .NamespaceMember)).contains(try unwrap(tokens.first)) else {
            return []
        }
        let extendedAttributeList = try parseExtendedAttributeList()

        return try [parseNamespaceMember(extendedAttributeList: extendedAttributeList)] + parseNamespaceMembers()
    }

    func parseNamespaceMember(extendedAttributeList: ExtendedAttributeList) throws -> NamespaceMember {

        /*
         NamespaceMember ::
             RegularOperation
             readonly AttributeRest
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .RegularOperation).contains(t):
            return .regularOperation(try parseRegularOperation(), extendedAttributeList)

        case .terminal(.readonly):
            return .readonlyAttribute(try parseAttributeRest())

        case let t:
            try unexpected(t)
        }
    }

    func parsePartial(extendedAttributeList: ExtendedAttributeList) throws -> Partial {

        /*
         Partial ::
         partial PartialDefinition
         */
        expect(next: .terminal(.partial))

        return try parsePartialDefinition(extendedAttributeList: extendedAttributeList)
    }

    func parsePartialDefinition(extendedAttributeList: ExtendedAttributeList) throws -> Partial {

        /*
        PartialDefinition ::
        interface PartialInterfaceOrPartialMixin
        PartialDictionary
        Namespace
        */
        switch try unwrap(tokens.first) {
        case .terminal(.interface):
            expect(next: .terminal(.interface))
            return try parsePartialInterfaceOrPartialMixin(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .PartialDictionary).contains(t):
            return .dictionary(try parsePartialDictionary(), extendedAttributeList)

        case let t where firstSet(for: .Namespace).contains(t):
            return .namespace(try parseNamespace(extendedAttributeList: []), extendedAttributeList)

        case let t:
            try unexpected(t)
        }
    }

    func parsePartialInterfaceOrPartialMixin(extendedAttributeList: ExtendedAttributeList) throws -> Partial {

        /*
         PartialInterfaceOrPartialMixin ::
         PartialInterfaceRest
         MixinRest

         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .PartialInterfaceRest).contains(t):
            return try parsePartialInterfaceRest(extendedAttributeList: extendedAttributeList)

        case let t where firstSet(for: .MixinRest).contains(t):
            let mixinRest = try parseMixinRest(extendedAttributeList: [])
            return .mixin(mixinRest, extendedAttributeList)


        case let t:
            try unexpected(t)
        }
    }

    func parsePartialInterfaceRest(extendedAttributeList: ExtendedAttributeList) throws -> Partial {

        /*
         PartialInterfaceRest ::
         identifier { PartialInterfaceMembers } ;
         */

        let identifier = try parseIdentifier()
        expect(next: .terminal(.openingCurlyBraces))
        let partialInterfaceMembers = try parsePartialInterfaceMembers()
        expect(next: .terminal(.closingCurlyBraces))
        expect(next: .terminal(.semicolon))

        return .interface(Interface(identifier: identifier, extendedAttributeList: [], inheritance: nil, members: partialInterfaceMembers), extendedAttributeList)
    }

    func parsePartialDictionary() throws -> Dictionary {

        /*
         PartialDictionary ::
         dictionary identifier { DictionaryMembers } ;
         */
        expect(next: .terminal(.dictionary))
        let identifier = try parseIdentifier()
        expect(next: .terminal(.openingCurlyBraces))
        let dictionaryMembers = try parseDictionaryMembers()
        expect(next: .terminal(.closingCurlyBraces))
        expect(next: .terminal(.semicolon))

        return Dictionary(identifier: identifier, extendedAttributeList: [], inheritance: nil, members: dictionaryMembers)
    }

    func parseDictionary(extendedAttributeList: ExtendedAttributeList) throws -> Dictionary {

        /*
         Dictionary ::
         dictionary identifier Inheritance { DictionaryMembers } ;
         */

        expect(next: .terminal(.dictionary))
        let identifier = try parseIdentifier()
        let inheritance = try parseInheritance()
        expect(next: .terminal(.openingCurlyBraces))
        let dictionaryMembers = try parseDictionaryMembers()
        expect(next: .terminal(.closingCurlyBraces))
        expect(next: .terminal(.semicolon))

        return Dictionary(identifier: identifier, extendedAttributeList: extendedAttributeList, inheritance: inheritance, members: dictionaryMembers)
    }

    func parseDictionaryMember() throws -> DictionaryMember {

        let extendedAttributeList = try parseExtendedAttributeList()
        return try parseDictionaryMemberRest(extendedAttributeList: extendedAttributeList)
    }

    func parseDictionaryMembers() throws -> [DictionaryMember] {

        guard firstSet(for: .DictionaryMember).contains(try unwrap(tokens.first)) else {
            return []
        }

        return try [parseDictionaryMember()] + parseDictionaryMembers()
    }

    func parseDictionaryMemberRest(extendedAttributeList: ExtendedAttributeList) throws -> DictionaryMember {

        switch try unwrap(tokens.first) {
        case .terminal(.required):
            tokens.removeFirst()
            let typeWithExtendedAttributes = try parseTypeWithExtendedAttributes()
            let identifier = try parseIdentifier()
            expect(next: .terminal(.semicolon))
            return DictionaryMember(identifier: identifier, isRequired: true, extendedAttributeList: extendedAttributeList, dataType: typeWithExtendedAttributes.dataType, extendedAttributesOfDataType: typeWithExtendedAttributes.extendedAttributeList, defaultValue: nil)

        case let t where firstSet(for: .Type).contains(t):
            let dataType = try parseType()
            let identifier = try parseIdentifier()
            let defaultValue = try parseDefault()
            expect(next: .terminal(.semicolon))
            return DictionaryMember(identifier: identifier, isRequired: false, extendedAttributeList: extendedAttributeList, dataType: dataType, extendedAttributesOfDataType: nil, defaultValue: defaultValue)

        case let t:
            try unexpected(t)
        }
    }

    func parseEnum(extendedAttributeList: ExtendedAttributeList) throws -> Definition {

        /*
        Enum ::
        enum identifier { EnumValueList } ;
         */
        expect(next: .terminal(.enum))
        let identifier = try parseIdentifier()
        expect(next: .terminal(.openingCurlyBraces))
        let enumValueList = try parseEnumValueList()
        expect(next: .terminal(.closingCurlyBraces))
        expect(next: .terminal(.semicolon))

        return Enum(identifier: identifier, extendedAttributeList: extendedAttributeList, enumValues: enumValueList)
    }

    func parseEnumValueList() throws -> [EnumValue] {

        /*
         EnumValueList ::
         string EnumValueListComma
         */
        expect(next: .string)
        let string = strings.removeFirst()

        return try [EnumValue(string: string)] + parseEnumValueListComma()
    }

    func parseEnumValueListComma() throws -> [EnumValue] {

        /*
        EnumValueListComma ::
        , EnumValueListString
        ε
         */

        guard check(forNext: .terminal(.comma)) else {
            return []
        }

        return try parseEnumValueListString()
    }

    func parseEnumValueListString() throws -> [EnumValue] {
        /*
         EnumValueListString ::
         string EnumValueListComma
         ε
         */

        guard check(forNext: .string) else {
            return []
        }
        return try [EnumValue(string: strings.removeFirst())] + parseEnumValueListComma()
    }

    func parseTypedef(extendedAttributeList: ExtendedAttributeList) throws -> Definition {
        /*
         Typedef ::
         typedef TypeWithExtendedAttributes identifier ;
         */

        expect(next: .terminal(.typedef))
        let typeWithExtendedAttributes = try parseTypeWithExtendedAttributes()
        let identifier = try parseIdentifier()
        expect(next: .terminal(.semicolon))

        return Typedef(identifier: identifier, dataType: typeWithExtendedAttributes.dataType, extendedAttributeList: typeWithExtendedAttributes.extendedAttributeList)
    }

    func parseTypeWithExtendedAttributes() throws -> TypeWithExtendedAttributes{

        /*
         TypeWithExtendedAttributes ::
         ExtendedAttributeList Type
         */

        let extendedAttributeList = try parseExtendedAttributeList()
        let dataType = try parseType()
        return .init(dataType: dataType, extendedAttributeList: extendedAttributeList)
    }

    func parseType() throws -> DataType {

        /*
         Type ::
         SingleType
         UnionType Null
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .SingleType).contains(t):
            return .single(try parseSingleType())

        case let t where firstSet(for: .UnionType).contains(t):
            return .union(try parseUnionType(), try parseNull())

        case let t:
            try unexpected(t)
        }
    }

    func parseSingleType() throws -> SingleType {

        /*
         SingleType ::
         DistinguishableType
         any
         PromiseType
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .DistinguishableType).contains(t):
            let distinguishableType = try parseDistinguishableType()
            return .distinguishableType(distinguishableType)

        case .terminal(.any):
            tokens.removeFirst()
            return .any

        case let t where firstSet(for: .PromiseType).contains(t):
            let promise = try parsePromiseType()
            return .promiseType(promise)

        case let t:
            try unexpected(t)
        }
    }

    func parseUnionType() throws -> [UnionMemberType] {

        /*
         UnionType ::
         ( UnionMemberType or UnionMemberType UnionMemberTypes )
         */

        expect(next: .terminal(.openingParenthesis))
        let unionMemberType0 = try parseUnionMemberType()
        expect(next: .terminal(.or))
        let unionMemberType1 = try parseUnionMemberType()
        let unionMemberTypes = try parseUnionMemberTypes()
        expect(next: .terminal(.closingParenthesis))
        return [unionMemberType0, unionMemberType1] + unionMemberTypes
    }

    func parseUnionMemberType() throws -> UnionMemberType {

        /*
         UnionMemberType ::
         ExtendedAttributeList DistinguishableType
         UnionType Null
         */

        switch try unwrap(tokens.first) {
        case let t where union(firstSet(for: .ExtendedAttributeList), firstSet(for: .DistinguishableType)).contains(t):
            let extendedAttributeList = try parseExtendedAttributeList()
            let distinguishableType = try parseDistinguishableType()
            return .distinguishableType(extendedAttributeList, distinguishableType)

        case let t where firstSet(for: .UnionType).contains(t):
            let unionTypes = try parseUnionType()
            let nullable = try parseNull()
            return .nullableUnionType(unionTypes, nullable)

        case let t:
            try unexpected(t)
        }
    }

    func parseUnionMemberTypes() throws -> [UnionMemberType]  {

        /*
         UnionMemberTypes ::
         or UnionMemberType UnionMemberTypes
         ε
         */

        guard check(forNext: .terminal(.or)) else {
            return []
        }

        return try [parseUnionMemberType()] + parseUnionMemberTypes()
    }

    func parseIncludesStatement(extendedAttributeList: ExtendedAttributeList) throws -> IncludesStatement {
        /*
         IncludesStatement ::
         identifier includes identifier ;
         */

        let child = try parseIdentifier()
        expect(next: .terminal(.includes))
        let parent = try parseIdentifier()
        expect(next: .terminal(.semicolon))

        return IncludesStatement(child: child, parent: parent, extendedAttributeList: extendedAttributeList)
    }

    func parseDistinguishableType() throws -> DistinguishableType {

        /*
         DistinguishableType ::
         PrimitiveType Null
         StringType Null
         identifier Null
         sequence < TypeWithExtendedAttributes > Null
         object Null
         symbol Null
         BufferRelatedType Null
         FrozenArray < TypeWithExtendedAttributes > Null
         RecordType Null
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .PrimitiveType).contains(t):
            let primitiveType = try parsePrimitiveType()
            let nullable = try parseNull()
            return .primitive(primitiveType, nullable)

        case let t where firstSet(for: .StringType).contains(t):
            let stringType = try parseStringType()
            let nullable = try parseNull()
            return .string(stringType, nullable)

        case .identifier:
            let identifier = try parseIdentifier()
            let nullable = try parseNull()
            return .identifier(identifier, nullable)

        case .terminal(.sequence):
            tokens.removeFirst()
            expect(next: .terminal(.openingAngleBracket))
            let typeWithExtendedAttribute = try parseTypeWithExtendedAttributes()
            expect(next: .terminal(.closingAngleBracket))

            let nullable = try parseNull()
            return.sequence(typeWithExtendedAttribute, nullable)

        case .terminal(.object):
            tokens.removeFirst()
            let nullable = try parseNull()
            return .object(nullable)

        case .terminal(.symbol):
            tokens.removeFirst()
            let nullable = try parseNull()
            return .symbol(nullable)

        case let t where firstSet(for: .BufferRelatedType).contains(t):
            let bufferRelatedType = try parseBufferRelatedType()
            let nullable = try parseNull()
            return .bufferRelated(bufferRelatedType, nullable)

        case .terminal(.FrozenArray):
            tokens.removeFirst()
            expect(next: .terminal(.openingAngleBracket))
            let typeWithExtendedAttribute = try parseTypeWithExtendedAttributes()
            expect(next: .terminal(.closingAngleBracket))
            let nullable = try parseNull()
            return .frozenArray(typeWithExtendedAttribute, nullable)

        case let t where firstSet(for: .RecordType).contains(t):
            let recordType = try parseRecordType()
            let nullable = try parseNull()
            return .record(recordType, nullable)

        case let t:
            try unexpected(t)
        }
    }

    func parsePrimitiveType() throws -> PrimitiveType {
        /*
         PrimitiveType ::
         UnsignedIntegerType
         UnrestrictedFloatType
         boolean
         byte
         octet
         */

        switch try unwrap(tokens.first) {
        case let t where firstSet(for: .UnsignedIntegerType).contains(t):
            return .UnsignedIntegerType(try parseUnsignedIntegerType())

        case let t where firstSet(for: .UnrestrictedFloatType).contains(t):
            return .UnrestrictedFloatType(try parseUnrestrictedFloatType())

        case .terminal(.boolean):
            tokens.removeFirst()
            return .boolean

        case .terminal(.byte):
            tokens.removeFirst()
            return .byte

        case .terminal(.octet):
            tokens.removeFirst()
            return .octet

        case let t:
            try unexpected(t)
        }
    }

    func parseUnrestrictedFloatType() throws -> UnrestrictedFloatType {
        /*
         UnrestrictedFloatType ::
         unrestricted FloatType
         FloatType
         */

        guard check(forNext: .terminal(.unrestricted)) else {
            return try .restricted(parseFloatType())
        }
        return try .unrestricted(parseFloatType())
    }

    func parseFloatType() throws -> FloatType {
        /*
         FloatType ::
         float
         double
         */

        switch try unwrap(tokens.first) {
        case .terminal(.float):
            tokens.removeFirst()
            return .float

        case .terminal(.double):
            tokens.removeFirst()
            return .double

        case let t:
            try unexpected(t)
        }
    }

    func parseUnsignedIntegerType() throws -> UnsignedIntegerType {
        /*
         UnsignedIntegerType ::
         unsigned IntegerType
         IntegerType
         */

        guard check(forNext: .terminal(.unsigned)) else {

            return try .signed(parseIntegerType())
        }
        return try .unsigned(parseIntegerType())
    }

    func parseIntegerType() throws -> IntegerType {
        /*
         IntegerType ::
         short
         long OptionalLong
         */

        switch try unwrap(tokens.first) {
        case .terminal(.long):
            tokens.removeFirst()
            if try parseOptionalLong() {
                return .longLong
            } else {
                return .long
            }

        case .terminal(.short):
            tokens.removeFirst()
            return .short

        case let t:
            try unexpected(t)
        }
    }

    func parseOptionalLong() throws -> Bool {
        /*
         OptionalLong ::
         long
         ε
         */
        return check(forNext: .terminal(.long))
    }

    func parseStringType() throws -> StringType {
        /*
         StringType ::
         ByteString
         DOMString
         USVString
         */

        switch try unwrap(tokens.first) {
        case .terminal(.ByteString):
            tokens.removeFirst()
            return .ByteString

        case .terminal(.DOMString):
            tokens.removeFirst()
            return .DOMString

        case .terminal(.USVString):
            tokens.removeFirst()
            return .USVString

        case let t:
            try unexpected(t)
        }
    }

    func parsePromiseType() throws -> Promise {
        /*
         PromiseType ::
         Promise < ReturnType >
         */

        expect(next: .terminal(.promise))
        expect(next: .terminal(.openingAngleBracket))
        let returnType = try parseReturnType()
        expect(next: .terminal(.closingAngleBracket))

        return Promise(returnType: returnType)
    }

    func parseReturnType() throws -> ReturnType {
        /*
         ReturnType ::
         Type
         void
         */
        if check(forNext: .terminal(.void)) {
            return .void
        } else {
            return .dataType(try parseType())
        }
    }

    func parseRecordType() throws -> RecordType {
        /*
         RecordType ::
         record < StringType , TypeWithExtendedAttributes >
         */

        expect(next: .terminal(.record))
        expect(next: .terminal(.openingAngleBracket))
        let stringType = try parseStringType()
        expect(next: .terminal(.comma))
        let typeWithExtendedAttributes = try parseTypeWithExtendedAttributes()
        expect(next: .terminal(.closingAngleBracket))

        return RecordType(stringType: stringType, typeWithExtendedAttributes: typeWithExtendedAttributes)
    }

    func parseNull() throws -> Bool {

        /*
         Null ::
         ?
         ε
         */

        check(forNext: .terminal(.questionMark))
    }

    func parseBufferRelatedType() throws -> BufferRelatedType {

        /*
         BufferRelatedType ::
         ArrayBuffer
         DataView
         Int8Array
         Int16Array
         Int32Array
         Uint8Array
         Uint16Array
         Uint32Array
         Uint8ClampedArray
         Float32Array
         Float64Array
         */

        switch tokens.removeFirst() {
        case .terminal(.ArrayBuffer): return .ArrayBuffer
        case .terminal(.DataView): return .DataView
        case .terminal(.Int8Array): return .Int8Array
        case .terminal(.Int16Array): return .Int16Array
        case .terminal(.Int32Array): return .Int32Array
        case .terminal(.Uint8Array): return .Uint8Array
        case .terminal(.Uint16Array): return .Uint16Array
        case .terminal(.Uint32Array): return .Uint32Array
        case .terminal(.Uint8ClampedArray): return .Uint8ClampedArray
        case .terminal(.Float32Array): return .Float32Array
        case .terminal(.Float64Array): return .Float64Array
        case let t:
            try unexpected(t)
        }
    }
}

func union(_ sets: Set<Token> ...) -> Set<Token> {

    return sets.reduce(Set<Token>()) {
        $0.union($1)
    }
}

    func firstSet(for symbol: NonTerminal) -> Set<Token> {

        switch symbol {
        case .Definitions:
            return union(
                firstSet(for: .ExtendedAttributes),
                firstSet(for: .Definition)
            )

        case .Definition:
            return union(
                firstSet(for: .CallbackOrInterfaceOrMixin),
                firstSet(for: .Namespace),
                firstSet(for: .Partial),
                firstSet(for: .Dictionary),
                firstSet(for: .Enum),
                firstSet(for: .Typedef),
                firstSet(for: .IncludesStatement)
            )

        case .ArgumentNameKeyword:
            return [.terminal(.async),.terminal(.attribute),.terminal(.callback),.terminal(.const),.terminal(.constructor),.terminal(.deleter),.terminal(.dictionary),.terminal(.enum),.terminal(.getter),.terminal(.includes),.terminal(.inherit),.terminal(.interface),.terminal(.iterable),.terminal(.maplike),.terminal(.mixin),.terminal(.namespace),.terminal(.partial),.terminal(.readonly),.terminal(.required),.terminal(.setlike),.terminal(.setter),.terminal(.static),.terminal(.stringifier),.terminal(.typedef),.terminal(.unrestricted),]

        case .CallbackOrInterfaceOrMixin:
            return [.terminal(.callback), .terminal(.interface)]

        case .InterfaceOrMixin:
            return union(
                firstSet(for: .InterfaceRest),
                firstSet(for: .MixinRest)
            )

        case .Partial:
            return [.terminal(.partial)]

        case .PartialDefinition:
            return union(
                [.terminal(.interface)],
                firstSet(for: .PartialDictionary),
                firstSet(for: .Namespace)
            )

        case .PartialInterfaceOrPartialMixin:
            return union(
                firstSet(for: .PartialInterfaceRest),
                firstSet(for: .MixinRest)
            )

        case .PartialInterfaceRest:
            return [.identifier]

        case .InterfaceMembers:
            return union(
                firstSet(for: .ExtendedAttributeList),
                firstSet(for: .InterfaceMember)
            )

        case .InterfaceMember:
            return union(
                firstSet(for: .PartialInterfaceMember),
                firstSet(for: .Constructor)
            )

        case .PartialInterfaceMembers:
            return union(
                firstSet(for: .ExtendedAttributeList),
                firstSet(for: .PartialInterfaceMember)
            )

        case .PartialInterfaceMember:
            return union(
                firstSet(for: .Const),
                firstSet(for: .Operation),
                firstSet(for: .Stringifier),
                firstSet(for: .StaticMember),
                firstSet(for: .Iterable),
                firstSet(for: .AsyncIterable),
                firstSet(for: .ReadOnlyMember),
                firstSet(for: .ReadWriteAttribute),
                firstSet(for: .ReadWriteMaplike),
                firstSet(for: .ReadWriteSetlike)
            )

        case .Inheritance:
            return [.terminal(.colon)]

        case .InterfaceRest:
            return [.identifier]

        case .MixinRest:
            return [.terminal(.mixin)]

        case .MixinMembers:
            return union(
                firstSet(for: .ExtendedAttributeList),
                firstSet(for: .MixinMember)
            )

        case .MixinMember:
            return union(
                firstSet(for: .Const),
                firstSet(for: .RegularOperation),
                firstSet(for: .Stringifier),
                firstSet(for: .ReadOnly),
                firstSet(for: .AttributeRest)
            )

        case .IncludesStatement:
            return [.identifier]

        case .CallbackRestOrInterface:
            return union(
                firstSet(for: .CallbackRest),
                [.identifier]
            )

        case .CallbackInterfaceMembers:
            return union(
                firstSet(for: .ExtendedAttributeList),
                firstSet(for: .CallbackInterfaceMember)
            )

        case .CallbackInterfaceMember:
            return union(
                firstSet(for: .Const),
                firstSet(for: .RegularOperation)
            )

        case .Const:
            return [.terminal(.const)]

        case .ConstValue:
            return union(
                firstSet(for: .BooleanLiteral),
                firstSet(for: .FloatLiteral),
                [.integer]
            )

        case .BooleanLiteral:
            return [.terminal(.true), .terminal(.false)]

        case .FloatLiteral:
            return [.decimal, .terminal(.negativeInfinity), .terminal(.infinity), .terminal(.nan)]

        case .ConstType:
            return union(
                firstSet(for: .PrimitiveType),
                [.identifier]
            )

        case .ReadOnlyMember:
            return [.terminal(.readonly)]

        case .ReadOnlyMemberRest:
            return union(
                firstSet(for: .AttributeRest),
                firstSet(for: .MaplikeRest),
                firstSet(for: .SetlikeRest)
            )

        case .ReadWriteAttribute:
            return union(
                [.terminal(.inherit)],
                firstSet(for: .AttributeRest)
            )

        case .AttributeRest:
            return [.terminal(.attribute)]

        case .AttributeName:
            return union(
                firstSet(for: .AttributeNameKeyword),
                [.identifier]
            )

        case .AttributeNameKeyword:
            return [.terminal(.async), .terminal(.required)]

        case .ReadOnly:
            return [.terminal(.readonly)]

        case .DefaultValue:
            return union(
                firstSet(for: .ConstValue),
                [.string, .terminal(.openingSquareBracket), .terminal(.openingCurlyBraces), .terminal(.null)]
            )

        case .Operation:
            return union(
                firstSet(for: .RegularOperation),
                firstSet(for: .SpecialOperation)
            )

        case .RegularOperation:
            return firstSet(for: .ReturnType)

        case .SpecialOperation:
            return firstSet(for: .Special)

        case .Special:
            return [.terminal(.getter), .terminal(.setter), .terminal(.deleter)]

        case .OperationRest:
            return union(
                firstSet(for: .OptionalOperationName),
                [.terminal(.openingParenthesis)]
            )

        case .OptionalOperationName:
            return firstSet(for: .OperationName)

        case .OperationName:
            return union(
                firstSet(for: .OperationNameKeyword),
                [.identifier]
            )

        case .OperationNameKeyword:
            return [.terminal(.includes)]

        case .ArgumentList:
            return firstSet(for: .Argument)

        case .Arguments:
            return [.terminal(.comma)]

        case .Argument:
            return union(
                firstSet(for: .ExtendedAttributeList),
                firstSet(for: .ArgumentRest)
            )

        case .ArgumentRest:
            return union(
                [.terminal(.optional)],
                firstSet(for: .Type)
            )

        case .ArgumentName:
            return union(
                firstSet(for: .ArgumentNameKeyword),
                [.identifier]
            )

        case .Ellipsis:
            return [.terminal(.ellipsis)]

        case .ReturnType:
            return union(
                firstSet(for: .Type),
                [.terminal(.void)]
            )

        case .Constructor:
            return [.terminal(.constructor)]

        case .Stringifier:
            return [.terminal(.stringifier)]

        case .StringifierRest:
            return union(
                firstSet(for: .ReadOnly),
                firstSet(for: .AttributeRest),
                firstSet(for: .RegularOperation),
                [.terminal(.semicolon)]
            )

        case .StaticMember:
            return [.terminal(.static)]

        case .StaticMemberRest:
            return union(
                firstSet(for: .ReadOnly),
                firstSet(for: .AttributeRest),
                firstSet(for: .RegularOperation)
            )

        case .Iterable:
            return [.terminal(.iterable)]

        case .OptionalType:
            return [.terminal(.comma)]

        case .AsyncIterable:
            return [.terminal(.async)]

        case .ReadWriteMaplike:
            return firstSet(for: .MaplikeRest)

        case .MaplikeRest:
            return [.terminal(.maplike)]

        case .ReadWriteSetlike:
            return firstSet(for: .SetlikeRest)

        case .SetlikeRest:
            return [.terminal(.setlike)]

        case .Namespace:
            return [.terminal(.namespace)]

        case .NamespaceMembers:
            return union(
                firstSet(for: .ExtendedAttributeList),
                firstSet(for: .NamespaceMember)
            )

        case .NamespaceMember:
            return union(
                firstSet(for: .RegularOperation),
                [.terminal(.readonly)]
            )

        case .Dictionary:
            return [.terminal(.dictionary)]

        case .DictionaryMembers:
            return firstSet(for: .DictionaryMember)

        case .DictionaryMember:
            return union(
                firstSet(for: .ExtendedAttributeList),
                firstSet(for: .DictionaryMemberRest)
            )

        case .DictionaryMemberRest:
            return union(
                [.terminal(.required)],
                firstSet(for: .Type)
            )

        case .PartialDictionary:
            return [.terminal(.dictionary)]

        case .Default:
            return [.terminal(.equalSign)]

        case .Enum:
            return [.terminal(.enum)]

        case .EnumValueList:
            return [.string]

        case .EnumValueListComma:
            return [.terminal(.comma)]

        case .EnumValueListString:
            return [.string]

        case .CallbackRest:
            return [.identifier]

        case .Typedef:
            return [.terminal(.typedef)]

        case .Type:
            return union(
                firstSet(for: .SingleType),
                firstSet(for: .UnionType)
            )

        case .TypeWithExtendedAttributes:
            return union(
                firstSet(for: .ExtendedAttributeList),
                firstSet(for: .Type)
            )

        case .SingleType:
            return union(
                firstSet(for: .DistinguishableType),
                [.terminal(.any)],
                firstSet(for: .PromiseType)
            )

        case .UnionType:
            return [.terminal(.openingParenthesis)]

        case .UnionMemberType:
            return union(
                firstSet(for: .ExtendedAttributeList),
                firstSet(for: .DistinguishableType),
                firstSet(for: .UnionType)
            )

        case .UnionMemberTypes:
            return [.terminal(.or)]

        case .DistinguishableType:
            return union(
                firstSet(for: .PrimitiveType),
                firstSet(for: .StringType),
                [.identifier, .terminal(.sequence), .terminal(.object), .terminal(.symbol)],
                firstSet(for: .BufferRelatedType),
                [.terminal(.FrozenArray)],
                firstSet(for: .RecordType)
            )

        case .PrimitiveType:
            return union(
                firstSet(for: .UnsignedIntegerType),
                firstSet(for: .UnrestrictedFloatType),
                [.terminal(.boolean), .terminal(.byte),.terminal(.octet)]
            )

        case .UnrestrictedFloatType:
            return union(
                firstSet(for: .FloatType),
                [.terminal(.unrestricted)]
            )

        case .UnsignedIntegerType:
            return union(
                firstSet(for: .IntegerType),
                [.terminal(.unsigned)]
            )

        case .FloatType:
            return [.terminal(.double),.terminal(.float),]

        case .IntegerType:
            return [.terminal(.long),.terminal(.short),]

        case .OptionalLong:
            return [.terminal(.long)]

        case .StringType:
            return [.terminal(.ByteString), .terminal(.DOMString), .terminal(.USVString)]

        case .PromiseType:
            return [.terminal(.promise)]

        case .RecordType:
            return [.terminal(.record)]

        case .Null:
            return [.terminal(.questionMark)]

        case .BufferRelatedType:
            return [.terminal(.ArrayBuffer),.terminal(.DataView),.terminal(.Int8Array),.terminal(.Int16Array),.terminal(.Int32Array),.terminal(.Uint8Array),.terminal(.Uint16Array),.terminal(.Uint32Array),.terminal(.Uint8ClampedArray),.terminal(.Float32Array),.terminal(.Float64Array),]

        case .ExtendedAttributeList :
            return [.terminal(.openingSquareBracket)]

        case .ExtendedAttributes:
            return [.terminal(.comma)]

        case .ExtendedAttribute:
            return union(
                [.terminal(.openingParenthesis), .terminal(.openingSquareBracket), .terminal(.openingCurlyBraces)],
                firstSet(for: .Other)
            )

        case .ExtendedAttributeRest:
            return firstSet(for: .ExtendedAttribute)

        case .ExtendedAttributeInner:
            return union(
                [.terminal(.openingParenthesis), .terminal(.openingSquareBracket), .terminal(.openingCurlyBraces)],
                firstSet(for: .OtherOrComma)
            )

        case .Other:
            return union(
                [.identifier,
                 .integer,
                 .decimal,
                 .string,
                 .other,
                 .terminal(.minus),
                 .terminal(.negativeInfinity),
                 .terminal(.dot),
                 .terminal(.ellipsis),
                 .terminal(.colon),
                 .terminal(.semicolon),
                 .terminal(.openingAngleBracket),
                 .terminal(.equalSign),
                 .terminal(.closingAngleBracket),
                 .terminal(.questionMark),
                 .terminal(.ByteString),
                 .terminal(.DOMString),
                 .terminal(.FrozenArray),
                 .terminal(.infinity),
                 .terminal(.nan),
                 .terminal(.promise),
                 .terminal(.USVString),
                 .terminal(.any),
                 .terminal(.boolean),
                 .terminal(.byte),
                 .terminal(.double),
                 .terminal(.false),
                 .terminal(.float),
                 .terminal(.long),
                 .terminal(.null),
                 .terminal(.object),
                 .terminal(.octet),
                 .terminal(.or),
                 .terminal(.optional),
                 .terminal(.record),
                 .terminal(.sequence),
                 .terminal(.short),
                 .terminal(.symbol),
                 .terminal(.true),
                 .terminal(.unsigned),
                 .terminal(.void)],
                firstSet(for: .ArgumentNameKeyword),
                firstSet(for: .BufferRelatedType)
            )

        case .OtherOrComma:
            return union(
                [.terminal(.comma)],
                firstSet(for: .Other)
            )

        case .IdentifierList:
            return [.identifier]

        case .Identifiers:
            return [.terminal(.comma)]
            
        case .ExtendedAttributeNoArgs:
            return []

        case .ExtendedAttributeArgList:
            return []

        case .ExtendedAttributeIdent:
            return []

        case .ExtendedAttributeIdentList:
            return []

        case .ExtendedAttributeNamedArgList:
            return []
        }
    }
