# jupiter-menubar

A native macOS status bar app that surfaces, at a glance:

- **Portfolio** — wallet holdings (SOL + SPL tokens) and DeFi positions across one or many Solana wallets, via Jupiter's Portfolio + Ultra APIs.
- **Lend** — your Jupiter Lend earn positions (token, balance, APR).
- **Trending** — top 10 trending Solana tokens (24h). Click any row to open `jup.ag/?buy=<mint>`.

Auto-refreshes every 5 seconds. API key and wallets are configured in-app (Keychain + UserDefaults — nothing in source).

---

## Requirements

- macOS **13 Ventura or newer** (uses `MenuBarExtra`)
- Xcode 15+ **or** the Command Line Tools (`xcode-select --install`)
- A Jupiter API key from [portal.jup.ag](https://portal.jup.ag/) (free tier works)
- Optional: [`xcodegen`](https://github.com/yonaskolb/XcodeGen) if you want to regenerate the Xcode project (`brew install xcodegen`)

---

## Install

### 1. Clone

```bash
git clone git@github.com:lifeofpavs/jupiter-menubar.git
cd jupiter-menubar
```

### 2. Build

Two paths — pick whichever works on your machine.

**A) `swiftc` build script (always works, no Xcode UI needed)**

```bash
./build.sh
open build-manual/JupiterMenuBar.app
```

This compiles directly with `swiftc`, wraps a proper `.app` bundle, copies the icon, and ad-hoc signs it. Output: `build-manual/JupiterMenuBar.app`.

**B) Xcode**

```bash
xcodegen generate          # (re)generate jupiter-menubar.xcodeproj from project.yml
open jupiter-menubar.xcodeproj
```

Then ⌘R in Xcode.

> If `xcodebuild` complains about a missing `CoreSimulator.framework`, run `sudo xcodebuild -runFirstLaunch` once, or just use path A.

### 3. Launch

After the first launch the Jupiter logo appears in your menu bar (no Dock icon — this is a `LSUIElement` app). Click it to open the popover.

---

## Configure

From the popover footer, click **Settings…**

1. **API key** — paste your key from [portal.jup.ag](https://portal.jup.ag/) and click **Save**. It's stored in the macOS Keychain under service `dev.raccoons.jupiter-menubar`.
2. **Wallets** — paste one or more Solana wallet addresses (base58, 32–44 chars). Add/remove with the buttons. Wallet addresses are stored in `UserDefaults`.

The popover repopulates within 5 s.

---

## Uninstall

```bash
rm -rf build-manual/JupiterMenuBar.app
# remove keychain entry (optional)
security delete-generic-password -s dev.raccoons.jupiter-menubar
# remove preferences (optional)
defaults delete dev.raccoons.jupiter-menubar
```

---

## Project layout

```
jupiter-menubar/
├── App/                 # @main + MenuBarExtra scene
├── Views/               # SwiftUI views (Portfolio / Lend / Trending / Settings)
├── Services/            # JupiterClient + per-API wrappers (Lend, Tokens, Portfolio, Ultra)
├── Models/              # Codable response types
├── State/               # AppViewModel, SettingsStore, KeychainStore
└── Resources/           # Info.plist, Assets.xcassets, entitlements
```

Jupiter endpoints used (base `https://api.jup.ag`, `x-api-key` header on every request):

- `GET /lend/v1/earn/positions?users={csv}`
- `GET /tokens/v2/toptrending/24h?limit=10`
- `GET /tokens/v2/search?query={mints}`
- `GET /portfolio/v1/positions/{wallet}`
- `GET /ultra/v1/holdings/{wallet}`

---

## License

MIT
