import SwiftUI

enum Theme {
    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let s: CGFloat = 6
        static let m: CGFloat = 10
        static let l: CGFloat = 14
    }

    static let popoverWidth: CGFloat = 380
    static let popoverMaxHeight: CGFloat = 480
}

extension View {
    func sectionLabel() -> some View {
        self
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(.tertiary)
    }

    func heroNumber() -> some View {
        self
            .font(.system(size: 32, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
    }
}

struct TokenIcon: View {
    let url: URL?
    let fallback: String
    let size: CGFloat

    init(url: URL? = nil, fallback: String, size: CGFloat = 24) {
        self.url = url
        self.fallback = fallback
        self.size = size
    }

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: letterFallback
                    }
                }
            } else {
                letterFallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle().strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private var letterFallback: some View {
        ZStack {
            Circle().fill(
                LinearGradient(
                    colors: [fallbackColor.opacity(0.35), fallbackColor.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            Text(String(fallback.prefix(1)).uppercased())
                .font(.system(size: size * 0.46, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.7))
        }
    }

    private var fallbackColor: Color {
        let palette: [Color] = [.blue, .purple, .pink, .orange, .yellow, .green, .teal, .indigo, .mint, .cyan]
        let hash = fallback.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[hash % palette.count]
    }
}

struct HoverableRow<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var hovering = false

    var body: some View {
        content()
            .padding(.horizontal, Theme.Space.s)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                    .fill(Color.primary.opacity(hovering ? 0.06 : 0))
            )
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

struct ErrorBanner: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.s) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.red)
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.primary)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                .fill(Color.red.opacity(0.08))
        )
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 2)
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 28)
        .padding(.horizontal, Theme.Space.m)
        .frame(maxWidth: .infinity)
    }
}

struct LoadingRow: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Loading")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
}

enum Format {
    static func usd(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f.string(from: d as NSDecimalNumber) ?? "$0.00"
    }

    static func price(_ d: Decimal?) -> String {
        guard let d else { return "—" }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        if d == 0 {
            f.maximumFractionDigits = 2
        } else if d < 0.001 {
            f.maximumFractionDigits = 8
        } else if d < 1 {
            f.maximumFractionDigits = 4
        } else {
            f.maximumFractionDigits = 2
        }
        return f.string(from: d as NSDecimalNumber) ?? "—"
    }

    static func amount(_ d: Decimal, maxFractionDigits: Int = 4) -> String {
        let f = NumberFormatter()
        f.usesGroupingSeparator = true
        if d >= 1000 {
            f.maximumFractionDigits = 0
        } else if d < 1 {
            f.maximumFractionDigits = maxFractionDigits
        } else {
            f.maximumFractionDigits = 2
        }
        f.minimumFractionDigits = 0
        return f.string(from: d as NSDecimalNumber) ?? "0"
    }

    static func shortAddress(_ a: String) -> String {
        guard a.count > 10 else { return a }
        return "\(a.prefix(4))…\(a.suffix(4))"
    }
}
