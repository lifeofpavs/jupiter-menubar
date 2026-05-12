import SwiftUI

struct TrendingSection: View {
    let tokens: [TrendingToken]
    let error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Trending (24h)")
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
            if tokens.isEmpty && error == nil {
                Text("Loading…")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(tokens) { token in
                    Button {
                        if let url = URL(string: "https://jup.ag/?buy=\(token.id)") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        TrendingRow(token: token)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

private struct TrendingRow: View {
    let token: TrendingToken

    var body: some View {
        HStack(spacing: 8) {
            AsyncImage(url: token.icon) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFit()
                default: Circle().fill(Color.secondary.opacity(0.2))
                }
            }
            .frame(width: 18, height: 18)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(token.symbol)
                        .font(.system(size: 12, weight: .semibold))
                    if token.isSus {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                    }
                }
                Text(token.name)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(formatPrice(token.usdPrice))
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                if let change = token.priceChange24h {
                    Text(formatPercent(change))
                        .font(.system(size: 10))
                        .monospacedDigit()
                        .foregroundStyle(change >= 0 ? .green : .red)
                }
            }
        }
    }

    private func formatPrice(_ price: Decimal?) -> String {
        guard let price else { return "—" }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = price < 1 ? 6 : 2
        return f.string(from: price as NSDecimalNumber) ?? "—"
    }

    private func formatPercent(_ value: Decimal) -> String {
        let v = (value as NSDecimalNumber).doubleValue
        return String(format: "%+.2f%%", v)
    }
}
