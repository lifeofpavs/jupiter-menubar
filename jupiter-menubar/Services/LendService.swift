import Foundation

struct LendService {
    let client: JupiterClient

    init(client: JupiterClient = .shared) {
        self.client = client
    }

    func positions(for wallets: [String]) async throws -> [LendPosition] {
        guard !wallets.isEmpty else { return [] }
        let csv = wallets.joined(separator: ",")
        let wrapped: [Failable<LendPosition>] = try await client.get("/lend/v1/earn/positions", query: ["users": csv])
        return wrapped.compactMap(\.value)
    }

    func markets() async throws -> [LendMarket] {
        try await client.get("/lend/v1/earn/tokens")
    }
}

struct Failable<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}
