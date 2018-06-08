// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

import SAT

func tidy(_ string: String) -> String {
    if string.count < 100 {
        return string
    }
    return string.prefix(100) + "..."
}

// Load a formula from a DIMACS file, if an argument is given.
let f: Formula
if CommandLine.arguments.count <= 1 {
    f = Formula(clauses: 
        Clause(terms: 
            Term(not: Variable(0)),
            Term(not: Variable(1)),
            Term(not: Variable(2))),
        Clause(terms: 
            Term(Variable(0)),
            Term(Variable(1)),
            Term(Variable(2))))
} else {
    let s = try String(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
    f = try DIMACSLoader(s).load()
}

print("formula = \(tidy(String(describing: f)))")
for solver in [DPLLSolver()/*, BruteForceSolver()*/] as [Solver] {
    print("solving with \(type(of: solver))")
    if let result = try solver.solve(formula: f) {
        print("... result = \(tidy(String(describing: result)))")
        if f.isSatisfied(by: result) != true {
            fatalError("found invalid solution")
        }
    } else {
        print("... not satisfiable")
    }
    print("... solved in \(solver.iterations) iterations")
}
