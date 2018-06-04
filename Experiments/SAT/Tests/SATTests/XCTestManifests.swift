import XCTest

extension SATTests {
    static let __allTests = [
        ("testBasics", testBasics),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SATTests.__allTests),
    ]
}
#endif
