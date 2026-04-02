import SwiftUI

struct ViewAllView: View {
    @Environment(\.colorScheme) private var colorScheme

    let articles: [Article]
    @State private var showSearchView = false

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.10, green: 0.10, blue: 0.11) : Color(red: 0.96, green: 0.93, blue: 0.89)
    }

    private var cardColor: Color {
        colorScheme == .dark ? Color(red: 0.18, green: 0.18, blue: 0.19) : Color(red: 0.90, green: 0.86, blue: 0.80)
    }

    private var titleColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.12, green: 0.12, blue: 0.12)
    }

    private var searchButtonBackground: Color {
        colorScheme == .dark ? Color(red: 0.24, green: 0.24, blue: 0.25) : Color(red: 0.93, green: 0.90, blue: 0.85)
    }

    var body: some View {
        ScrollView {
          VStack(spacing: 12) {
                HStack {
                    Text("View All")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(titleColor)

                    Spacer()

                    Button {
                        showSearchView = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(titleColor.opacity(0.65))
                            .frame(width: 34, height: 34)
                            .background(searchButtonBackground, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
                }

                if articles.isEmpty {
                    Text("No articles available")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(titleColor)
                        .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(articles, id: \.url) { article in
                            NavigationLink {
                                ArticleDetailView(article: article)
                            } label: {
                                ViewAllRow(article: article, titleColor: titleColor, cardColor: cardColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSearchView) {
            SearchView(articles: articles)
        }
    }
}

private struct ViewAllRow: View {
    let article: Article
    let titleColor: Color
    let cardColor: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            AsyncImageView(imageString: article.urlToImage)
                .frame(width: 78, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .clipped()

            Text(article.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(titleColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 82, alignment: .leading)
        .background(cardColor.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ViewAllView(articles: [
            Article(
                source: Source(id: "1", name: "CNBC"),
                author: "Reporter",
                title: "Inside Y Combinator: Where Big Tech Gets Its Start",
                description: "Sample description",
                url: "https://example.com/1",
                urlToImage: nil,
                publishedAt: "2026-04-01T09:00:00Z",
                content: "Sample content"
            ),
            Article(
                source: Source(id: "2", name: "Bloomberg"),
                author: "Editor",
                title: "Apple's First Foldable iPhone Is Rumored to Launch in 2026",
                description: "Sample description",
                url: "https://example.com/2",
                urlToImage: nil,
                publishedAt: "2026-04-01T10:00:00Z",
                content: "Sample content"
            ),
            Article(
                source: Source(id: "3", name: "The Verge"),
                author: "Staff",
                title: "Former OpenAI CTO Launches Thinking Machines Lab",
                description: "Sample description",
                url: "https://example.com/3",
                urlToImage: nil,
                publishedAt: "2026-04-01T11:00:00Z",
                content: "Sample content"
            )
        ])
    }
}
