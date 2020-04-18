import XCTest
@testable import webidl2swift

final class webidl2swiftTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(webidl2swift().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
