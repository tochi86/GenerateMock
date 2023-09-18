import Dependencies
import XCTest
@testable import GenerateMockClient

@MainActor
final class ViewModelTests: XCTestCase {
    var sut: ViewModel!
    var apiClientMock: APIClient.Mock!

    override func setUp() {
        super.setUp()
        apiClientMock = .init()
        sut = withDependencies {
            $0.apiClient = .mock(apiClientMock)
        } operation: {
            ViewModel(userId: 1234)
        }
    }

    func testButtonTapped_Success() async {
        apiClientMock.fetchUserNameHandler = { "Mock user for \($0)" }
        apiClientMock.setUserFlagHandler = { _, _ in }
        await sut.buttonTapped()

        XCTAssertEqual(sut.text, "Mock user for 1234")
        XCTAssertEqual(apiClientMock.fetchUserNameCallCount, 1)
        XCTAssertEqual(apiClientMock.fetchUserNameArgValues, [1234])

        XCTAssertEqual(apiClientMock.setUserFlagCallCount, 1)
        XCTAssertEqual(apiClientMock.setUserFlagArgValues.map(\.userId), [1234])
        XCTAssertEqual(apiClientMock.setUserFlagArgValues.map(\.flag), [true])
    }

    func testButtonTapped_Failure() async {
        apiClientMock.fetchUserNameHandler = { _ in
            struct SomeError: Error {}
            throw SomeError()
        }
        await sut.buttonTapped()

        XCTAssertEqual(sut.text, "Error!")
        XCTAssertEqual(apiClientMock.fetchUserNameCallCount, 1)
        XCTAssertEqual(apiClientMock.fetchUserNameArgValues, [1234])

        XCTAssertEqual(apiClientMock.setUserFlagCallCount, 0)
        XCTAssertEqual(apiClientMock.setUserFlagArgValues.map(\.userId), [])
        XCTAssertEqual(apiClientMock.setUserFlagArgValues.map(\.flag), [])
    }

    func testButtonTapped_RetryWithLoading() async {
        await withMainSerialExecutor {
            apiClientMock.fetchUserNameHandler = { _ in
                await Task.yield()
                struct SomeError: Error {}
                throw SomeError()
            }
            let task1 = Task { await sut.buttonTapped() }

            await Task.yield()
            XCTAssertTrue(sut.isLoading)
            XCTAssertNil(sut.text)

            await task1.value
            XCTAssertFalse(sut.isLoading)
            XCTAssertEqual(sut.text, "Error!")

            apiClientMock.fetchUserNameHandler = {
                await Task.yield()
                return "Mock user for \($0)"
            }
            apiClientMock.setUserFlagHandler = { _, _ in }
            let task2 = Task { await sut.buttonTapped() }

            await Task.yield()
            XCTAssertTrue(sut.isLoading)
            XCTAssertNil(sut.text)

            await task2.value
            XCTAssertFalse(sut.isLoading)
            XCTAssertEqual(sut.text, "Mock user for 1234")
        }
    }
}
