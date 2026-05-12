import Foundation

struct LendPosition: Codable, Identifiable, Hashable {
    let token: TokenInfo
    let ownerAddress: String
    let shares: String?
    let underlyingAssets: String
    let underlyingBalance: String?
    let allowance: String?

    var id: String { "\(ownerAddress)-\(token.address)" }

    var underlyingAmount: Decimal {
        Decimal(string: underlyingAssets).map { $0 / pow(10, token.decimals) } ?? 0
    }

    var underlyingUsd: Decimal? {
        guard let price = token.assetUsdPrice ?? token.usdPrice else { return nil }
        return underlyingAmount * price
    }
}

struct TokenInfo: Codable, Hashable {
    let address: String
    let symbol: String
    let name: String?
    let decimals: Int
    let assetSymbol: String?
    let assetUsdPrice: Decimal?
    let usdPrice: Decimal?
    let supplyRate: Decimal?
    let rewardsRate: Decimal?
    let totalRate: Decimal?

    enum CodingKeys: String, CodingKey {
        case address, symbol, name, decimals
        case assetSymbol, assetUsdPrice, usdPrice
        case supplyRate, rewardsRate, totalRate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        address = try c.decode(String.self, forKey: .address)
        symbol = (try? c.decode(String.self, forKey: .symbol)) ?? ""
        name = try c.decodeIfPresent(String.self, forKey: .name)
        decimals = (try? c.decode(Int.self, forKey: .decimals)) ?? 0
        assetSymbol = try c.decodeIfPresent(String.self, forKey: .assetSymbol)
        assetUsdPrice = try c.decodeDecimalIfPresent(forKey: .assetUsdPrice)
        usdPrice = try c.decodeDecimalIfPresent(forKey: .usdPrice)
        supplyRate = try c.decodeDecimalIfPresent(forKey: .supplyRate)
        rewardsRate = try c.decodeDecimalIfPresent(forKey: .rewardsRate)
        totalRate = try c.decodeDecimalIfPresent(forKey: .totalRate)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(address, forKey: .address)
        try c.encode(symbol, forKey: .symbol)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encode(decimals, forKey: .decimals)
        try c.encodeIfPresent(assetSymbol, forKey: .assetSymbol)
        try c.encodeIfPresent(assetUsdPrice, forKey: .assetUsdPrice)
        try c.encodeIfPresent(usdPrice, forKey: .usdPrice)
        try c.encodeIfPresent(supplyRate, forKey: .supplyRate)
        try c.encodeIfPresent(rewardsRate, forKey: .rewardsRate)
        try c.encodeIfPresent(totalRate, forKey: .totalRate)
    }

    var displaySymbol: String { assetSymbol ?? symbol }
    var aprPercent: Decimal? { totalRate.map { $0 / 100 } }
}

extension KeyedDecodingContainer {
    func decodeDecimalIfPresent(forKey key: Key) throws -> Decimal? {
        if let d = try? decode(Decimal.self, forKey: key) { return d }
        if let s = try? decode(String.self, forKey: key) { return Decimal(string: s) }
        return nil
    }
}

private func pow(_ base: Decimal, _ exp: Int) -> Decimal {
    var result = Decimal(1)
    var b = base
    NSDecimalPower(&result, &b, exp, .plain)
    return result
}
