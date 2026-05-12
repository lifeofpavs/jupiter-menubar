import Foundation

struct TrendingToken: Codable, Identifiable, Hashable {
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

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(symbol, forKey: .symbol)
        try c.encodeIfPresent(icon?.absoluteString, forKey: .icon)
        try c.encodeIfPresent(usdPrice, forKey: .usdPrice)
        try c.encodeIfPresent(mcap, forKey: .mcap)
        try c.encodeIfPresent(liquidity, forKey: .liquidity)
        try c.encodeIfPresent(isVerified, forKey: .isVerified)
        try c.encodeIfPresent(organicScoreLabel, forKey: .organicScoreLabel)
        try c.encodeIfPresent(audit, forKey: .audit)
        try c.encodeIfPresent(stats24h, forKey: .stats24h)
    }

    var priceChange24h: Decimal? { stats24h?.priceChange }
    var isSus: Bool { audit?.isSus ?? false }
}

struct Audit: Codable, Hashable {
    let isSus: Bool?

    enum CodingKeys: String, CodingKey { case isSus }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isSus = try c.decodeIfPresent(Bool.self, forKey: .isSus)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(isSus, forKey: .isSus)
    }
}

struct IntervalStats: Codable, Hashable {
    let priceChange: Decimal?
    let volumeChange: Decimal?

    enum CodingKeys: String, CodingKey { case priceChange, volumeChange }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        priceChange = try c.decodeDecimalIfPresent(forKey: .priceChange)
        volumeChange = try c.decodeDecimalIfPresent(forKey: .volumeChange)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(priceChange, forKey: .priceChange)
        try c.encodeIfPresent(volumeChange, forKey: .volumeChange)
    }
}
