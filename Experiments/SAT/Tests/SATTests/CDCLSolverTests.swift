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
    }
}
