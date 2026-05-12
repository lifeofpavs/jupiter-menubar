import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var apiKeyDraft: String = ""
    @State private var walletDraft: String = ""
    @State private var addError: String?

    var body: some View {
        Form {
            Section("Jupiter API key") {
                SecureField("Paste key from portal.jup.ag", text: $apiKeyDraft)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Save") {
                        settings.apiKey = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    .disabled(apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Clear") {
                        settings.apiKey = ""
                        apiKeyDraft = ""
                    }
                    .disabled(settings.apiKey.isEmpty)
                    Spacer()
                    if !settings.apiKey.isEmpty {
                        Label("Stored in Keychain", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                    }
                }
            }

            Section("Wallets") {
                HStack {
                    TextField("Solana wallet address", text: $walletDraft)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addWallet)
                    Button("Add", action: addWallet)
                        .disabled(walletDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if let addError {
                    Text(addError)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                }
                if settings.wallets.isEmpty {
                    Text("No wallets yet.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    List {
                        ForEach(settings.wallets, id: \.self) { w in
                            HStack {
                                Text(w).font(.system(.body, design: .monospaced))
                                Spacer()
                                Button(role: .destructive) {
                                    if let i = settings.wallets.firstIndex(of: w) {
                                        settings.wallets.remove(at: i)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .frame(minHeight: 100, maxHeight: 200)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 420)
        .onAppear { apiKeyDraft = settings.apiKey }
    }

    private func addWallet() {
        let before = settings.wallets.count
        settings.addWallet(walletDraft)
        if settings.wallets.count == before {
            addError = "Invalid Solana address."
        } else {
            walletDraft = ""
            addError = nil
        }
    }
}
