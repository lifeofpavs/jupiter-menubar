import Foundation

struct LendMarket: Decodable, Identifiable, Hashable {
    let id: Int
    let address: String
    let name: String
    let symbol: String
    let uiSymbol: String?
    let decimals: Int
    let assetAddress: String
    let asset: LendUnderlying?
    let totalAssets: String?
    let rewardsRate: String?
    let supplyRate: String?
    let totalRate: String?

    enum CodingKeys: String, CodingKey {
        case id, address, name, symbol, uiSymbol, decimals
        case assetAddress, asset, totalAssets
        case rewardsRate, supplyRate, totalRate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        address = try c.decode(String.self, forKey: .address)
        name = try c.decode(String.self, forKey: .name)
        symbol = try c.decode(String.self, forKey: .symbol)
        uiSymbol = try c.decodeIfPresent(String.self, forKey: .uiSymbol)
        decimals = try c.decode(Int.self, forKey: .decimals)
        assetAddress = try c.decode(String.self, forKey: .assetAddress)
        asset = try c.decodeIfPresent(LendUnderlying.self, forKey: .asset)
        totalAssets = try c.decodeIfPresent(String.self, forKey: .totalAssets)
        rewardsRate = try c.decodeIfPresent(String.self, forKey: .rewardsRate)
        supplyRate = try c.decodeIfPresent(String.self, forKey: .supplyRate)
        totalRate = try c.decodeIfPresent(String.self, forKey: .totalRate)
    }

    var displaySymbol: String { asset?.symbol ?? uiSymbol ?? symbol }
    var iconURL: URL? { asset?.logoUrl.flatMap { URL(string: $0) } }

    var aprPercent: Decimal? {
        guard let r = totalRate, let d = Decimal(string: r) else { return nil }
        return d / 100
    }

    var rewardsAprPercent: Decimal? {
        guard let r = rewardsRate, let d = Decimal(string: r) else { return nil }
        return d / 100
    }

    var tvlUsd: Decimal? {
        guard let totalAssets, let assets = Decimal(string: totalAssets) else { return nil }
        guard let priceStr = asset?.price, let price = Decimal(string: priceStr) else { return nil }
        return (assets / decimalPow(10, decimals)) * price
    }
}

struct LendUnderlying: Decodable, Hashable {
    let address: String
    let name: String
    let symbol: String
    let decimals: Int
    let logoUrl: String?
    let price: String?

    enum CodingKeys: String, CodingKey { case address, name, symbol, decimals, logoUrl, price }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        address = try c.decode(String.self, forKey: .address)
        name = try c.decode(String.self, forKey: .name)
        symbol = try c.decode(String.self, forKey: .symbol)
        decimals = try c.decode(Int.self, forKey: .decimals)
        logoUrl = try c.decodeIfPresent(String.self, forKey: .logoUrl)
        price = try c.decodeIfPresent(String.self, forKey: .price)
    }
}

private func decimalPow(_ base: Decimal, _ exp: Int) -> Decimal {
    var result = Decimal(1)
    var b = base
    NSDecimalPower(&result, &b, exp, .plain)
    return result
}
