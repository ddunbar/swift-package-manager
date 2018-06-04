// swift-tools-version:4.0

// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors


import PackageDescription

let package = Package(
    name: "SAT",
    targets: [
        .target(
            name: "sattool",
            dependencies: ["SAT"]),
        
        .target(
            name: "SAT",
            dependencies: []),
        .testTarget(
            name: "SATTests",
            dependencies: ["SAT"]),
    ]
)
