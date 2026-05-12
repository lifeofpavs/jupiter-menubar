import Foundation

struct TokensService {
    let client: JupiterClient

    init(client: JupiterClient = .shared) {
        self.client = client
    }

    func topTrending(interval: String = "24h", limit: Int = 10) async throws -> [TrendingToken] {
        try await client.get(
            "/tokens/v2/toptrending/\(interval)",
            query: ["limit": String(limit)]
        )
    }

    func search(mints: [String]) async throws -> [TrendingToken] {
        guard !mints.isEmpty else { return [] }
        var results: [TrendingToken] = []
        for chunk in mints.chunked(into: 100) {
            let res: [TrendingToken] = try await client.get(
                "/tokens/v2/search",
                query: ["query": chunk.joined(separator: ",")]
            )
            results.append(contentsOf: res)
        }
        return results
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
