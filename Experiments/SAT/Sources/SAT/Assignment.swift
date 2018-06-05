// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A variable assignment for a logical formula.
public struct Assignment: CustomStringConvertible, Equatable {
    let bindings: [Variable: Bool]

    public init(bindings: [Variable: Bool]) {
        self.bindings = bindings
    }

    public var description: String {
        let strings = bindings.map{ "\($0.0)=\($0.1 ? "T" : "F")" }.sorted()
        return "{" + strings.joined(separator: ",") + "}"
    }
}
