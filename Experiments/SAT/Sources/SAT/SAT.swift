
/// A clause variable.
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

/// A variable assignment for a logical formula.
public struct Assignment: CustomStringConvertible {
    let trueBindings: Set<Variable>

    public init(trueBindings: Set<Variable>) {
        self.trueBindings = trueBindings
    }

    public var description: String {
        return "{\(trueBindings.map{ "\($0)=T" }.sorted().joined(separator: ","))}"
    }
}

public extension Set {
    public var powerSet: [Set<Element>] {
        // If the set is empty, we are done.
        if isEmpty {
            return [Set()]
        }

        // Otherwise, take an element and return the power set with and without it.
        var set = self
        let item = set.removeFirst()
        let nextSet = set.powerSet
        return nextSet + nextSet.map{ set in
            var set = set
            set.insert(item)
            return set
        }
    }
}
    
public func solve(formula: Formula) -> Assignment? {
    // Find all of the variables.
    let variables = Set(formula.clauses.flatMap{ [$0.a.variable, $0.b.variable, $0.c.variable] })

    // Iterate over all subsets of variables.
    for subset in variables.powerSet {
        // Create an assignment of these variables to true.
        let candidate = Assignment(trueBindings: subset)

        if formula.isSatisfied(by: candidate) {
            return candidate
        }
    }

    return nil
}
