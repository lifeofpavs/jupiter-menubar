import SwiftUI

struct PositionsSection: View {
    let positions: [LendPosition]
    let wallets: [String]
    let error: String?
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Lend Positions")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let error {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }

            if wallets.isEmpty {
                emptyState
            } else if positions.isEmpty && error == nil {
                Text("Loading…")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else if groupedByWallet.isEmpty {
                Text("No active positions.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(groupedByWallet, id: \.0) { wallet, group in
                    walletGroup(wallet: wallet, items: group)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Add a wallet to track lending positions.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Button("Open Settings…", action: onOpenSettings)
                .font(.system(size: 11))
                .buttonStyle(.link)
        }
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
        VStack(alignment: .leading, spacing: 3) {
            Text(shortAddress(wallet))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .monospaced()
            ForEach(items) { p in
                PositionRow(position: p)
            }
        }
    }

    private func shortAddress(_ a: String) -> String {
        guard a.count > 10 else { return a }
        return "\(a.prefix(4))…\(a.suffix(4))"
    }
}

private struct PositionRow: View {
    let position: LendPosition

    var body: some View {
        HStack(spacing: 8) {
            Text(position.token.displaySymbol)
                .font(.system(size: 12, weight: .semibold))
                .frame(minWidth: 50, alignment: .leading)

            Text(formatAmount(position.underlyingAmount))
                .font(.system(size: 11))
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                if let usd = position.underlyingUsd {
                    Text(formatUsd(usd))
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                }
                if let apr = position.token.aprPercent {
                    Text(String(format: "%.2f%% APR", (apr as NSDecimalNumber).doubleValue))
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private func formatAmount(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.maximumFractionDigits = d < 1 ? 6 : 4
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
