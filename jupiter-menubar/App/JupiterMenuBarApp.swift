import SwiftUI

@main
struct JupiterMenuBarApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var viewModel: AppViewModel

    init() {
        let store = SettingsStore()
        _settings = StateObject(wrappedValue: store)
        _viewModel = StateObject(wrappedValue: AppViewModel(settings: store))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(viewModel)
                .environmentObject(settings)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(settings)
        }
        .windowResizability(.contentSize)
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        if let ns = NSImage(named: "MenuBarIcon") {
            Image(nsImage: ns)
        } else {
            Image(systemName: "chart.line.uptrend.xyaxis")
        }
    }
}
