import Foundation

@Observable
@MainActor
class ViewModel {
    enum AppThemeMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }
    }

    let networkManager = NetworkManager()

    var currrentCategory = Category.general

    var headLinesStatus = FetchStatus.notStarted
    var categoryStatus = FetchStatus.notStarted

    var supabaseManager = SupaBaseManager()

    var isAuthen = false
    var appThemeMode: AppThemeMode {
        didSet {
            UserDefaults.standard.set(appThemeMode.rawValue, forKey: "app_theme_mode")
        }
    }

    var headLineNews: [Article] = []
    var categoryNews: [Article] = []

    init() {
        if let raw = UserDefaults.standard.string(forKey: "app_theme_mode"),
           let mode = AppThemeMode(rawValue: raw) {
            appThemeMode = mode
        } else {
            appThemeMode = .system
        }
    }

    func fetchHeadLines() async {
        headLinesStatus = .loading
        do {
            let headLineResponse = try await networkManager.getHeadLines()
            headLineNews = headLineResponse.articles
            headLinesStatus = .success
        } catch {
            headLinesStatus = .failed(error)
        }
    }

    func fetchCategory() async {
        categoryStatus = .loading
        do {
            let response = try await networkManager.getCategory(category: currrentCategory)
            categoryNews = response.articles
            categoryStatus = .success
        } catch {
            categoryStatus = .failed(error)
        }
    }

    func signIn(email: String, password: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            throw AuthFlowError.missingFields
        }

        _ = try await supabaseManager.signIn(email: trimmedEmail, password: trimmedPassword)
        isAuthen = true
    }

    func signUp(name: String, email: String, password: String) async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            throw AuthFlowError.missingFields
        }

        guard trimmedPassword.count >= 6 else {
            throw AuthFlowError.weakPassword
        }

        let session = try await supabaseManager.signUp(
            name: trimmedName,
            email: trimmedEmail,
            password: trimmedPassword
        )

        guard session != nil else {
            throw AuthFlowError.confirmEmailRequired
        }

        isAuthen = true
    }

    func signOut() async {
        do {
            try await supabaseManager.signOut()
        } catch {
            // Force local sign-out even if remote sign-out fails.
        }
        isAuthen = false
    }

    func authErrorMessage(from error: Error) -> String {
        if let authError = error as? AuthFlowError {
            return authError.localizedDescription
        }

        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        return message.isEmpty ? "A specific error has occurred. Please try again." : message
    }
}

enum AuthFlowError: LocalizedError {
    case missingFields
    case weakPassword
    case confirmEmailRequired

    var errorDescription: String? {
        switch self {
        case .missingFields:
            return "Please fill in all required fields and try again."
        case .weakPassword:
            return "Password should be at least 6 characters."
        case .confirmEmailRequired:
            return "Account created. Please confirm your email before signing in."
        }
    }
}
