import SwiftUI
import SafariServices

struct ArticleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ViewModel.self) private var viewModel

    let article: Article

    @State private var selectedSummaryIndex = 0
    @State private var showChatSheet = false
    @State private var showOriginalArticleSheet = false
    @State private var isUserDraggingSummary = false
    @State private var isSaved = false
    @State private var isSaveActionRunning = false
    @State private var toastMessage: SaveToastMessage?
    @State private var savedRecordURL: String?

    init(article: Article = .previewArticle) {
        self.article = article
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.10, green: 0.10, blue: 0.11) : Color(red: 0.96, green: 0.93, blue: 0.89)
    }

    private var cardColor: Color {
        colorScheme == .dark ? Color(red: 0.18, green: 0.18, blue: 0.19) : Color(red: 0.92, green: 0.89, blue: 0.84)
    }

    private var titleColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.12, green: 0.12, blue: 0.12)
    }

    private var iconBackground: Color {
        colorScheme == .dark ? Color(red: 0.24, green: 0.24, blue: 0.25) : Color(red: 0.93, green: 0.90, blue: 0.85)
    }

    private var summaryCards: [String] {
        ArticleSummaryBuilder.makeCards(from: article)
    }

    private var articleURL: URL? {
        URL(string: article.url)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
             VStack(spacing: 12) {
                    topBar
                    headline
                    photo
                    summaryCarousel
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            askLaymanButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                saveToastView(toastMessage)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showChatSheet) {
            NavigationStack {
                ChartView(article: article)
            }
        }
        .sheet(isPresented: $showOriginalArticleSheet) {
            if let url = articleURL {
                SafariSheet(url: url)
                    .ignoresSafeArea()
            }
        }
        .task {
            await refreshSavedState()
            await autoScrollSummaryCards()
        }
    }

    private func autoScrollSummaryCards() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard !summaryCards.isEmpty, !isUserDraggingSummary else { return }
                selectedSummaryIndex = (selectedSummaryIndex + 1) % summaryCards.count
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(titleColor.opacity(0.75))
                    .frame(width: 30, height: 30)
                    .background(iconBackground, in: Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())

            Spacer()

            Button {
                if articleURL != nil {
                    showOriginalArticleSheet = true
                }
            } label: {
                Image(systemName: "link")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(titleColor.opacity(0.75))
                    .frame(width: 30, height: 30)
                    .background(iconBackground, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(articleURL == nil)
            .glassEffect(.regular.interactive(), in: Circle())

            Button {
                Task { await onSaveTapped() }
            } label: {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isSaved ? Color.orange : titleColor.opacity(0.75))
                    .frame(width: 30, height: 30)
                    .background(iconBackground, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(isSaveActionRunning)
            .glassEffect(.regular.interactive(), in: Circle())

            ShareLink(item: article.url) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(titleColor.opacity(0.75))
                    .frame(width: 30, height: 30)
                    .background(iconBackground, in: Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
        }
    }

    private var headline: some View {
        Text(article.title)
            .font(.system(size: 36, weight: .black, design: .rounded))
            .tracking(-0.3)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .foregroundStyle(titleColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var photo: some View {
        AsyncImageView(imageString: article.urlToImage)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var summaryCarousel: some View {
        VStack(spacing: 8) {
            TabView(selection: $selectedSummaryIndex) {
                ForEach(Array(summaryCards.enumerated()), id: \.offset) { index, text in
                    let summaryShape = RoundedRectangle(cornerRadius: 20, style: .continuous)
                    ZStack(alignment: .topLeading) {
                        summaryShape
                            .fill(cardColor)
                            .overlay(
                                summaryShape.stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.55), lineWidth: 1)
                            )

                        Text(text)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(titleColor)
                            .lineSpacing(3)
                            .lineLimit(6)
                            .multilineTextAlignment(.leading)
                            .padding(14)
                    }
                    .padding(.horizontal, 2)
                    .clipShape(summaryShape)
                    .contentShape(summaryShape)
                    .glassEffect(.regular, in: summaryShape)
                        .tag(index)
                }
            }
            .frame(height: 170)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in isUserDraggingSummary = true }
                    .onEnded { _ in isUserDraggingSummary = false }
            )

            HStack(spacing: 6) {
                ForEach(summaryCards.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selectedSummaryIndex ? Color.orange : titleColor.opacity(0.2))
                        .frame(width: index == selectedSummaryIndex ? 16 : 6, height: 5)
                        .animation(.easeInOut(duration: 0.2), value: selectedSummaryIndex)
                }
            }
        }
    }

    private var askLaymanButton: some View {
        Button {
            showChatSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                Text("Ask Layman")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color(red: 0.79, green: 0.37, blue: 0.18), in: Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(
            .regular
                .tint(Color(red: 0.79, green: 0.37, blue: 0.18))
                .interactive(),
            in: Capsule()
        )
    }

    private func onSaveTapped() async {
        guard !isSaveActionRunning else { return }
        isSaveActionRunning = true
        defer { isSaveActionRunning = false }

        do {
            if isSaved {
                let urlToRemove = savedRecordURL ?? article.url
                try await viewModel.supabaseManager.removeSavedArticle(articleURL: urlToRemove)
                isSaved = false
                savedRecordURL = nil
                await showToast(.removed)
            } else {
                let saved = try await viewModel.supabaseManager.saveArticle(article)
                isSaved = true
                savedRecordURL = saved.articleURL
                await showToast(.saved)
            }
        } catch {
            if errorIsMissingSession(error) {
                await viewModel.supabaseManager.refreshSession()
                await refreshSavedState()
            }
            await showToast(.failed)
        }
    }

    @MainActor
    private func refreshSavedState() async {
        do {
            let savedArticles = try await viewModel.supabaseManager.fetchSavedArticles()
            if let matched = savedArticles.first(where: { matchesSavedArticleURL(current: article.url, saved: $0.articleURL) }) {
                isSaved = true
                savedRecordURL = matched.articleURL
            } else {
                isSaved = false
                savedRecordURL = nil
            }
        } catch {
            if errorIsMissingSession(error) {
                await viewModel.supabaseManager.refreshSession()
                do {
                    let savedArticles = try await viewModel.supabaseManager.fetchSavedArticles()
                    if let matched = savedArticles.first(where: { matchesSavedArticleURL(current: article.url, saved: $0.articleURL) }) {
                        isSaved = true
                        savedRecordURL = matched.articleURL
                    } else {
                        isSaved = false
                        savedRecordURL = nil
                    }
                    return
                } catch {
                    isSaved = false
                    savedRecordURL = nil
                    return
                }
            }
            isSaved = false
            savedRecordURL = nil
        }
    }

    @MainActor
    private func showToast(_ kind: SaveToastKind) async {
        withAnimation(.easeInOut(duration: 0.2)) {
            toastMessage = SaveToastMessage(kind: kind, article: article)
        }

        try? await Task.sleep(for: .seconds(1))

        withAnimation(.easeInOut(duration: 0.2)) {
            toastMessage = nil
        }
    }

    private func saveToastView(_ toast: SaveToastMessage) -> some View {
        HStack(spacing: 10) {
            AsyncImageView(imageString: toast.article.urlToImage)
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.kind.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(titleColor)
                    .lineLimit(1)

                Text(toast.article.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(titleColor.opacity(0.75))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(cardColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(toast.kind.tint.opacity(0.35), lineWidth: 1)
        )
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func errorIsMissingSession(_ error: Error) -> Bool {
        if let typed = error as? SupaBaseError, typed == .missingUserSession {
            return true
        }
        return false
    }

    private func matchesSavedArticleURL(current: String, saved: String) -> Bool {
        if current == saved { return true }
        return normalizedURLKey(current) == normalizedURLKey(saved)
    }

    private func normalizedURLKey(_ string: String) -> String {
        guard let components = URLComponents(string: string) else {
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let host = (components.host ?? "").lowercased()
        var path = components.path.lowercased()
        if path.hasSuffix("/") {
            path.removeLast()
        }

        if host.isEmpty && path.isEmpty {
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return host + path
    }
}

private struct SaveToastMessage {
    let kind: SaveToastKind
    let article: Article
}

private enum SaveToastKind {
    case saved
    case removed
    case failed

    var title: String {
        switch self {
        case .saved:
            return "Saved To Your Articles"
        case .removed:
            return "Removed From Saved"
        case .failed:
            return "Operation Failed"
        }
    }

    var tint: Color {
        switch self {
        case .saved:
            return .green
        case .removed:
            return .orange
        case .failed:
            return .red
        }
    }
}

private struct SafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}

private enum ArticleSummaryBuilder {
    static func makeCards(from article: Article) -> [String] {
        let rawText = [article.description, article.content]
            .compactMap { $0 }
            .joined(separator: " ")
            .replacingOccurrences(of: "\n", with: " ")

        let normalized = rawText
            .split(separator: " ")
            .map(String.init)

        let fallback = fallbackCards(using: article.title)
        guard !normalized.isEmpty else { return fallback }

        let chunkSize = max(1, normalized.count / 3)
        var cards: [String] = []

        for index in 0..<3 {
            let start = index * chunkSize
            if start >= normalized.count {
                cards.append(fallback[index])
                continue
            }

            let end = min(normalized.count, (index + 1) * chunkSize)
            let words = Array(normalized[start..<end])
            let sentence = words.joined(separator: " ")
            cards.append(trimmedSummary(sentence, fallback: fallback[index]))
        }

        return cards
    }

    private static func trimmedSummary(_ text: String, fallback: String) -> String {
        let words = text.split(separator: " ").map(String.init)
        if words.count < 16 {
            return fallback
        }

        let limitedWords = Array(words.prefix(35))
        return limitedWords.joined(separator: " ")
    }

    private static func fallbackCards(using title: String) -> [String] {
        [
            "This story explains the main update in simple terms. \(title) focuses on what changed, why people are paying attention, and what it means right now.",
            "The article adds context around who is involved, what decisions are being made, and what outcomes are possible over the next few weeks.",
            "In short, the key takeaway is practical impact. This can influence business choices, technology direction, and everyday users depending on how it develops."
        ]
    }
}

private extension Article {
    static let previewArticle = Article(
        source: Source(id: "1", name: "The Washington Post"),
        author: "Reporter",
        title: "Elon Musk's xAI builds a smarter chatbot than ChatGPT",
        description: "xAI recently raised $6 billion and is now raising another $4.3 billion to accelerate model training and infrastructure. The company says it aims to compete directly with OpenAI and Google by delivering faster and more practical AI tools.",
        url: "https://example.com",
        urlToImage: nil,
        publishedAt: "2026-04-01T09:00:00Z",
        content: "Investors are closely watching how quickly xAI can scale products and attract enterprise adoption. Analysts note that speed, reliability, and lower operational costs will determine whether the company can gain long-term market share in AI assistants."
    )
}

#Preview {
    NavigationStack {
        ArticleDetailView()
            .environment(ViewModel())
    }
}
