//
//  ContentView.swift
//  Layman
//
//  Created by Surya Sai Gopalam on 31/03/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(ViewModel.self) var viewModel
    @AppStorage("app_theme_mode") private var appThemeModeRawValue = ViewModel.AppThemeMode.system.rawValue

    var body: some View {
        Group {
            if !viewModel.isAuthen {
                AuthView()
            } else {
                LaymanTabView()
            }
        }
        .preferredColorScheme(preferredColorScheme)
    }

    private var preferredColorScheme: ColorScheme? {
        switch ViewModel.AppThemeMode(rawValue: appThemeModeRawValue) ?? .system {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

#Preview {
    ContentView()
        .environment(ViewModel())
}
