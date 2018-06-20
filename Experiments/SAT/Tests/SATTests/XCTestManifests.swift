import XCTest

extension AssignmentTests {
    static let __allTests = [
        ("testBasics", testBasics),
    ]
}

extension CDCDLSolverTests {
    static let __allTests = [
        ("testBasics", testBasics),
        ("testConflictResolution", testConflictResolution),
    ]
}

extension ClauseTests {
    static let __allTests = [
        ("testIsSatisfied", testIsSatisfied),
        ("testPropagation", testPropagation),
        ("testResolution", testResolution),
    ]
}

extension FormulaTests {
    static let __allTests = [
        ("testDescription", testDescription),
        ("testIsSatisfied", testIsSatisfied),
        ("testPureLiteralEliminate", testPureLiteralEliminate),
        ("testUnitPropagation", testUnitPropagation),
    ]
}

extension SolverTests {
    static let __allTests = [
        ("testBasics", testBasics),
        ("testDPLLSolver", testDPLLSolver),
    ]
}

extension TermTests {
    static let __allTests = [
        ("testDescription", testDescription),
        ("testIsSatisfied", testIsSatisfied),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AssignmentTests.__allTests),
        testCase(CDCDLSolverTests.__allTests),
        testCase(ClauseTests.__allTests),
        testCase(FormulaTests.__allTests),
        testCase(SolverTests.__allTests),
        testCase(TermTests.__allTests),
    ]
}
#endif
