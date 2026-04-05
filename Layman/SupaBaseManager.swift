import Foundation
import Supabase

final class SupaBaseManager {
    private let client: SupabaseClient

    private(set) var authSession: Session?

    init() {
        guard
            let urlString = AppConfig.value(for: "SUPABASE_URL"),
            !AppConfig.isUnresolvedBuildSetting(urlString),
            let parsedURL = URL(string: urlString),
            parsedURL.host != nil,
            let key = AppConfig.value(for: "SUPABASE_ANON_KEY"),
            !AppConfig.isUnresolvedBuildSetting(key)
        else {
            fatalError("Invalid SUPABASE_URL or SUPABASE_ANON_KEY. Verify Config.xcconfig is linked to your target and SUPABASE_URL uses https:/$()/... format.")
        }

        self.client = SupabaseClient(
            supabaseURL: parsedURL,
            supabaseKey: key,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }

    // MARK: - Auth

    func refreshSession() async {
        do {
            authSession = try await client.auth.session
        } catch {
            authSession = nil
        }
    }

    @discardableResult
    func signUp(name: String, email: String, password: String) async throws -> Session? {
        _ = try await client.auth.signUp(
            email: email,
            password: password
        )

        authSession = try? await client.auth.session

        // If Confirm email is disabled, session exists and we can store name immediately.
        if authSession != nil {
            _ = try? await updateCurrentProfileName(name)
        }

        return authSession
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> Session {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        authSession = session
        return session
    }

    func signOut() async throws {
        try await client.auth.signOut()
        authSession = nil
    }

    // MARK: - Profile

    func fetchCurrentProfile() async throws -> SupabaseProfile? {
        let userID = try currentUserIDString()

        let rows: [SupabaseProfile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userID)
            .execute()
            .value

        return rows.first
    }

    @discardableResult
    func updateCurrentProfileName(_ name: String) async throws -> SupabaseProfile {
        let userID = try currentUserIDString()

        let rows: [SupabaseProfile] = try await client
            .from("profiles")
            .upsert(
                ProfileUpsertPayload(id: userID, name: name),
                onConflict: "id"
            )
            .select()
            .execute()
            .value

        guard let profile = rows.first else {
            throw SupaBaseError.invalidResponse
        }

        return profile
    }

    // MARK: - Saved Articles

    func fetchSavedArticles() async throws -> [SavedArticle] {
        let userID = try currentUserIDString()

        let rows: [SavedArticle] = try await client
            .from("saved_articles")
            .select()
            .eq("user_id", value: userID)
            .order("saved_at", ascending: false)
            .execute()
            .value

        return rows
    }

    @discardableResult
    func saveArticle(_ article: Article) async throws -> SavedArticle {
        let userID = try currentUserIDString()

        let rows: [SavedArticle] = try await client
            .from("saved_articles")
            .upsert(
                SavedArticleInsertPayload(
                    userID: userID,
                    articleURL: article.url,
                    title: article.title,
                    sourceName: article.source.name,
                    imageURL: article.urlToImage
                ),
                onConflict: "user_id,article_url"
            )
            .select()
            .execute()
            .value

        guard let row = rows.first else {
            throw SupaBaseError.invalidResponse
        }

        return row
    }

    func removeSavedArticle(articleURL: String) async throws {
        let userID = try currentUserIDString()

        _ = try await client
            .from("saved_articles")
            .delete()
            .eq("user_id", value: userID)
            .eq("article_url", value: articleURL)
            .execute()
    }

    // MARK: - Helpers

    private func currentUserIDString() throws -> String {
        guard let session = authSession else {
            throw SupaBaseError.missingUserSession
        }

        return String(describing: session.user.id)
    }
}

struct SupabaseProfile: Codable {
    let id: String
    let name: String
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SavedArticle: Codable, Identifiable {
    let id: String
    let userID: String
    let articleURL: String
    let title: String
    let sourceName: String?
    let imageURL: String?
    let savedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case articleURL = "article_url"
        case title
        case sourceName = "source_name"
        case imageURL = "image_url"
        case savedAt = "saved_at"
    }
}

private struct ProfileUpsertPayload: Encodable {
    let id: String
    let name: String
}

private struct SavedArticleInsertPayload: Encodable {
    let userID: String
    let articleURL: String
    let title: String
    let sourceName: String?
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case articleURL = "article_url"
        case title
        case sourceName = "source_name"
        case imageURL = "image_url"
    }
}

enum SupaBaseError: LocalizedError, Equatable {
    case invalidResponse
    case missingUserSession

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid Supabase response."
        case .missingUserSession:
            return "No active user session found."
        }
    }
}
