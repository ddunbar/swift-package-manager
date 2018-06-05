// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A boolean logical formatal in CNF.
public struct Formula: CustomStringConvertible {
    /// The list of clauses.
    public let clauses: [Clause]

    public init(clauses: [Clause]) {
        self.clauses = clauses
    }

    /// Check if the formula is satisfied by a given assignment.
    public func isSatisfied(by assignment: Assignment) -> Bool {
        // The formula is satisfied if all clauses are satisfied.
        for clause in self.clauses where !clause.isSatisfied(by: assignment) {
            return false
        }
        return true
    }

    public var description: String {
        return clauses.map{ String(describing: $0) }.joined(separator: " ⋏ ")
    }
}

/// An individual clause in a boolean formula.
public struct Clause: CustomStringConvertible {
    let a: (variable: Variable, positive: Bool)
    let b: (variable: Variable, positive: Bool)
    let c: (variable: Variable, positive: Bool)

    public init(
        a: (variable: Variable, positive: Bool),
        b: (variable: Variable, positive: Bool),
        c: (variable: Variable, positive: Bool)
    ) {
        self.a = a
        self.b = b
        self.c = c
    }

    /// Check if the clause is satisfied by a given assignment.
    public func isSatisfied(by assignment: Assignment) -> Bool {
        return (
            assignment.trueBindings.contains(a.variable) == a.positive ||
            assignment.trueBindings.contains(b.variable) == b.positive ||
            assignment.trueBindings.contains(c.variable) == c.positive)
    }

    public var description: String {
        return """
        (\
        \(a.variable)\(a.positive ? "" : "'") ⋎ \
        \(b.variable)\(b.positive ? "" : "'") ⋎ \
        \(c.variable)\(c.positive ? "" : "'")\
        )
        """
    }
}

/// A formula variable.
public struct Variable: Hashable, CustomStringConvertible {
    /// A unique ID for the variable.
    public let id: Int

    public init(_ id: Int) {
        self.id = id
    }

    public var description: String {
        return "ν\(self.id)"
    }
}
