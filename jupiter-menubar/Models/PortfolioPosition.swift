import Foundation

struct PortfolioResponse: Decodable {
    let owner: String
    let elements: [PortfolioElement]
    let tokenInfo: TokenInfoMap?

    enum CodingKeys: String, CodingKey { case owner, elements, tokenInfo }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        owner = try c.decode(String.self, forKey: .owner)
        elements = (try? c.decode([PortfolioElement].self, forKey: .elements)) ?? []
        tokenInfo = try? c.decode(TokenInfoMap.self, forKey: .tokenInfo)
    }
}

struct TokenInfoMap: Codable {
    let solana: [String: PortfolioTokenInfo]?

    enum CodingKeys: String, CodingKey { case solana }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        solana = try c.decodeIfPresent([String: PortfolioTokenInfo].self, forKey: .solana)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(solana, forKey: .solana)
    }

    func symbol(for address: String) -> String? { solana?[address]?.symbol }
}

struct PortfolioTokenInfo: Codable, Hashable {
    let address: String
    let symbol: String
    let name: String?
    let decimals: Int?
}

struct PortfolioElement: Codable, Identifiable {
    let type: String
    let label: String?
    let value: Decimal?
    let platformId: String?
    let networkId: String?
    let assets: [PortfolioAsset]

    var id: String { "\(platformId ?? "?")-\(type)-\(label ?? "")" }

    enum CodingKeys: String, CodingKey {
        case type, label, value, platformId, networkId, data
    }
    enum DataKeys: String, CodingKey {
        case assets, liquidities, suppliedAssets, borrowedAssets, rewardAssets, positions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        label = try c.decodeIfPresent(String.self, forKey: .label)
        value = try c.decodeDecimalIfPresent(forKey: .value)
        platformId = try c.decodeIfPresent(String.self, forKey: .platformId)
        networkId = try c.decodeIfPresent(String.self, forKey: .networkId)

        var collected: [PortfolioAsset] = []
        if let dataContainer = try? c.nestedContainer(keyedBy: DataKeys.self, forKey: .data) {
            if let a = try? dataContainer.decodeIfPresent([PortfolioAsset].self, forKey: .assets) {
                collected.append(contentsOf: a)
            }
            if let a = try? dataContainer.decodeIfPresent([PortfolioAsset].self, forKey: .suppliedAssets) {
                collected.append(contentsOf: a.map { $0.tagging("supplied") })
            }
            if let a = try? dataContainer.decodeIfPresent([PortfolioAsset].self, forKey: .borrowedAssets) {
                collected.append(contentsOf: a.map { $0.tagging("borrowed") })
            }
            if let a = try? dataContainer.decodeIfPresent([PortfolioAsset].self, forKey: .rewardAssets) {
                collected.append(contentsOf: a.map { $0.tagging("reward") })
            }
        }
        assets = collected
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(label, forKey: .label)
        try c.encodeIfPresent(value, forKey: .value)
        try c.encodeIfPresent(platformId, forKey: .platformId)
        try c.encodeIfPresent(networkId, forKey: .networkId)
        var dataContainer = c.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        try dataContainer.encode(assets, forKey: .assets)
    }

    var typeLabel: String {
        switch type {
        case "multiple": return label ?? "Wallet"
        case "liquidity": return "Liquidity"
        case "trade": return "Orders"
        case "leverage": return "Perps"
        case "borrowlend": return "Lending"
        default: return type.capitalized
        }
    }

    var displayTitle: String {
        if let p = platformId, !p.isEmpty, p != "native-stake" { return p }
        return typeLabel
    }

    var rolledValue: Decimal {
        if let v = value { return v }
        let supplied = assets
            .filter { $0.tag != "borrowed" }
            .compactMap(\.value)
            .reduce(0, +)
        let borrowed = assets
            .filter { $0.tag == "borrowed" }
            .compactMap { $0.value.map { Swift.abs($0) } }
            .reduce(0, +)
        return supplied - borrowed
    }

    var hasContent: Bool {
        if Swift.abs(rolledValue) > Decimal(string: "0.01") ?? 0 { return true }
        return assets.contains { ($0.value ?? 0) > 0 || ($0.amount ?? 0) > 0 }
    }
}

struct PortfolioAsset: Codable, Identifiable {
    let type: String?
    let value: Decimal?
    let address: String?
    let amount: Decimal?
    let price: Decimal?
    var tag: String?

    enum CodingKeys: String, CodingKey { case type, value, data, tag }
    enum InnerDataKeys: String, CodingKey { case address, amount, price }

    var id: String { "\(address ?? UUID().uuidString)-\(tag ?? "")" }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decodeIfPresent(String.self, forKey: .type)
        value = try c.decodeDecimalIfPresent(forKey: .value)
        if let inner = try? c.nestedContainer(keyedBy: InnerDataKeys.self, forKey: .data) {
            address = try inner.decodeIfPresent(String.self, forKey: .address)
            amount = try inner.decodeDecimalIfPresent(forKey: .amount)
            price = try inner.decodeDecimalIfPresent(forKey: .price)
        } else {
            address = nil
            amount = nil
            price = nil
        }
        tag = try c.decodeIfPresent(String.self, forKey: .tag)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(type, forKey: .type)
        try c.encodeIfPresent(value, forKey: .value)
        try c.encodeIfPresent(tag, forKey: .tag)
        var inner = c.nestedContainer(keyedBy: InnerDataKeys.self, forKey: .data)
        try inner.encodeIfPresent(address, forKey: .address)
        try inner.encodeIfPresent(amount, forKey: .amount)
        try inner.encodeIfPresent(price, forKey: .price)
    }

    func tagging(_ t: String) -> PortfolioAsset {
        var copy = self
        copy.tag = t
        return copy
    }
}

struct WalletPortfolio: Codable, Identifiable {
    let wallet: String
    let elements: [PortfolioElement]
    let tokens: TokenInfoMap?
    let walletTokens: [WalletToken]
    let error: String?

    var id: String { wallet }

    var walletTotal: Decimal {
        walletTokens.compactMap(\.usdValue).reduce(0, +)
    }
    var positionsTotal: Decimal {
        elements.map(\.rolledValue).reduce(0, +)
    }
    var total: Decimal { walletTotal + positionsTotal }
}
