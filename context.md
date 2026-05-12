# jupiter-menubar — context

## Purpose
Native macOS status bar app that displays:
- Jupiter Lend earn positions for one or many user-specified wallets
- Top trending Solana tokens (24h window)

Auto-refreshes every 5 seconds. User pastes a Jupiter API key (portal.jup.ag) into Settings.

## Stack
- Swift 5.9, SwiftUI, macOS 13+
- `MenuBarExtra(.window)` for the popover
- Keychain for the API key, UserDefaults for the wallet list
- `URLSession` + `async/await` + `Codable`

## Endpoints (Base: https://api.jup.ag, header x-api-key)
- `GET /lend/v1/earn/positions?users={csv}` → array of `UserPosition`
- `GET /tokens/v2/toptrending/24h?limit=10` → array of trending tokens

## Layout
- `App/` — app entry (`@main`)
- `Views/` — SwiftUI views
- `Services/` — `JupiterClient`, `LendService`, `TokensService`
- `Models/` — Codable response types
- `State/` — `AppViewModel`, `SettingsStore`, `KeychainStore`
- `Resources/` — `Info.plist`, `Assets.xcassets`, entitlements

## Build

Two paths:

**A. Xcode (preferred for development)**
```bash
xcodegen generate                  # regenerate jupiter-menubar.xcodeproj from project.yml
open jupiter-menubar.xcodeproj     # then ⌘R to run
```

**B. Direct swiftc (CI / when xcodebuild misbehaves)**
```bash
./build.sh                         # produces build-manual/JupiterMenuBar.app
open build-manual/JupiterMenuBar.app
```

Note: on this machine `xcodebuild` aborts because `/Library/Developer/PrivateFrameworks/CoreSimulator.framework` is missing. To repair: `sudo xcodebuild -runFirstLaunch` (or reinstall Xcode). The direct swiftc path in `build.sh` works regardless.

## Status
v1 scaffolded and compiling. Code typechecks and links into a working .app bundle.
