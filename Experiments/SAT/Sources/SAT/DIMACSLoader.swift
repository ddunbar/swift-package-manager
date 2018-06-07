// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A loader for SAT instances in the DIMACS format.
///
/// See: http://www.cs.ubc.ca/~hoos/SATLIB/Benchmarks/SAT/satformat.ps
public final class DIMACSLoader {
    public enum Error: Swift.Error {
    case missingHeader
    case invalidHeader
    case invalidClauseLine(String)
        case missingClause
    }
    
    public let string: String
    
    public init(_ string: String) {
        self.string = string
    }

    public func load() throws -> Formula {
        // Split into lines.
        let lines = self.string.split(separator: "\n")
        // FIXME: This isn't right, comments are only allowed in the preamble.
        var it = lines.lazy.filter{ !$0.hasPrefix("c") }.makeIterator()

        // Find the header.
        guard let header = it.next(), header.hasPrefix("p") else {
            throw Error.missingHeader
        }

        let headerItems = header.split(separator: " ").filter{ !$0.isEmpty }
        guard headerItems.count == 4,
              headerItems[0] == "p",
              headerItems[1] == "cnf",
              // We ignore the numVariables entry.
              let _ = Int(headerItems[2]),
              let numClauses = Int(headerItems[3]) else {
            throw Error.invalidHeader
        }
        
        // Parse the clauses.
        var clauses: [Clause] = []
        for _ in 0 ..< numClauses {
            guard let ln = it.next() else {
                throw Error.missingClause
            }
            
            // Each remaining non-empty line should be a clause.
            //
            // FIXME: This isn't right, the actual format allows other
            // whitespaces separators and doesn't require newline separation.
            let items = ln.split(separator: " ").filter{ !$0.isEmpty }
            guard items.count == 4, items[3] == "0",
                  let a = Int(items[0]),
                  let b = Int(items[1]),
                  let c = Int(items[2]) else {
                throw Error.invalidClauseLine(String(ln))
            }
            clauses.append(Clause(terms: [a, b, c].map { i in
                        return Term(Variable(abs(i)), positive: i < 0)
                    }))
        }
        
        return Formula(clauses: clauses)
    }
}
