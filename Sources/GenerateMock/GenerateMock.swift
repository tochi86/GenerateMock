// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: named(mock(_:)), named(Mock))
public macro GenerateMock() = #externalMacro(module: "GenerateMockMacros", type: "GenerateMockMacro")
