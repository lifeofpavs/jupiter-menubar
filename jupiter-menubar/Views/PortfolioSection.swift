import SwiftUI

struct PortfolioSection: View {
    let portfolios: [WalletPortfolio]
    let wallets: [String]
    let error: String?
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            if wallets.isEmpty {
                emptyState
            } else if portfolios.isEmpty && error == nil {
                Text("Loading…")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(portfolios) { p in
                    walletBlock(p)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Total")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(formatUsd(grandTotal))
                    .font(.system(size: 18, weight: .bold))
                    .monospacedDigit()
            }
            Spacer()
            if let error {
                Text(error)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Add a wallet to view portfolio.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Button("Open Settings…", action: onOpenSettings)
                .font(.system(size: 11))
                .buttonStyle(.link)
        }
    }

    private var grandTotal: Decimal {
        portfolios.map(\.total).reduce(0, +)
    }

    private func walletBlock(_ p: WalletPortfolio) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button {
                    if let url = URL(string: "https://jup.ag/portfolio/\(p.wallet)") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text(shortAddress(p.wallet))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .monospaced()
                }
                .buttonStyle(.plain)
                .help("Open jup.ag/portfolio/\(p.wallet)")
                Spacer()
                Text(formatUsd(p.total))
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
            }

            if let err = p.error {
                Text(err)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
            } else if p.elements.isEmpty && p.walletTokens.isEmpty {
                Text("No holdings.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                if !p.walletTokens.isEmpty {
                    WalletHoldingsGroup(tokens: p.walletTokens, total: p.walletTotal)
                }
                ForEach(sorted(p.elements)) { el in
                    PortfolioGroup(element: el, tokens: p.tokens)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func sorted(_ elements: [PortfolioElement]) -> [PortfolioElement] {
        elements
            .filter { $0.rolledValue > 0 }
            .sorted { $0.rolledValue > $1.rolledValue }
    }

    private func shortAddress(_ a: String) -> String {
        guard a.count > 10 else { return a }
        return "\(a.prefix(4))…\(a.suffix(4))"
    }

    private func formatUsd(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        return f.string(from: d as NSDecimalNumber) ?? "$0"
    }
}

private struct PortfolioGroup: View {
    let element: PortfolioElement
    let tokens: TokenInfoMap?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(element.typeLabel)
                    .font(.system(size: 11, weight: .semibold))
                if element.displayTitle != element.typeLabel {
                    Text("· \(element.displayTitle)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(formatUsd(element.rolledValue))
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
            }
            if !visibleAssets.isEmpty {
                ForEach(visibleAssets) { a in
                    AssetRow(asset: a, tokens: tokens)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var visibleAssets: [PortfolioAsset] {
        element.assets
            .filter { ($0.value ?? 0) > 0 || ($0.amount ?? 0) > 0 }
            .sorted { ($0.value ?? 0) > ($1.value ?? 0) }
    }

    private func formatUsd(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        return f.string(from: d as NSDecimalNumber) ?? "$0"
    }
}

private struct AssetRow: View {
    let asset: PortfolioAsset
    let tokens: TokenInfoMap?

    var body: some View {
        HStack(spacing: 6) {
            if let tag = asset.tag {
                Text(tag)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
            }
            Text(symbol)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, alignment: .leading)
            if let amount = asset.amount {
                Text(formatAmount(amount))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
            Spacer()
            if let value = asset.value {
                Text(formatUsd(value))
                    .font(.system(size: 10))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 8)
    }

    private var symbol: String {
        if let addr = asset.address, let s = tokens?.symbol(for: addr) { return s }
        if let addr = asset.address { return String(addr.prefix(4)) }
        return "—"
    }

    private func formatAmount(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.maximumFractionDigits = d < 1 ? 4 : 2
        f.minimumFractionDigits = 0
        return f.string(from: d as NSDecimalNumber) ?? "0"
    }

    private func formatUsd(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        return f.string(from: d as NSDecimalNumber) ?? "$0"
    }
}

private struct WalletHoldingsGroup: View {
    let tokens: [WalletToken]
    let total: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Wallet")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Text(formatUsd(total))
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
            }
            ForEach(visible) { t in
                WalletTokenRow(token: t)
            }
        }
        .padding(.vertical, 2)
    }

    private var visible: [WalletToken] {
        tokens
            .filter { ($0.usdValue ?? 0) >= 0.01 }
            .sorted { ($0.usdValue ?? 0) > ($1.usdValue ?? 0) }
    }

    private func formatUsd(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        return f.string(from: d as NSDecimalNumber) ?? "$0"
    }
}

private struct WalletTokenRow: View {
    let token: WalletToken

    var body: some View {
        HStack(spacing: 6) {
            Text(token.symbol)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, alignment: .leading)
                .lineLimit(1)
            Text(formatAmount(token.amount))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
            Spacer()
            if let value = token.usdValue {
                Text(formatUsd(value))
                    .font(.system(size: 10))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 8)
    }

    private func formatAmount(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.maximumFractionDigits = d < 1 ? 4 : 2
        f.minimumFractionDigits = 0
        return f.string(from: d as NSDecimalNumber) ?? "0"
    }

    private func formatUsd(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        return f.string(from: d as NSDecimalNumber) ?? "$0"
    }
}
