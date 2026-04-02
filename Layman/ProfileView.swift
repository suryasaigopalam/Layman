import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ViewModel.self) private var viewModel

    @AppStorage("app_theme_mode") private var appThemeModeRawValue = ViewModel.AppThemeMode.system.rawValue

    @State private var name = "User"
    @State private var draftName = ""
    @State private var isEditingName = false
    @State private var isLoading = false
    @State private var isSavingName = false
    @State private var errorMessage: String?

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.10, green: 0.10, blue: 0.11) : Color(red: 0.96, green: 0.93, blue: 0.89)
    }

    private var cardColor: Color {
        colorScheme == .dark ? Color(red: 0.18, green: 0.18, blue: 0.19) : Color(red: 0.90, green: 0.86, blue: 0.80)
    }

    private var titleColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.12, green: 0.12, blue: 0.12)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    header
                    profileSection
                    modeSection
                    signOutSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationBarHidden(true)
            .task {
                await loadProfile()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Profile")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(titleColor)

            Spacer()

            if isLoading {
                ProgressView()
            }
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Name")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(titleColor.opacity(0.75))

            if isEditingName {
                TextField("Enter your name", text: $draftName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(titleColor)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(cardColor.opacity(0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Text(name)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(titleColor)
            }

            HStack(spacing: 8) {
                if isEditingName {
                    Button("Cancel") {
                        draftName = name
                        isEditingName = false
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(cardColor.opacity(0.9), in: Capsule())
                    .glassEffect(.regular.interactive(), in: Capsule())

                    Button(isSavingName ? "Saving..." : "Save") {
                        Task {
                            await saveName()
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isSavingName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.orange, in: Capsule())
                    .glassEffect(.regular.tint(.orange).interactive(), in: Capsule())
                } else {
                    Button("Change Name") {
                        draftName = name
                        isEditingName = true
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(cardColor.opacity(0.9), in: Capsule())
                    .glassEffect(.regular.interactive(), in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardColor.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appearance")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(titleColor.opacity(0.75))

            Picker(
                "Mode",
                selection: Binding(
                    get: { appThemeModeRawValue },
                    set: { newValue in
                        appThemeModeRawValue = newValue
                        if let mode = ViewModel.AppThemeMode(rawValue: newValue) {
                            viewModel.appThemeMode = mode
                        }
                    }
                )
            ) {
                Text("System").tag(ViewModel.AppThemeMode.system.rawValue)
                Text("Light").tag(ViewModel.AppThemeMode.light.rawValue)
                Text("Dark").tag(ViewModel.AppThemeMode.dark.rawValue)
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardColor.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var signOutSection: some View {
        Button {
            Task {
                await viewModel.signOut()
            }
        } label: {
            Text("Sign Out")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red.opacity(0.85), in: Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(.red).interactive(), in: Capsule())
    }

    @MainActor
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            if let profile = try await viewModel.supabaseManager.fetchCurrentProfile() {
                name = profile.name
            }
        } catch {
            if isMissingSession(error) {
                await viewModel.supabaseManager.refreshSession()
                do {
                    if let profile = try await viewModel.supabaseManager.fetchCurrentProfile() {
                        name = profile.name
                    }
                } catch {
                    errorMessage = "Could not load profile."
                }
            } else {
                errorMessage = "Could not load profile."
            }
        }

        isLoading = false
    }

    @MainActor
    private func saveName() async {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Name cannot be empty."
            return
        }

        isSavingName = true
        errorMessage = nil

        do {
            _ = try await viewModel.supabaseManager.updateCurrentProfileName(trimmed)
            name = trimmed
            isEditingName = false
        } catch {
            if isMissingSession(error) {
                await viewModel.supabaseManager.refreshSession()
                do {
                    _ = try await viewModel.supabaseManager.updateCurrentProfileName(trimmed)
                    name = trimmed
                    isEditingName = false
                } catch {
                    errorMessage = "Could not update name. Please try again."
                }
            } else {
                errorMessage = "Could not update name. Please try again."
            }
        }

        isSavingName = false
    }

    private func isMissingSession(_ error: Error) -> Bool {
        guard let typed = error as? SupaBaseError else { return false }
        return typed == .missingUserSession
    }
}

#Preview {
    ProfileView()
        .environment(ViewModel())
}
