import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let articles: [Article]

    @State private var query = ""
    @FocusState private var isSearchFieldFocused: Bool

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.10, green: 0.10, blue: 0.11) : Color(red: 0.96, green: 0.93, blue: 0.89)
    }

    private var cardColor: Color {
        colorScheme == .dark ? Color(red: 0.18, green: 0.18, blue: 0.19) : Color(red: 0.90, green: 0.86, blue: 0.80)
    }

    private var titleColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.12, green: 0.12, blue: 0.12)
    }

    private var searchFieldBackground: Color {
        colorScheme == .dark ? Color(red: 0.22, green: 0.22, blue: 0.23) : Color(red: 0.93, green: 0.90, blue: 0.85)
    }

    private var filteredArticles: [Article] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return articles }

        return articles.filter { article in
            article.title.localizedCaseInsensitiveContains(text)
                || (article.description?.localizedCaseInsensitiveContains(text) ?? false)
                || article.source.name.localizedCaseInsensitiveContains(text)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                header
                searchBar

                if filteredArticles.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isSearchFieldFocused = true
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(titleColor.opacity(0.75))
                    .frame(width: 34, height: 34)
                    .background(searchFieldBackground, in: Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())

            Text("Search")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(titleColor)

            Spacer()
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(titleColor.opacity(0.55))

            TextField("Search articles", text: $query)
                .focused($isSearchFieldFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(titleColor)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(titleColor.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(searchFieldBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var noResultsView: some View {
        VStack(spacing: 8) {
            Text("No articles available")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(titleColor)

            Text("Try a different keyword.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(titleColor.opacity(0.65))
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private var resultsList: some View {
        VStack(spacing: 10) {
            ForEach(filteredArticles, id: \.url) { article in
                NavigationLink {
                    ArticleDetailView(article: article)
                } label: {
                    HStack(spacing: 12) {
                        AsyncImageView(imageString: article.urlToImage)
                            .frame(width: 78, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text(article.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .foregroundStyle(titleColor)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(cardColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchView(
            articles: [
                Article(
                    source: Source(id: "1", name: "CNBC"),
                    author: nil,
                    title: "Department of Labor proposes rule for including alternative investments",
                    description: "Preview description",
                    url: "https://example.com/1",
                    urlToImage: nil,
                    publishedAt: "2026-03-31T09:00:00Z",
                    content: nil
                ),
                Article(
                    source: Source(id: "2", name: "NBC News"),
                    author: nil,
                    title: "Actor and comedian Alex Duong dies at 42",
                    description: "Preview description",
                    url: "https://example.com/2",
                    urlToImage: nil,
                    publishedAt: "2026-03-31T10:00:00Z",
                    content: nil
                )
            ]
        )
    }
}
