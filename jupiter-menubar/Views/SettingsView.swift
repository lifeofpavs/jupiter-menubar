import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var apiKeyDraft: String = ""
    @State private var walletDraft: String = ""
    @State private var addError: String?

    var body: some View {
        Form {
            Section {
                SecureField("Paste key from portal.jup.ag", text: $apiKeyDraft)
                    .textFieldStyle(.roundedBorder)
                HStack(spacing: 8) {
                    Button("Save") {
                        settings.apiKey = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(trimmedKey.isEmpty || trimmedKey == settings.apiKey)
                    Button("Clear") {
                        settings.apiKey = ""
                        apiKeyDraft = ""
                    }
                    .disabled(settings.apiKey.isEmpty)
                    Spacer()
                    if !settings.apiKey.isEmpty {
                        Label("Stored in Keychain", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.green)
                    }
                }
            } header: {
                Text("API key")
                    .font(.system(size: 13, weight: .semibold))
            } footer: {
                Text("Generate a key at portal.jup.ag — it's stored in your macOS Keychain.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack(spacing: 8) {
                    TextField("Solana wallet address", text: $walletDraft)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addWallet)
                    Button("Add", action: addWallet)
                        .buttonStyle(.bordered)
                        .disabled(walletDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if let addError {
                    Label(addError, systemImage: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                }
                if settings.wallets.isEmpty {
                    Text("No wallets yet.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(settings.wallets.enumerated()), id: \.element) { idx, w in
                            walletRow(w)
                            if idx < settings.wallets.count - 1 {
                                Divider().opacity(0.4)
                            }
                        }
                    }
                }
            } header: {
                Text("Wallets")
                    .font(.system(size: 13, weight: .semibold))
            } footer: {
                Text("Add as many Solana wallets as you like — holdings and lend positions show up in the menu.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 460)
        .onAppear { apiKeyDraft = settings.apiKey }
    }

    private var trimmedKey: String {
        apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func walletRow(_ wallet: String) -> some View {
        HStack(spacing: 8) {
            TokenIcon(url: nil, fallback: wallet, size: 22)
            Text(wallet)
                .font(.system(size: 12, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button {
                if let i = settings.wallets.firstIndex(of: wallet) {
                    settings.wallets.remove(at: i)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.85))
            }
            .buttonStyle(.borderless)
            .help("Remove wallet")
        }
        .padding(.vertical, 6)
    }

    private func addWallet() {
        let before = settings.wallets.count
        settings.addWallet(walletDraft)
        if settings.wallets.count == before {
            addError = "That doesn't look like a valid Solana address."
        } else {
            walletDraft = ""
            addError = nil
        }
    }
}
