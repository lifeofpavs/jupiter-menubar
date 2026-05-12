import Foundation

struct PortfolioService {
    let client: JupiterClient

    init(client: JupiterClient = .shared) {
        self.client = client
    }

    func positions(for wallet: String) async throws -> PortfolioResponse {
        try await client.get("/portfolio/v1/positions/\(wallet)")
    }
}
