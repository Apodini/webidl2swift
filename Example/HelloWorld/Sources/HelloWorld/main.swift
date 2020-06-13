
import JavaScriptKit
import ECMAScript
import WebAPI

extension console {

    static func log<Type: JSValueEncodable>(_ value: Type) {
        log(data: AnyJSValueCodable(value))
    }
}

extension Document {

    var body: HTMLElement {
        return objectRef.body.fromJSValue()
    }
}

let document = Document(objectRef: JSObjectRef.global.document.object!)

console.log("Hello World!")

let header: HTMLElement = staticCast(document.createElement(localName: "h1"))
header.innerText = "Hello World!"
_ = document.body.appendChild(node: header)
