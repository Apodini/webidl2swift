import XCTest

import webidl2swiftTests

var tests = [XCTestCaseEntry]()
tests += webidl2swiftTests.allTests()
XCTMain(tests)
