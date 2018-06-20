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
private let v3 = Variable(3)
private let v4 = Variable(4)
private let v5 = Variable(5)
private let v6 = Variable(6)
private let v7 = Variable(7)
private let v8 = Variable(8)

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

        // Check a non-trivial unsatisfiable instance.
        XCTAssertEqual(
            try CDCLSolver().solve(formula:
                Formula(clauses:
                    Clause(terms: Term(v0), Term(v1)),
                    Clause(terms: Term(not: v0), Term(v1)),
                    Clause(terms: Term(v0), Term(not: v1)),
                    Clause(terms: Term(not: v0), Term(not: v1)))),
            nil)

        // Check a non-trivial satisfiable instance.
        do {
            let f = Formula(clauses:
                Clause(terms: Term(not: v1), Term(not: v3), Term(v4)),
                Clause(terms: Term(not: v3), Term(v5)),
                Clause(terms: Term(not: v4), Term(not: v5), Term(v6)),
                Clause(terms: Term(not: v6), Term(v7)),
                Clause(terms: Term(not: v2), Term(not: v6), Term(v8)),
                Clause(terms: Term(not: v7), Term(not: v8)),
                Clause(terms: Term(not: v7), Term(v8)))
            guard let assignment = try CDCLSolver().solve(formula: f) else {
                XCTFail("incomplete result for solving: \(f) (has a solution)")
                return
            }
            XCTAssertEqual(f.isSatisfied(by: assignment), true)
        }
    }

    func testConflictResolution() {
        do {
            var igraph = CDCLSolver.ImplicationGraph.empty
            XCTAssertTrue(igraph.bind(v0, to: true, decisionLevel: 0, cause: nil))
            XCTAssertTrue(igraph.bind(v1, to: true, decisionLevel: 1, cause: nil))
            XCTAssertTrue(igraph.bind(v2, to: true, decisionLevel: 1, cause: Clause(terms: Term(not: v1), Term(v2))))
            XCTAssertFalse(igraph.bind(v2, to: false, decisionLevel: 1, cause: Clause(terms: Term(not: v1), Term(not: v2))))
            XCTAssertEqual(
                igraph.analyzeConflict(),
                Clause(terms: Term(not: v1)))
        }

        do {
            var igraph = CDCLSolver.ImplicationGraph.empty
            XCTAssertTrue(igraph.bind(v0, to: true, decisionLevel: 0, cause: nil))
            XCTAssertTrue(igraph.bind(v1, to: true, decisionLevel: 1, cause: nil))
            XCTAssertTrue(igraph.bind(v2, to: true, decisionLevel: 1, cause: Clause(terms:
                        Term(not: v0), Term(not: v1), Term(v2))))
            XCTAssertFalse(igraph.bind(v2, to: false, decisionLevel: 1, cause: Clause(terms:
                        Term(not: v0), Term(not: v1), Term(not: v2))))
            XCTAssertEqual(
                igraph.analyzeConflict(),
                Clause(terms: Term(not: v0), Term(not: v1)))
        }
    }
}
