import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @Published var wallets: [String] {
        didSet { defaults.set(wallets, forKey: walletsKey) }
    }
    @Published var apiKey: String {
        didSet {
            if apiKey.isEmpty { KeychainStore.clear() } else { KeychainStore.save(apiKey) }
        }
    }

    private let defaults: UserDefaults
    private let walletsKey = "jupiter.wallets"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.wallets = defaults.stringArray(forKey: walletsKey) ?? []
        self.apiKey = KeychainStore.read() ?? ""
    }

    func addWallet(_ address: String) {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidSolanaAddress(trimmed), !wallets.contains(trimmed) else { return }
        wallets.append(trimmed)
    }

    func removeWallet(at offsets: IndexSet) {
        wallets.remove(atOffsets: offsets)
    }

    private func isValidSolanaAddress(_ s: String) -> Bool {
        guard (32...44).contains(s.count) else { return false }
        let base58 = Set("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
        return s.allSatisfy { base58.contains($0) }
    }
}
