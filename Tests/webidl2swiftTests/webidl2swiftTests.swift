import XCTest
import ArgumentParser
import Commands
@testable import webidl2swift

final class webidl2swiftTests: XCTestCase {

    func test_Generation() throws  {

        let arguments = [
            "-o", "\(FileManager.default.temporaryDirectory.path)",
            "-i", "\(URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("WebIDL-files").path)",
            "--no-pretty-print",
        ]

        XCTAssertNoThrow(try GenerateCode.parse(arguments).run())
    }
}
