// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A variable assignment for a logical formula.
public struct Assignment: CustomStringConvertible {
    let trueBindings: Set<Variable>

    public init(trueBindings: Set<Variable>) {
        self.trueBindings = trueBindings
    }

    public var description: String {
        let trueNames = trueBindings.map{ "\($0)=T" }.sorted()
        return "{\(trueNames.joined(separator: ","))}"
    }
}
