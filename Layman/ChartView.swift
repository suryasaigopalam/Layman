import SwiftUI

struct ChartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let article: Article

    @State private var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Hi, I’m Layman! What can I answer for you?")
    ]
    @State private var suggestionQuestions: [String] = []
    @State private var hasLoadedSuggestions = false
    @State private var inputText = ""
    @State private var isSending = false
    @State private var errorText: String?

    private let apiClient = GeminiChatClient()

    init(article: Article = .previewArticle) {
        self.article = article
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.13) : Color(red: 0.95, green: 0.90, blue: 0.84)
    }

    private var cardColor: Color {
        colorScheme == .dark ? Color(red: 0.19, green: 0.19, blue: 0.20) : Color(red: 0.90, green: 0.83, blue: 0.74)
    }

    private var textColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.13, green: 0.13, blue: 0.13)
    }

    var body: some View {
        VStack(spacing: 10) {
            topBar

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { message in
                            messageRow(message)
                                .id(message.id)
                        }

                        suggestionSection

                        if let errorText {
                            Text(errorText)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.red)
                                .padding(.horizontal, 8)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: messages.count) {
                    guard let lastID = messages.last?.id else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }

            inputBar
        }
        .padding(.top, 12)
        .background(backgroundColor.ignoresSafeArea())
        .task {
            await loadSuggestionsIfNeeded()
        }
    }

    @MainActor
    private func loadSuggestionsIfNeeded() async {
        guard !hasLoadedSuggestions else { return }
        hasLoadedSuggestions = true
        let fallback = SuggestionBuilder.fallbackSuggestions(from: article)
        suggestionQuestions = fallback

        do {
            let generated = try await apiClient.generateSuggestions(article: article)
            if !generated.isEmpty {
                var merged = generated
                if merged.count < 3 {
                    for question in fallback where !merged.contains(where: { $0.caseInsensitiveCompare(question) == .orderedSame }) {
                        merged.append(question)
                        if merged.count == 3 { break }
                    }
                }
                suggestionQuestions = Array(merged.prefix(3))
            }
        } catch {
            // Keep fallback suggestions if generation fails.
        }
    }

    private var topBar: some View {
        ZStack {
            Capsule()
                .fill(textColor.opacity(0.2))
                .frame(width: 40, height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 32)
        .overlay(alignment: .leading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(textColor.opacity(0.7))
                    .frame(width: 30, height: 30)
                    .background(cardColor.opacity(0.8), in: Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .padding(.leading, 12)
            .padding(.top, 2)
        }
    }

    private func messageRow(_ message: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color(red: 0.79, green: 0.37, blue: 0.18), in: Circle())

                chatBubble(for: message)

                Spacer(minLength: 28)
            } else {
                Spacer(minLength: 28)

                chatBubble(for: message)

                Image(systemName: "person.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color(red: 0.79, green: 0.37, blue: 0.18), in: Circle())
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func chatBubble(for message: ChatMessage) -> some View {
        Text(message.text)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .foregroundStyle(message.role == .assistant ? textColor : .white)
            .background(
                message.role == .assistant ? cardColor : Color(red: 0.79, green: 0.37, blue: 0.18),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question Suggestions")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(textColor.opacity(0.65))

            LazyVStack(alignment: .leading, spacing: 7) {
                ForEach(suggestionQuestions, id: \.self) { question in
                    Button {
                        inputText = question
                        Task {
                            await sendMessage(question)
                        }
                    } label: {
                        Text(question)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.79, green: 0.37, blue: 0.18), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)
                    .glassEffect(.regular.interactive(), in: Capsule())
                }
            }
        }
        .padding(.top, 4)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Type your question...", text: $inputText)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(textColor)

            Button {
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(textColor.opacity(0.75))
                    .frame(width: 24, height: 24)
                    .background(cardColor, in: Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())

            Button {
                Task {
                    await sendMessage(inputText)
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Color(red: 0.79, green: 0.37, blue: 0.18), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(isSending || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .glassEffect(.regular.tint(Color(red: 0.79, green: 0.37, blue: 0.18)).interactive(), in: Circle())
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
        .background(cardColor, in: Capsule())
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    @MainActor
    private func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isSending else { return }

        errorText = nil
        inputText = ""
        isSending = true
        messages.append(ChatMessage(role: .user, text: trimmed))

        do {
            let reply = try await apiClient.sendMessage(userMessage: trimmed, article: article, history: messages)
            messages.append(ChatMessage(role: .assistant, text: reply))
        } catch {
            let friendly = (error as? LocalizedError)?.errorDescription ?? "Couldn’t get a response. Check API key/network and try again."
            errorText = friendly
        }

        isSending = false
    }
}

private struct ChatMessage: Identifiable {
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
}

private enum SuggestionBuilder {
    static func fallbackSuggestions(from article: Article) -> [String] {
        let sourceName = article.source.name
        let topic = article.title
            .split(separator: " ")
            .prefix(6)
            .joined(separator: " ")

        return [
            "Can you explain this article in very simple words?",
            "What is the most important takeaway about \(topic)?",
            "How could this affect regular people based on \(sourceName)?"
        ].map { suggestion in
            suggestion.count > 90 ? String(suggestion.prefix(90)) : suggestion
        }
    }
}

private struct GeminiChatClient {
    func sendMessage(userMessage: String, article: Article, history: [ChatMessage]) async throws -> String {
        let apiKey = try loadAPIKey()

        let context = """
        Title: \(article.title)
        Source: \(article.source.name)
        Description: \(article.description ?? "N/A")
        Content: \(article.content ?? "N/A")
        """

        let recentHistory = history
            .dropLast(
                (history.last?.role == .user && history.last?.text == userMessage) ? 1 : 0
            )
        let recent = recentHistory.suffix(8).map { item in
            GeminiContent(
                role: item.role == .user ? "user" : "model",
                parts: [GeminiPart(text: item.text)]
            )
        }

        var contents = recent
        contents.append(
            GeminiContent(
                role: "user",
                parts: [GeminiPart(text: userMessage)]
            )
        )

        let requestBody = GeminiGenerateRequest(
            systemInstruction: GeminiContent(
                role: "system",
                parts: [GeminiPart(text: """
                You are Layman, a concise AI that explains news in simple language.
                Rules:
                - Reply in 1-2 complete sentences.
                - Do not use fragments, sentence starters, or bullet points.
                - Keep the answer between 14 and 40 words.
                - Keep it directly relevant to this article context: \(context)
                """)]
            ),
            contents: contents,
            generationConfig: GeminiGenerationConfig(
                temperature: 0.4,
                maxOutputTokens: 120
            )
        )

        let decoded = try await performGenerate(requestBody: requestBody, apiKey: apiKey)
        guard let rawText = extractText(from: decoded) else {
            throw ChatError.emptyResponse
        }

        let cleanedText = normalizeReply(rawText)
        if isLowQualityReply(cleanedText) {
            let repaired = try await regenerateCleanReply(
                userMessage: userMessage,
                article: article,
                draftReply: cleanedText,
                apiKey: apiKey
            )
            if isLowQualityReply(repaired) {
                return fallbackReply(article: article)
            }
            return repaired
        }

        return cleanedText
    }

    func generateSuggestions(article: Article) async throws -> [String] {
        let apiKey = try loadAPIKey()
        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)")!

        let context = """
        Title: \(article.title)
        Source: \(article.source.name)
        Description: \(article.description ?? "N/A")
        Content: \(article.content ?? "N/A")
        """

        let requestBody = GeminiGenerateRequest(
            systemInstruction: GeminiContent(
                role: "system",
                parts: [GeminiPart(text: "Generate exactly 3 short, specific user questions based on the article context. Questions must be practical, simple, and directly related to this article. Output only a JSON array of 3 strings, nothing else.")]
            ),
            contents: [
                GeminiContent(
                    role: "user",
                    parts: [GeminiPart(text: context)]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.2,
                maxOutputTokens: 140
            )
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown API error"
            throw ChatError.apiFailure(message)
        }

        let decoded = try JSONDecoder().decode(GeminiGenerateResponse.self, from: data)
        guard let text = extractText(from: decoded) else {
            throw ChatError.emptyResponse
        }

        return parseSuggestionText(text)
    }

    private func loadAPIKey() throws -> String {
        if let value = AppConfig.value(for: "GEMINI_API_KEY"),
           !AppConfig.isUnresolvedBuildSetting(value) {
            return value
        }

        throw ChatError.missingAPIKey
    }

    private func performGenerate(requestBody: GeminiGenerateRequest, apiKey: String) async throws -> GeminiGenerateResponse {
        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown API error"
            throw ChatError.apiFailure(message)
        }

        return try JSONDecoder().decode(GeminiGenerateResponse.self, from: data)
    }

    private func regenerateCleanReply(userMessage: String, article: Article, draftReply: String, apiKey: String) async throws -> String {
        let repairRequest = GeminiGenerateRequest(
            systemInstruction: GeminiContent(
                role: "system",
                parts: [GeminiPart(text: """
                Rewrite the draft into a clear layman answer.
                Must be 1-2 complete sentences, no fragments, no bullets.
                Keep between 14 and 40 words.
                Keep it grounded in the provided article context.
                Return plain text only.
                """)]
            ),
            contents: [
                GeminiContent(
                    role: "user",
                    parts: [GeminiPart(text: """
                    Article title: \(article.title)
                    Article source: \(article.source.name)
                    Article description: \(article.description ?? "N/A")
                    Article content: \(article.content ?? "N/A")
                    User question: \(userMessage)
                    Draft answer: \(draftReply)
                    """)]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.2,
                maxOutputTokens: 120
            )
        )

        let decoded = try await performGenerate(requestBody: repairRequest, apiKey: apiKey)
        guard
            let repaired = extractText(from: decoded),
            !repaired.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw ChatError.emptyResponse
        }

        return normalizeReply(repaired)
    }

    private func extractText(from response: GeminiGenerateResponse) -> String? {
        let combined = response.candidates
            .flatMap { $0.content.parts }
            .compactMap(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return combined.isEmpty ? nil : combined
    }

    private func normalizeReply(_ text: String) -> String {
        let withoutBullets = text.replacingOccurrences(
            of: #"^\s*[-•\d\.\)]\s*"#,
            with: "",
            options: .regularExpression
        )

        let collapsed = withoutBullets
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return collapsed
    }

    private func isLowQualityReply(_ text: String) -> Bool {
        let words = text.split(whereSeparator: \.isWhitespace).count
        let hasSentenceEnd = text.contains(".") || text.contains("?") || text.contains("!")
        return words < 8 || !hasSentenceEnd
    }

    private func fallbackReply(article: Article) -> String {
        let description = article.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let description, !description.isEmpty {
            return "In simple terms, this article says \(description)"
        }

        return "In simple terms, this article is about \(article.title), and the main point is that it can directly affect people depending on what happens next."
    }

    private func parseSuggestionText(_ text: String) -> [String] {
        let trimmed = text
            .replacingOccurrences(of: "```json", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let start = trimmed.firstIndex(of: "["),
           let end = trimmed.lastIndex(of: "]"),
           start <= end {
            let jsonSlice = String(trimmed[start...end])
            if let data = jsonSlice.data(using: .utf8),
               let json = try? JSONDecoder().decode([String].self, from: data) {
                return sanitizeSuggestions(json)
            }
        }

        if let data = trimmed.data(using: .utf8),
           let json = try? JSONDecoder().decode([String].self, from: data) {
            return sanitizeSuggestions(json)
        }

        let lines = trimmed
            .components(separatedBy: .newlines)
            .map { line in
                line
                    .replacingOccurrences(of: #"^\s*[-\d\.\)]\s*"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: "`", with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"' ").union(.whitespacesAndNewlines))
            }
            .filter { !$0.isEmpty && $0.lowercased() != "json" }

        return sanitizeSuggestions(lines)
    }

    private func sanitizeSuggestions(_ suggestions: [String]) -> [String] {
        var seen = Set<String>()
        let cleaned = suggestions
            .map { suggestion in
                suggestion
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'`[]{} ").union(.whitespacesAndNewlines))
            }
            .filter { !$0.isEmpty }
            .filter { isValidSuggestion($0) }
            .map { $0.count > 90 ? String($0.prefix(90)) : $0 }
            .filter { seen.insert($0.lowercased()).inserted }

        return Array(cleaned.prefix(3))
    }

    private func isValidSuggestion(_ suggestion: String) -> Bool {
        let lowercased = suggestion.lowercased()
        guard lowercased != "json" else { return false }
        guard suggestion.count >= 6 else { return false }
        return suggestion.range(of: "[A-Za-z]", options: .regularExpression) != nil
    }
}

private struct GeminiGenerateRequest: Encodable {
    let systemInstruction: GeminiContent
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

private struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiGenerationConfig: Encodable {
    let temperature: Double
    let maxOutputTokens: Int
}

private struct GeminiGenerateResponse: Decodable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Decodable {
    let content: GeminiCandidateContent
}

private struct GeminiCandidateContent: Decodable {
    let parts: [GeminiCandidatePart]
}

private struct GeminiCandidatePart: Decodable {
    let text: String?
}

private enum ChatError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case emptyResponse
    case apiFailure(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing GEMINI_API_KEY. Add it in environment variables or Info.plist."
        case .invalidResponse:
            return "Invalid server response."
        case .emptyResponse:
            return "No response text received."
        case .apiFailure(let message):
            return "API error: \(message)"
        }
    }
}

private extension Article {
    static let previewArticle = Article(
        source: Source(id: "1", name: "The Washington Post"),
        author: "Reporter",
        title: "Elon Musk's xAI builds a smarter chatbot than ChatGPT",
        description: "xAI recently raised $6 billion and is now raising another $4.3 billion.",
        url: "https://example.com",
        urlToImage: nil,
        publishedAt: "2026-04-01T09:00:00Z",
        content: "xAI is scaling infrastructure to compete with OpenAI and Google."
    )
}

#Preview {
    ChartView()
}
