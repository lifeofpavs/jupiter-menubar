import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var positions: [LendPosition] = []
    @Published private(set) var trending: [TrendingToken] = []
    @Published private(set) var portfolios: [WalletPortfolio] = []
    @Published private(set) var positionsError: String?
    @Published private(set) var trendingError: String?
    @Published private(set) var portfolioError: String?
    @Published private(set) var lastUpdated: Date?

    private let settings: SettingsStore
    private let lend = LendService()
    private let tokens = TokensService()
    private let portfolio = PortfolioService()
    private let ultra = UltraService()
    private var refreshTask: Task<Void, Never>?

    private var positionsBackoff: TimeInterval = 0
    private var trendingBackoff: TimeInterval = 0
    private var portfolioBackoff: TimeInterval = 0
    private let baseInterval: TimeInterval = 5
    private let maxBackoff: TimeInterval = 60

    init(settings: SettingsStore) {
        self.settings = settings
        Task { await JupiterClient.shared.setApiKeyProvider { [weak settings] in settings?.apiKey } }
    }

    func start() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshAll()
                let delay = max(self?.baseInterval ?? 5, self?.nextDelay() ?? 5)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func nextDelay() -> TimeInterval {
        max(baseInterval, min(positionsBackoff, trendingBackoff).nonZeroOr(baseInterval))
    }

    private func refreshAll() async {
        async let positionsResult: () = refreshPositions()
        async let trendingResult: () = refreshTrending()
        async let portfolioResult: () = refreshPortfolios()
        _ = await (positionsResult, trendingResult, portfolioResult)
        lastUpdated = Date()
    }

    private func refreshPortfolios() async {
        if portfolioBackoff > 0 {
            portfolioBackoff = max(0, portfolioBackoff - baseInterval)
            return
        }
        let wallets = settings.wallets
        guard !wallets.isEmpty else {
            portfolios = []
            portfolioError = nil
            return
        }
        let results: [WalletPortfolio] = await withTaskGroup(of: WalletPortfolio.self) { group in
            for wallet in wallets {
                group.addTask { [portfolio, ultra, tokens] in
                    await Self.fetchWallet(wallet: wallet, portfolio: portfolio, ultra: ultra, tokens: tokens)
                }
            }
            var collected: [WalletPortfolio] = []
            for await item in group { collected.append(item) }
            return collected
        }
        let byWallet = Dictionary(uniqueKeysWithValues: results.map { ($0.wallet, $0) })
        portfolios = wallets.compactMap { byWallet[$0] }
        let firstError = portfolios.compactMap(\.error).first
        portfolioError = firstError
        if let firstError, firstError.contains("Rate limited") {
            portfolioBackoff = 20
        }
    }

    private func refreshPositions() async {
        if positionsBackoff > 0 {
            positionsBackoff = max(0, positionsBackoff - baseInterval)
            return
        }
        let wallets = settings.wallets
        guard !wallets.isEmpty else {
            positions = []
            positionsError = nil
            return
        }
        do {
            positions = try await lend.positions(for: wallets)
            positionsError = nil
        } catch let error as JupiterError {
            positionsError = error.errorDescription
            if case .rateLimited(let retry) = error {
                positionsBackoff = min(maxBackoff, retry)
            }
        } catch {
            positionsError = error.localizedDescription
        }
    }

    private func refreshTrending() async {
        if trendingBackoff > 0 {
            trendingBackoff = max(0, trendingBackoff - baseInterval)
            return
        }
        do {
            trending = try await tokens.topTrending(interval: "24h", limit: 10)
            trendingError = nil
        } catch let error as JupiterError {
            trendingError = error.errorDescription
            if case .rateLimited(let retry) = error {
                trendingBackoff = min(maxBackoff, retry)
            }
        } catch {
            trendingError = error.localizedDescription
        }
    }
}

private extension TimeInterval {
    func nonZeroOr(_ fallback: TimeInterval) -> TimeInterval {
        self > 0 ? self : fallback
    }
}

extension AppViewModel {
    static func fetchWallet(
        wallet: String,
        portfolio: PortfolioService,
        ultra: UltraService,
        tokens: TokensService
    ) async -> WalletPortfolio {
        async let portfolioResp = try? await portfolio.positions(for: wallet)
        async let holdingsResp = try? await ultra.holdings(for: wallet)
        let p = await portfolioResp
        let h = await holdingsResp

        var walletTokens: [WalletToken] = []
        if let h, !h.allMints.isEmpty {
            let metaList = (try? await tokens.search(mints: h.allMints)) ?? []
            let metaMap = Dictionary(uniqueKeysWithValues: metaList.map { ($0.id, $0) })
            walletTokens = h.walletTokens(metadata: metaMap)
        }

        let elements = p?.elements ?? []
        let tokenInfo = p?.tokenInfo
        let bothFailed = p == nil && h == nil
        return WalletPortfolio(
            wallet: wallet,
            elements: elements,
            tokens: tokenInfo,
            walletTokens: walletTokens,
            error: bothFailed ? "Failed to load wallet" : nil
        )
    }
}
