import Foundation

struct LendService {
    let client: JupiterClient

    init(client: JupiterClient = .shared) {
        self.client = client
    }

    func positions(for wallets: [String]) async throws -> [LendPosition] {
        guard !wallets.isEmpty else { return [] }
        let csv = wallets.joined(separator: ",")
        return try await client.get("/lend/v1/earn/positions", query: ["users": csv])
    }
}
