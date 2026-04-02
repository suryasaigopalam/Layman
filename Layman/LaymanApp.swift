import SwiftUI

@main
struct LaymanApp: App {
    @State private var viewModel = ViewModel()
    @AppStorage("app_theme_mode") private var appThemeModeRawValue = ViewModel.AppThemeMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            WelcomeScreen()
                .environment(viewModel)
                .preferredColorScheme(preferredColorScheme(for: currentThemeMode))
        }
    }

    private var currentThemeMode: ViewModel.AppThemeMode {
        ViewModel.AppThemeMode(rawValue: appThemeModeRawValue) ?? .system
    }

    private func preferredColorScheme(for mode: ViewModel.AppThemeMode) -> ColorScheme? {
        switch mode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
