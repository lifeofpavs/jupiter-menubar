import Foundation

struct TrendingToken: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let icon: URL?
    let usdPrice: Decimal?
    let mcap: Decimal?
    let liquidity: Decimal?
    let isVerified: Bool?
    let organicScoreLabel: String?
    let audit: Audit?
    let stats24h: IntervalStats?

    enum CodingKeys: String, CodingKey {
        case id, name, symbol, icon
        case usdPrice, mcap, liquidity, isVerified
        case organicScoreLabel, audit, stats24h
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        symbol = try c.decode(String.self, forKey: .symbol)
        if let iconStr = try? c.decodeIfPresent(String.self, forKey: .icon), !iconStr.isEmpty {
            icon = URL(string: iconStr)
        } else {
            icon = nil
        }
        usdPrice = try c.decodeDecimalIfPresent(forKey: .usdPrice)
        mcap = try c.decodeDecimalIfPresent(forKey: .mcap)
        liquidity = try c.decodeDecimalIfPresent(forKey: .liquidity)
        isVerified = try c.decodeIfPresent(Bool.self, forKey: .isVerified)
        organicScoreLabel = try c.decodeIfPresent(String.self, forKey: .organicScoreLabel)
        audit = try c.decodeIfPresent(Audit.self, forKey: .audit)
        stats24h = try c.decodeIfPresent(IntervalStats.self, forKey: .stats24h)
    }

    var priceChange24h: Decimal? { stats24h?.priceChange }
    var isSus: Bool { audit?.isSus ?? false }
}

struct Audit: Decodable, Hashable {
    let isSus: Bool?

    enum CodingKeys: String, CodingKey { case isSus }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isSus = try c.decodeIfPresent(Bool.self, forKey: .isSus)
    }
}

struct IntervalStats: Decodable, Hashable {
    let priceChange: Decimal?
    let volumeChange: Decimal?

    enum CodingKeys: String, CodingKey { case priceChange, volumeChange }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        priceChange = try c.decodeDecimalIfPresent(forKey: .priceChange)
        volumeChange = try c.decodeDecimalIfPresent(forKey: .volumeChange)
    }
}
