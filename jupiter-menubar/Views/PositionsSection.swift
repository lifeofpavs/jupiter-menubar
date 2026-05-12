import SwiftUI

struct PositionsSection: View {
    let positions: [LendPosition]
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
                    icon: "leaf",
                    title: "No wallets to track",
                    subtitle: "Add a wallet in Settings to see\nyour Jupiter Lend positions.",
                    actionTitle: "Open Settings…",
                    action: onOpenSettings
                )
            } else if positions.isEmpty && error == nil {
                LoadingRow()
            } else if groupedByWallet.isEmpty {
                EmptyState(
                    icon: "leaf",
                    title: "No active lend positions",
                    subtitle: "Visit jup.ag/lend to deposit\nand start earning yield.",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                ForEach(groupedByWallet, id: \.0) { wallet, group in
                    walletGroup(wallet: wallet, items: group)
                }
            }
        }
        .padding(.horizontal, Theme.Space.m + 4)
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

private struct AprPill: View {
    let value: Decimal

    var body: some View {
        Text(String(format: "%.2f%% APR", (value as NSDecimalNumber).doubleValue))
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .tracking(0.2)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(Capsule().fill(.green.opacity(0.16)))
            .foregroundStyle(.green)
    }
}
