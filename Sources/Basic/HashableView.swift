/*
 This source file is part of the Swift.org open source project

 Copyright 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

/// Wrapper for exposing an item as a hashable.
///
/// This is intended to be used when an algorithm wants to temporarily view some
/// object as hashable based on a derived property of the object itself (most
/// commonly some member of the object itself), without erasing its type.
///
/// Example:
///
///     struct Airport {
///         // The name of the aiport.
///         let name: String
///         // The names of destination airports for outgoing flights.
///         let destinations: [String]
///     }
///
///     func whereCanIGo(from here: Airport) -> [Airport] {
///         func makeView(_ for aiport: Airport) -> HashableView<Airport, String> {
///             return HashableView(airport, accessor: { $0.name })
///         }
///         let closure = transitiveClosure([makeView(airport)]) { $0.destinations.map{ makeView } }
///         return closure.map{ $0.item }
///     }
public struct HashableView<T, H: Hashable>: Hashable {
    /// The wrapped item.
    public let item: T

    private let accessor: (T) -> H

    /// Create a new hashable box for `item` where `accessor` defines the hashable content.
    public init(_ item: T, accessor: @escaping (T) -> H) {
        self.item = item
        self.accessor = accessor
    }

    fileprivate var hashableItem: H {
        return accessor(item)
    }
    
    public var hashValue: Int {
        return hashableItem.hashValue
    }
}    
public func ==<T, H: Hashable>(lhs: HashableView<T, H>, rhs: HashableView<T, H>) -> Bool {
    return lhs.hashableItem == rhs.hashableItem
}
