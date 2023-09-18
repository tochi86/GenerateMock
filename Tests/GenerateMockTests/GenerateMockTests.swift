import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(GenerateMockMacros)
import GenerateMockMacros

let testMacros: [String: Macro.Type] = [
    "GenerateMock": GenerateMockMacro.self,
]
#endif

final class GenerateMockTests: XCTestCase {
    func test_ZeroArguments() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: @Sendable () async throws -> String
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: @Sendable () async throws -> String

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping () async throws -> String = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [()] = []
                    var fetchHandler: () async throws -> String
                    @Sendable fileprivate func fetch() async throws -> String {
                        fetchCallCount += 1
                        fetchArgValues.append(())
                        return try await fetchHandler()
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ZeroArguments_NoReturnValue() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: @Sendable () async throws -> Void
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: @Sendable () async throws -> Void

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping () async throws -> Void = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [()] = []
                    var fetchHandler: () async throws -> Void
                    @Sendable fileprivate func fetch() async throws -> Void {
                        fetchCallCount += 1
                        fetchArgValues.append(())
                        return try await fetchHandler()
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ZeroArguments_NoAsyncOrThrows() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: @Sendable () -> String
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: @Sendable () -> String

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping () -> String = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [()] = []
                    var fetchHandler: () -> String
                    @Sendable fileprivate func fetch() -> String {
                        fetchCallCount += 1
                        fetchArgValues.append(())
                        return fetchHandler()
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ZeroArguments_OnlyAsync() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: @Sendable () async -> String
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: @Sendable () async -> String

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping () async -> String = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [()] = []
                    var fetchHandler: () async -> String
                    @Sendable fileprivate func fetch() async -> String {
                        fetchCallCount += 1
                        fetchArgValues.append(())
                        return await fetchHandler()
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ZeroArguments_OnlyThrows() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: @Sendable () throws -> String
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: @Sendable () throws -> String

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping () throws -> String = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [()] = []
                    var fetchHandler: () throws -> String
                    @Sendable fileprivate func fetch() throws -> String {
                        fetchCallCount += 1
                        fetchArgValues.append(())
                        return try fetchHandler()
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ZeroArguments_WithoutSendable() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: () async throws -> String
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: () async throws -> String

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping () async throws -> String = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [()] = []
                    var fetchHandler: () async throws -> String
                    fileprivate func fetch() async throws -> String {
                        fetchCallCount += 1
                        fetchArgValues.append(())
                        return try await fetchHandler()
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ZeroArguments_WithPublic() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            public struct APIClient: Sendable {
                public var fetch: @Sendable () async throws -> String

                public init(fetch: @escaping @Sendable () async throws -> String) {
                    self.fetch = fetch
                }
            }
            """#,
            expandedSource: #"""
            public struct APIClient: Sendable {
                public var fetch: @Sendable () async throws -> String

                public init(fetch: @escaping @Sendable () async throws -> String) {
                    self.fetch = fetch
                }

                public static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    public init(fetchHandler: @escaping () async throws -> String = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    public private(set) var fetchCallCount = 0
                    public private(set) var fetchArgValues: [()] = []
                    public var fetchHandler: () async throws -> String
                    @Sendable fileprivate func fetch() async throws -> String {
                        fetchCallCount += 1
                        fetchArgValues.append(())
                        return try await fetchHandler()
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ZeroArguments_ZeroClosures() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
            }
            """#,
            expandedSource: #"""
            struct APIClient {

                static func mock(_ mock: Mock) -> Self {
                    Self ()
                }

                open class Mock {
                    init() {
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ZeroArguments_TwoClosures() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch1: @Sendable () async throws -> String
                var fetch2: @Sendable () async throws -> String
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch1: @Sendable () async throws -> String
                var fetch2: @Sendable () async throws -> String

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch1: mock.fetch1, fetch2: mock.fetch2)
                }

                open class Mock {
                    init(fetch1Handler: @escaping () async throws -> String = unimplemented("APIClient.Mock.fetch1Handler"), fetch2Handler: @escaping () async throws -> String = unimplemented("APIClient.Mock.fetch2Handler")) {
                        self.fetch1Handler = fetch1Handler
                        self.fetch2Handler = fetch2Handler
                    }
                    private(set) var fetch1CallCount = 0
                    private(set) var fetch1ArgValues: [()] = []
                    var fetch1Handler: () async throws -> String
                    @Sendable fileprivate func fetch1() async throws -> String {
                        fetch1CallCount += 1
                        fetch1ArgValues.append(())
                        return try await fetch1Handler()
                    }
                    private(set) var fetch2CallCount = 0
                    private(set) var fetch2ArgValues: [()] = []
                    var fetch2Handler: () async throws -> String
                    @Sendable fileprivate func fetch2() async throws -> String {
                        fetch2CallCount += 1
                        fetch2ArgValues.append(())
                        return try await fetch2Handler()
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_OneArgument() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: @Sendable (Int) async throws -> String
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: @Sendable (Int) async throws -> String

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping (Int) async throws -> String = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [(Int)] = []
                    var fetchHandler: (Int) async throws -> String
                    @Sendable fileprivate func fetch(_ arg0: Int) async throws -> String {
                        fetchCallCount += 1
                        fetchArgValues.append((arg0))
                        return try await fetchHandler(arg0)
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_OneArgument_NoReturnValue() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: @Sendable (Int) async throws -> Void
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: @Sendable (Int) async throws -> Void

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping (Int) async throws -> Void = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [(Int)] = []
                    var fetchHandler: (Int) async throws -> Void
                    @Sendable fileprivate func fetch(_ arg0: Int) async throws -> Void {
                        fetchCallCount += 1
                        fetchArgValues.append((arg0))
                        return try await fetchHandler(arg0)
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_OneArgument_WithLabel() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: @Sendable (_ userId: Int) async throws -> String
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: @Sendable (_ userId: Int) async throws -> String

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping (_ userId: Int) async throws -> String = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [(Int)] = []
                    var fetchHandler: (_ userId: Int) async throws -> String
                    @Sendable fileprivate func fetch(_ userId: Int) async throws -> String {
                        fetchCallCount += 1
                        fetchArgValues.append((userId))
                        return try await fetchHandler(userId)
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_TwoArguments() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: @Sendable (Int, Bool) async throws -> String
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: @Sendable (Int, Bool) async throws -> String

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping (Int, Bool) async throws -> String = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [(Int, Bool)] = []
                    var fetchHandler: (Int, Bool) async throws -> String
                    @Sendable fileprivate func fetch(_ arg0: Int, _ arg1: Bool) async throws -> String {
                        fetchCallCount += 1
                        fetchArgValues.append((arg0, arg1))
                        return try await fetchHandler(arg0, arg1)
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_TwoArguments_NoReturnValue() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: @Sendable (Int, Bool) async throws -> Void
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: @Sendable (Int, Bool) async throws -> Void

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping (Int, Bool) async throws -> Void = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [(Int, Bool)] = []
                    var fetchHandler: (Int, Bool) async throws -> Void
                    @Sendable fileprivate func fetch(_ arg0: Int, _ arg1: Bool) async throws -> Void {
                        fetchCallCount += 1
                        fetchArgValues.append((arg0, arg1))
                        return try await fetchHandler(arg0, arg1)
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_TwoArguments_WithLabel() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: @Sendable (_ userId: Int, _ flag: Bool) async throws -> String
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: @Sendable (_ userId: Int, _ flag: Bool) async throws -> String

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping (_ userId: Int, _ flag: Bool) async throws -> String = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [(userId: Int, flag: Bool)] = []
                    var fetchHandler: (_ userId: Int, _ flag: Bool) async throws -> String
                    @Sendable fileprivate func fetch(_ userId: Int, _ flag: Bool) async throws -> String {
                        fetchCallCount += 1
                        fetchArgValues.append((userId, flag))
                        return try await fetchHandler(userId, flag)
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }


    func test_TwoArguments_MixedWithAndWithoutLabel() throws {
        #if canImport(GenerateMockMacros)
        assertMacroExpansion(#"""
            @GenerateMock
            struct APIClient {
                var fetch: @Sendable (Int, _ flag: Bool) async throws -> String
            }
            """#,
            expandedSource: #"""
            struct APIClient {
                var fetch: @Sendable (Int, _ flag: Bool) async throws -> String

                static func mock(_ mock: Mock) -> Self {
                    Self (fetch: mock.fetch)
                }

                open class Mock {
                    init(fetchHandler: @escaping (Int, _ flag: Bool) async throws -> String = unimplemented("APIClient.Mock.fetchHandler")) {
                        self.fetchHandler = fetchHandler
                    }
                    private(set) var fetchCallCount = 0
                    private(set) var fetchArgValues: [(Int, flag: Bool)] = []
                    var fetchHandler: (Int, _ flag: Bool) async throws -> String
                    @Sendable fileprivate func fetch(_ arg0: Int, _ flag: Bool) async throws -> String {
                        fetchCallCount += 1
                        fetchArgValues.append((arg0, flag))
                        return try await fetchHandler(arg0, flag)
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
