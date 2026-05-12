import SwiftUI

enum MenuTab: String, CaseIterable, Identifiable {
    case portfolio = "Portfolio"
    case lend = "Lend"
    case trending = "Trending"
    var id: String { rawValue }
}

struct MenuContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.openWindow) private var openWindow
    @State private var tab: MenuTab = .portfolio

    var body: some View {
        VStack(spacing: 0) {
            if settings.apiKey.isEmpty {
                noKeyState
            } else {
                hero
                TabBar(selection: $tab)
                    .padding(.horizontal, Theme.Space.m + 2)
                    .padding(.bottom, Theme.Space.s)
                ScrollView {
                    content
                        .padding(.bottom, Theme.Space.s)
                }
                .frame(maxHeight: Theme.popoverMaxHeight)
            }
            footer
        }
        .frame(width: Theme.popoverWidth)
        .task { viewModel.start() }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .portfolio:
            PortfolioSection(
                portfolios: viewModel.portfolios,
                wallets: settings.wallets,
                error: viewModel.portfolioError,
                onOpenSettings: { openWindow(id: "settings") }
            )
            .transition(.opacity)
        case .lend:
            PositionsSection(
                positions: viewModel.positions,
                markets: viewModel.lendMarkets,
                wallets: settings.wallets,
                positionsError: viewModel.positionsError,
                marketsError: viewModel.lendMarketsError,
                onOpenSettings: { openWindow(id: "settings") }
            )
            .transition(.opacity)
        case .trending:
            TrendingSection(
                tokens: viewModel.trending,
                error: viewModel.trendingError
            )
            .transition(.opacity)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Net worth")
                .sectionLabel()
            Text(Format.usd(grandTotal))
                .heroNumber()
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.4), value: grandTotal)
            Text(updatedLabel)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Space.m + 4)
        .padding(.top, Theme.Space.l)
        .padding(.bottom, Theme.Space.m)
    }

    private var grandTotal: Decimal {
        viewModel.portfolios.map(\.total).reduce(0, +)
    }

    private var updatedLabel: String {
        if settings.wallets.isEmpty {
            return "Add a wallet to start tracking."
        }
        if let updated = viewModel.lastUpdated {
            return "Updated \(updated.formatted(date: .omitted, time: .shortened)) · \(settings.wallets.count) wallet\(settings.wallets.count == 1 ? "" : "s")"
        }
        return "Refreshing…"
    }

    private var noKeyState: some View {
        VStack(spacing: Theme.Space.m) {
            Image(systemName: "key.horizontal")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.tertiary)
            VStack(spacing: 4) {
                Text("Add a Jupiter API key")
                    .font(.system(size: 14, weight: .semibold))
                Text("Generate one at portal.jup.ag,\nthen paste it in Settings.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Open Settings…") { openWindow(id: "settings") }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.top, 4)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 0) {
            FooterButton(title: "Settings", systemImage: "gearshape") {
                openWindow(id: "settings")
            }
            Spacer()
            FooterButton(title: "Quit", systemImage: "power") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, Theme.Space.s + 2)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.35))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(.quaternary),
            alignment: .top
        )
    }
}

private struct FooterButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 11, weight: .medium))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundStyle(hovering ? .primary : .secondary)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.primary.opacity(hovering ? 0.08 : 0))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

private struct TabBar: View {
    @Binding var selection: MenuTab
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MenuTab.allCases) { t in
                tabButton(t)
            }
        }
        .padding(3)
        .background(
            Capsule().fill(.quaternary.opacity(0.55))
        )
    }

    private func tabButton(_ t: MenuTab) -> some View {
        let selected = selection == t
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                selection = t
            }
        } label: {
            Text(t.rawValue)
                .font(.system(size: 12, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? .primary : .secondary)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .background {
                    if selected {
                        Capsule()
                            .fill(.background)
                            .shadow(color: .black.opacity(0.12), radius: 2.5, y: 1)
                            .matchedGeometryEffect(id: "selectedTab", in: ns)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
