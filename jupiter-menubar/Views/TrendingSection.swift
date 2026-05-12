import SwiftUI

struct TrendingSection: View {
    let tokens: [TrendingToken]
    let error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("Trending · 24h")
                    .sectionLabel()
                Spacer()
                Text("Tap to buy")
                    .sectionLabel()
                    .opacity(0.55)
            }
            .padding(.horizontal, Theme.Space.s)
            .padding(.top, 2)

            if let error {
                ErrorBanner(text: error)
            }
            if tokens.isEmpty && error == nil {
                LoadingRow()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(tokens.enumerated()), id: \.element.id) { i, token in
                        Button {
                            if let url = URL(string: "https://jup.ag/?buy=\(token.id)") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            TrendingRow(rank: i + 1, token: token)
                        }
                        .buttonStyle(.plain)
                        .help("Open jup.ag/?buy=\(token.symbol)")
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Space.m + 4)
    }
}

private struct TrendingRow: View {
    let rank: Int
    let token: TrendingToken

    var body: some View {
        HoverableRow {
            HStack(spacing: Theme.Space.s) {
                Text("\(rank)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
                    .frame(width: 16, alignment: .trailing)

                TokenIcon(url: token.icon, fallback: token.symbol, size: 26)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(token.symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        if token.isSus {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.orange)
                                .help("Flagged as suspicious")
                        }
                    }
                    Text(token.name)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Format.price(token.usdPrice))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    if let change = token.priceChange24h {
                        ChangePill(value: change)
                    }
                }
            }
        }
    }
}

private struct ChangePill: View {
    let value: Decimal

    var body: some View {
        let positive = value >= 0
        let magnitude = abs((value as NSDecimalNumber).doubleValue)
        HStack(spacing: 2) {
            Image(systemName: positive ? "arrow.up" : "arrow.down")
                .font(.system(size: 7, weight: .bold))
            Text(String(format: "%.2f%%", magnitude))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(positive ? .green : .red)
        .padding(.horizontal, 5)
        .padding(.vertical, 1.5)
        .background(
            Capsule().fill((positive ? Color.green : Color.red).opacity(0.14))
        )
    }
}
