import SwiftUI

struct PortfolioSection: View {
    let portfolios: [WalletPortfolio]
    let wallets: [String]
    let error: String?
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.l) {
            if let error {
                ErrorBanner(text: error)
                    .padding(.horizontal, Theme.Space.m)
            }
            if wallets.isEmpty {
                EmptyState(
                    icon: "wallet.pass",
                    title: "No wallets yet",
                    subtitle: "Add a Solana wallet in Settings\nto see your holdings here.",
                    actionTitle: "Open Settings…",
                    action: onOpenSettings
                )
            } else if portfolios.isEmpty && error == nil {
                LoadingRow()
            } else {
                ForEach(portfolios) { p in
                    walletBlock(p)
                }
            }
        }
        .padding(.horizontal, Theme.Space.m + 4)
    }

    private func walletBlock(_ p: WalletPortfolio) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            walletHeader(p)

            if let err = p.error {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            } else if p.elements.isEmpty && visibleTokens(p).isEmpty {
                Text("No holdings.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 4)
            } else {
                if !visibleTokens(p).isEmpty {
                    holdingsBlock(visibleTokens(p), total: p.walletTotal)
                }
                ForEach(sortedElements(p.elements)) { el in
                    PortfolioGroup(element: el, tokens: p.tokens)
                }
            }
        }
        .padding(.bottom, 2)
    }

    private func walletHeader(_ p: WalletPortfolio) -> some View {
        Button {
            if let url = URL(string: "https://jup.ag/portfolio/\(p.wallet)") {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Format.shortAddress(p.wallet))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)
                Spacer()
                Text(Format.usd(p.total))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.4), value: p.total)
            }
        }
        .buttonStyle(.plain)
        .help("Open jup.ag/portfolio/\(p.wallet)")
    }

    private func holdingsBlock(_ tokens: [WalletToken], total: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text("Wallet")
                    .sectionLabel()
                Spacer()
                Text(Format.usd(total))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Space.s)
            .padding(.top, 2)
            ForEach(tokens) { t in
                WalletTokenRow(token: t)
            }
        }
    }

    private func sortedElements(_ elements: [PortfolioElement]) -> [PortfolioElement] {
        elements.filter { $0.rolledValue > 0 }.sorted { $0.rolledValue > $1.rolledValue }
    }

    private func visibleTokens(_ p: WalletPortfolio) -> [WalletToken] {
        p.walletTokens
            .filter { ($0.usdValue ?? 0) >= 0.01 }
            .sorted { ($0.usdValue ?? 0) > ($1.usdValue ?? 0) }
    }
}

private struct WalletTokenRow: View {
    let token: WalletToken

    var body: some View {
        HoverableRow {
            HStack(spacing: Theme.Space.s) {
                TokenIcon(url: token.icon, fallback: token.symbol, size: 22)
                VStack(alignment: .leading, spacing: 0) {
                    Text(token.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Text(Format.amount(token.amount))
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
                Spacer(minLength: 4)
                if let usd = token.usdValue {
                    Text(Format.usd(usd))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PortfolioGroup: View {
    let element: PortfolioElement
    let tokens: TokenInfoMap?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(element.typeLabel)
                    .sectionLabel()
                if element.displayTitle != element.typeLabel {
                    Text("·")
                        .font(.system(size: 9))
                        .foregroundStyle(.quaternary)
                    Text(element.displayTitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Spacer()
                Text(Format.usd(element.rolledValue))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Space.s)
            .padding(.top, 6)
            ForEach(visibleAssets) { a in
                AssetRow(asset: a, tokens: tokens)
            }
        }
    }

    private var visibleAssets: [PortfolioAsset] {
        element.assets
            .filter { ($0.value ?? 0) > 0 || ($0.amount ?? 0) > 0 }
            .sorted { ($0.value ?? 0) > ($1.value ?? 0) }
    }
}

private struct AssetRow: View {
    let asset: PortfolioAsset
    let tokens: TokenInfoMap?

    var body: some View {
        HoverableRow {
            HStack(spacing: Theme.Space.s) {
                TokenIcon(url: nil, fallback: symbol, size: 20)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(symbol)
                            .font(.system(size: 12, weight: .semibold))
                        if let tag = asset.tag {
                            TagPill(tag: tag)
                        }
                    }
                    if let amount = asset.amount {
                        Text(Format.amount(amount))
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                }
                Spacer(minLength: 4)
                if let value = asset.value {
                    Text(Format.usd(value))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var symbol: String {
        if let addr = asset.address, let s = tokens?.symbol(for: addr) { return s }
        if let addr = asset.address { return String(addr.prefix(4)) }
        return "—"
    }
}

private struct TagPill: View {
    let tag: String

    var body: some View {
        Text(tag.uppercased())
            .font(.system(size: 8, weight: .heavy, design: .rounded))
            .tracking(0.3)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .foregroundStyle(.white)
            .background(Capsule().fill(color))
    }

    private var color: Color {
        switch tag {
        case "supplied", "reward": return Color(red: 0.18, green: 0.55, blue: 0.30)
        case "borrowed": return Color(red: 0.78, green: 0.22, blue: 0.22)
        default: return Color(white: 0.45)
        }
    }
}
