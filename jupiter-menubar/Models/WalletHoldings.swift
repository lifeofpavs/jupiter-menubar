import Foundation

struct UltraHoldingsResponse: Decodable {
    let amount: String
    let uiAmount: Decimal
    let tokens: [String: [UltraTokenAccount]]

    enum CodingKeys: String, CodingKey { case amount, uiAmount, tokens }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        amount = (try? c.decode(String.self, forKey: .amount)) ?? "0"
        if let d = try? c.decode(Decimal.self, forKey: .uiAmount) {
            uiAmount = d
        } else if let s = try? c.decode(String.self, forKey: .uiAmount), let d = Decimal(string: s) {
            uiAmount = d
        } else {
            uiAmount = 0
        }
        tokens = (try? c.decode([String: [UltraTokenAccount]].self, forKey: .tokens)) ?? [:]
    }
}

struct UltraTokenAccount: Decodable {
    let amount: String?
    let uiAmount: Decimal?
    let decimals: Int?
    let isFrozen: Bool?
    let excludeFromNetWorth: Bool?

    enum CodingKeys: String, CodingKey {
        case amount, uiAmount, decimals, isFrozen, excludeFromNetWorth
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        amount = try c.decodeIfPresent(String.self, forKey: .amount)
        uiAmount = try c.decodeDecimalIfPresent(forKey: .uiAmount)
        decimals = try c.decodeIfPresent(Int.self, forKey: .decimals)
        isFrozen = try c.decodeIfPresent(Bool.self, forKey: .isFrozen)
        excludeFromNetWorth = try c.decodeIfPresent(Bool.self, forKey: .excludeFromNetWorth)
    }
}

struct WalletToken: Identifiable, Hashable {
    let mint: String
    let symbol: String
    let icon: URL?
    let amount: Decimal
    let usdPrice: Decimal?
    let isNative: Bool

    var id: String { mint }
    var usdValue: Decimal? { usdPrice.map { $0 * amount } }
}

private let nativeSolMint = "So11111111111111111111111111111111111111112"

extension UltraHoldingsResponse {
    func walletTokens(metadata: [String: TrendingToken]) -> [WalletToken] {
        var out: [WalletToken] = []

        if uiAmount > 0 {
            let info = metadata[nativeSolMint]
            out.append(WalletToken(
                mint: nativeSolMint,
                symbol: info?.symbol ?? "SOL",
                icon: info?.icon,
                amount: uiAmount,
                usdPrice: info?.usdPrice,
                isNative: true
            ))
        }

        for (mint, accounts) in tokens {
            let usable = accounts.filter { ($0.excludeFromNetWorth ?? false) == false }
            let amount = usable.compactMap(\.uiAmount).reduce(0, +)
            guard amount > 0 else { continue }
            let info = metadata[mint]
            out.append(WalletToken(
                mint: mint,
                symbol: info?.symbol ?? String(mint.prefix(4)),
                icon: info?.icon,
                amount: amount,
                usdPrice: info?.usdPrice,
                isNative: false
            ))
        }

        return out.sorted { ($0.usdValue ?? 0) > ($1.usdValue ?? 0) }
    }

    var allMints: [String] {
        var set = Set(tokens.keys)
        set.insert(nativeSolMint)
        return Array(set)
    }
}
