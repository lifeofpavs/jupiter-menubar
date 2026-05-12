import Foundation

struct AppSnapshot: Codable {
    var portfolios: [WalletPortfolio]
    var positions: [LendPosition]
    var trending: [TrendingToken]
    var lendMarkets: [LendMarket]
    var lastUpdated: Date?
}

enum CacheStore {
    private static let filename = "snapshot.json"

    private static var fileURL: URL? {
        guard let dir = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        let app = dir.appendingPathComponent("JupiterMenuBar", isDirectory: true)
        try? FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        return app.appendingPathComponent(filename)
    }

    static func load() -> AppSnapshot? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppSnapshot.self, from: data)
    }

    static func save(_ snapshot: AppSnapshot) {
        guard let url = fileURL else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
