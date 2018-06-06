// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import SAT

let f = Formula(clauses: 
    Clause(terms: 
        Term(not: Variable(0)),
        Term(not: Variable(1)),
        Term(not: Variable(2))),
    Clause(terms: 
        Term(Variable(0)),
        Term(Variable(1)),
        Term(Variable(2))))
print("formula = \(f)")
if let result = try solve(formula: f) {
    print("result = \(result)")
} else {
    print("not satisfiable")
}
