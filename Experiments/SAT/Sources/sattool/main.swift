// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import SAT

let f = Formula(clauses: [
        Clause(
            a: (Variable(0), false),
            b: (Variable(1), false),
            c: (Variable(2), false)),
        Clause(
            a: (Variable(0), true),
            b: (Variable(1), true),
            c: (Variable(2), true)),
    ])

print("formula = \(f)")
if let result = solve(formula: f) {
    print("result = \(result)")
} else {
    print("not satisfiable")
}
