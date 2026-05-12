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
                Picker("", selection: $tab) {
                    ForEach(MenuTab.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 4)

                ScrollView {
                    switch tab {
                    case .portfolio:
                        PortfolioSection(
                            portfolios: viewModel.portfolios,
                            wallets: settings.wallets,
                            error: viewModel.portfolioError,
                            onOpenSettings: { openWindow(id: "settings") }
                        )
                    case .lend:
                        PositionsSection(
                            positions: viewModel.positions,
                            wallets: settings.wallets,
                            error: viewModel.positionsError,
                            onOpenSettings: { openWindow(id: "settings") }
                        )
                    case .trending:
                        TrendingSection(
                            tokens: viewModel.trending,
                            error: viewModel.trendingError
                        )
                    }
                }
                .frame(maxHeight: 460)
            }
            Divider()
            footer
        }
        .frame(width: 360)
        .task { viewModel.start() }
    }

    private var noKeyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "key.horizontal")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
            Text("Add a Jupiter API key")
                .font(.system(size: 12, weight: .semibold))
            Text("Get one from portal.jup.ag, then paste it in Settings.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings…") { openWindow(id: "settings") }
                .buttonStyle(.borderedProminent)
        }
        .padding(20)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if let updated = viewModel.lastUpdated {
                Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button("Settings…") { openWindow(id: "settings") }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
