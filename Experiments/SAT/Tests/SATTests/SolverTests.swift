// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

import SAT

final class SolverTests: XCTestCase {
    func testBasics() throws {
        let v0 = Variable(0) 

        XCTAssertEqual(
            try solve(formula:
                Formula(clauses: [
                        Clause(
                            a: (v0, true),
                            b: (v0, true),
                            c: (v0, true))])),
            Assignment(bindings: [v0: true]))

        XCTAssertEqual(
            try solve(formula:
                Formula(clauses: [
                        Clause(
                            a: (v0, false),
                            b: (v0, false),
                            c: (v0, false))])),
            Assignment(bindings: [v0: false]))

        XCTAssertEqual(
            try solve(formula:
                Formula(clauses: [
                        Clause(
                            a: (v0, true),
                            b: (v0, true),
                            c: (v0, true)),
                        Clause(
                            a: (v0, false),
                            b: (v0, false),
                            c: (v0, false))])),
            nil)
    }
}
