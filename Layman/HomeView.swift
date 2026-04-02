import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ViewModel.self) private var viewModel

    @State private var heroSelection = 0
    @State private var isUserDraggingHero = false
    @State private var showSearchView = false
    @State private var showBrowseView = false

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

    private var heroArticles: [Article] {
        Array(viewModel.headLineNews.prefix(5))
    }

    private var picksArticles: [Article] {
        Array(viewModel.headLineNews.dropFirst(1).prefix(10))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    header

                    switch viewModel.headLinesStatus {
                    case .notStarted, .loading:
                        loadingView
                    case .failed(let error):
                        failedView(message: error.localizedDescription)
                    case .success:
                        successView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.fetchHeadLines()
            }
            .navigationDestination(isPresented: $showSearchView) {
                SearchView(articles: viewModel.headLineNews)
            }
            .navigationDestination(isPresented: $showBrowseView) {
                BrowseView()
            }
            .task {
                guard viewModel.headLinesStatus == .notStarted else { return }
                await viewModel.fetchHeadLines()
            }
            .task {
                await autoScrollHero()
            }
        }
    }

    private func autoScrollHero() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard !heroArticles.isEmpty, !isUserDraggingHero else { return }
                heroSelection = (heroSelection + 1) % heroArticles.count
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Layman")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .tracking(-0.3)
                .foregroundStyle(titleColor)

            Spacer()

            Button {
                showBrowseView = true
            } label: {
                Text("Browse")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(titleColor.opacity(0.75))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(searchButtonBackground, in: Capsule())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Capsule())

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
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading latest stories...")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(titleColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }

    private func failedView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.orange)

            Text("Unable to load news")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(titleColor)

            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(titleColor.opacity(0.7))
                .lineLimit(3)

            Button("Retry") {
                Task {
                    await viewModel.fetchHeadLines()
                }
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }

    private var successView: some View {
        LazyVStack(spacing: 12) {
            if heroArticles.isEmpty {
                emptyState
            } else {
                heroCarousel
                todayPicksSection
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No articles available")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(titleColor)

            Text("Please check again in a while.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(titleColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }

    private var heroCarousel: some View {
        VStack(spacing: 10) {
            TabView(selection: $heroSelection) {
                ForEach(Array(heroArticles.enumerated()), id: \.element.url) { index, article in
                    NavigationLink {
                        ArticleDetailView(article: article)
                    } label: {
                        HeroCard(article: article)
                    }
                    .buttonStyle(.plain)
                    .tag(index)
                }
            }
            .frame(height: 205)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in isUserDraggingHero = true }
                    .onEnded { _ in isUserDraggingHero = false }
            )

            HStack(spacing: 6) {
                ForEach(heroArticles.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == heroSelection ? Color.orange : titleColor.opacity(0.2))
                        .frame(width: index == heroSelection ? 18 : 6, height: 5)
                        .animation(.easeInOut(duration: 0.2), value: heroSelection)
                }
            }
        }
    }

    private var todayPicksSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Today's Picks")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(titleColor)

                Spacer()

                NavigationLink {
                    ViewAllView(articles: viewModel.headLineNews)
                } label: {
                    Text("View All")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }

            LazyVStack(spacing: 10) {
                ForEach(picksArticles, id: \.url) { article in
                    NavigationLink {
                        ArticleDetailView(article: article)
                    } label: {
                        PickRow(article: article, titleColor: titleColor, cardColor: cardColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct HeroCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let article: Article

    private var gradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color(red: 0.29, green: 0.15, blue: 0.12), Color(red: 0.45, green: 0.20, blue: 0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [Color(red: 0.98, green: 0.35, blue: 0.00), Color(red: 0.55, green: 0.18, blue: 0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImageView(imageString: article.urlToImage)
                .overlay {
                    gradient.opacity(0.75)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(article.source.name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .foregroundStyle(.white)

                Text(article.title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(-0.2)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .foregroundStyle(.white)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .clipShape(heroShape)
        .contentShape(heroShape)
        .glassEffect(.regular, in: heroShape)
    }
}

private struct PickRow: View {
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
    HomeView()
        .environment(ViewModel())
}
