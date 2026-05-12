import SwiftUI

struct PositionsSection: View {
    let positions: [LendPosition]
    let markets: [LendMarket]
    let wallets: [String]
    let positionsError: String?
    let marketsError: String?
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.l) {
            exploreBlock
            if !wallets.isEmpty || !groupedByWallet.isEmpty {
                positionsBlock
            }
            marketsBlock
        }
        .padding(.horizontal, Theme.Space.m + 4)
    }

    @ViewBuilder
    private var positionsBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your positions")
                    .sectionLabel()
                Spacer()
                if let pe = positionsError {
                    Text(pe)
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, Theme.Space.s)

            if wallets.isEmpty {
                EmptyState(
                    icon: "leaf",
                    title: "No wallets to track",
                    subtitle: "Add a wallet in Settings to see\nyour Jupiter Lend positions.",
                    actionTitle: "Open Settings…",
                    action: onOpenSettings
                )
            } else if positions.isEmpty && positionsError == nil {
                LoadingRow()
            } else if groupedByWallet.isEmpty {
                Text("No active positions. Deposit at jup.ag/lend to start earning.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, Theme.Space.s)
                    .padding(.vertical, 4)
            } else {
                ForEach(groupedByWallet, id: \.0) { wallet, group in
                    walletGroup(wallet: wallet, items: group)
                }
            }
        }
    }

    private var marketsBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Lend markets")
                    .sectionLabel()
                Spacer()
                Text("APY · TVL")
                    .sectionLabel()
                    .opacity(0.55)
            }
            .padding(.horizontal, Theme.Space.s)

            if let marketsError {
                ErrorBanner(text: marketsError)
            }
            if markets.isEmpty && marketsError == nil {
                LoadingRow()
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedMarkets) { m in
                        Button {
                            if let url = URL(string: "https://jup.ag/lend") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            MarketRow(market: m)
                        }
                        .buttonStyle(.plain)
                        .help("Open jup.ag/lend")
                    }
                }
            }
        }
    }

    private var exploreBlock: some View {
        HStack(spacing: 6) {
            ExploreCard(
                title: "Multiply",
                subtitle: "Looped yield",
                icon: "arrow.triangle.2.circlepath",
                accent: .purple,
                url: "https://jup.ag/lend/multiply"
            )
            ExploreCard(
                title: "Strategies",
                subtitle: "Auto-managed",
                icon: "wand.and.stars",
                accent: .blue,
                url: "https://jup.ag/lend/strategies"
            )
            ExploreCard(
                title: "Borrow",
                subtitle: "Collateralized",
                icon: "arrow.up.arrow.down",
                accent: .orange,
                url: "https://jup.ag/lend/borrow"
            )
        }
    }

    private var sortedMarkets: [LendMarket] {
        markets.sorted { ($0.aprPercent ?? 0) > ($1.aprPercent ?? 0) }
    }

    private var groupedByWallet: [(String, [LendPosition])] {
        let nonZero = positions.filter { $0.underlyingAmount > 0 }
        let dict = Dictionary(grouping: nonZero, by: \.ownerAddress)
        return wallets.compactMap { w in
            guard let items = dict[w], !items.isEmpty else { return nil }
            return (w, items)
        }
    }

    private func walletGroup(wallet: String, items: [LendPosition]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(Format.shortAddress(wallet))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                Spacer()
                Text("\(items.count) position\(items.count == 1 ? "" : "s")")
                    .sectionLabel()
            }
            VStack(spacing: 0) {
                ForEach(items) { p in
                    PositionRow(position: p)
                }
            }
        }
        .padding(.bottom, 2)
    }
}

private struct PositionRow: View {
    let position: LendPosition

    var body: some View {
        HoverableRow {
            HStack(spacing: Theme.Space.s) {
                TokenIcon(url: nil, fallback: position.token.displaySymbol, size: 24)
                VStack(alignment: .leading, spacing: 0) {
                    Text(position.token.displaySymbol)
                        .font(.system(size: 12, weight: .semibold))
                    Text(Format.amount(position.underlyingAmount, maxFractionDigits: 4))
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 2) {
                    if let usd = position.underlyingUsd {
                        Text(Format.usd(usd))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                    if let apr = position.token.aprPercent {
                        AprPill(value: apr)
                    }
                }
            }
        }
    }
}

private struct MarketRow: View {
    let market: LendMarket

    var body: some View {
        HoverableRow {
            HStack(spacing: Theme.Space.s) {
                TokenIcon(url: market.iconURL, fallback: market.displaySymbol, size: 22)
                VStack(alignment: .leading, spacing: 0) {
                    Text(market.displaySymbol)
                        .font(.system(size: 12, weight: .semibold))
                    if let tvl = market.tvlUsd {
                        Text("TVL \(Format.compactUsd(tvl))")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                }
                Spacer(minLength: 4)
                if let apr = market.aprPercent {
                    AprPill(value: apr)
                }
            }
        }
    }
}

private struct AprPill: View {
    let value: Decimal

    var body: some View {
        Text(String(format: "%.2f%% APY", (value as NSDecimalNumber).doubleValue))
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .tracking(0.2)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .foregroundStyle(.white)
            .background(Capsule().fill(Color(red: 0.18, green: 0.55, blue: 0.30)))
    }
}

private struct ExploreCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let url: String
    @State private var hovering = false

    var body: some View {
        Button {
            if let u = URL(string: url) {
                NSWorkspace.shared.open(u)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(subtitle)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .tracking(0.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(accent.opacity(hovering ? 0.16 : 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .strokeBorder(accent.opacity(hovering ? 0.35 : 0.18), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
        .help("Open \(url)")
    }
}
