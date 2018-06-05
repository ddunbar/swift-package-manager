import XCTest

extension AssignmentTests {
    static let __allTests = [
        ("testBasics", testBasics),
    ]
}

extension SolverTests {
    static let __allTests = [
        ("testBasics", testBasics),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AssignmentTests.__allTests),
        testCase(SolverTests.__allTests),
    ]
}
#endif
