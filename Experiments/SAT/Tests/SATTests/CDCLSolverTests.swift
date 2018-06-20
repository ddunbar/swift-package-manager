// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

import SAT

private let v0 = Variable(0)
private let v1 = Variable(1)
private let v2 = Variable(2)

final class CDCDLSolverTests: XCTestCase {
    func testBasics() throws {
        XCTAssertEqual(
            try CDCLSolver().solve(formula:
                Formula(clauses: Clause(terms: []))),
            nil)

        // Check trivial units.
        XCTAssertEqual(
            try CDCLSolver().solve(formula:
                Formula(clauses: Clause(terms: Term(v0)))),
            Assignment(bindings: [v0: true]))
        XCTAssertEqual(
            try CDCLSolver().solve(formula:
                Formula(clauses: Clause(terms: Term(not: v0)))),
            Assignment(bindings: [v0: false]))

        // Check trivial units which contradict.
        XCTAssertEqual(
            try CDCLSolver().solve(formula:
                Formula(clauses:
                    Clause(terms: Term(v0)),
                    Clause(terms: Term(not: v0)))),
            nil)
        XCTAssertEqual(
            try CDCLSolver().solve(formula:
                Formula(clauses:
                    Clause(terms: Term(not: v0)),
                    Clause(terms: Term(v0)))),
            nil)
        
        // Check trivial units which demonstrate unsatisfiability.
        XCTAssertEqual(
            try CDCLSolver().solve(formula:
                Formula(clauses:
                    Clause(terms: Term(v0)),
                    Clause(terms: Term(not: v0), Term(v1)),
                    Clause(terms: Term(not: v0), Term(not: v1)))),
            nil)

        // Check a trivial case with no units.
        XCTAssertEqual(
            try CDCLSolver().solve(formula:
                Formula(clauses:
                    Clause(terms: Term(v0), Term(v1)))),
            Assignment(bindings: [v0: true]))
    }
}
