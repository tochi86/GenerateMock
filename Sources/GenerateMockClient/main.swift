import Dependencies
import Foundation
import GenerateMock

@GenerateMock
struct APIClient {
    var fetchUserName: @Sendable (_ userId: Int) async throws -> String
    var setUserFlag: @Sendable (_ userId: Int, _ flag: Bool) async throws -> Void
}

extension APIClient: DependencyKey {
    static let liveValue = Self(
        fetchUserName: { "Live user for \($0)" },
        setUserFlag: { _, _ in try await Task.sleep(nanoseconds: NSEC_PER_SEC) }
    )
}

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

@MainActor
final class ViewModel: ObservableObject {
    @Published private(set) var text: String?
    @Published private(set) var isLoading = false
    @Dependency(\.apiClient) private var apiClient

    private let userId: Int
    init(userId: Int) { self.userId = userId }

    func buttonTapped() async {
        text = nil
        isLoading = true; defer { isLoading = false }
        do {
            text = try await apiClient.fetchUserName(userId)
            try await apiClient.setUserFlag(userId, true)
        } catch {
            text = "Error!"
        }
    }
}
