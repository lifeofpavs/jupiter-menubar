import Foundation

struct UltraService {
    let client: JupiterClient

    init(client: JupiterClient = .shared) {
        self.client = client
    }

    func holdings(for wallet: String) async throws -> UltraHoldingsResponse {
        try await client.get("/ultra/v1/holdings/\(wallet)")
    }
}
