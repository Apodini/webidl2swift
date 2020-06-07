import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(webidl2swiftTests.allTests),
        testCase(TokenizerTests.allTests),
        testCase(ParserTests.allTests),
    ]
}
#endif
