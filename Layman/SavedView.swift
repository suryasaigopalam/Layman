//
//  SavedView.swift
//  Layman
//
//  Created by Surya Sai Gopalam on 01/04/26.
//

import SwiftUI

struct SavedView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ViewModel.self) private var viewModel

    @State private var savedArticles: [SavedArticle] = []
    @State private var isLoading = false
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
                LazyVStack(spacing: 12) {
                    header

                    if isLoading {
                        loadingView
                    } else if let errorMessage {
                        failedView(message: errorMessage)
                    } else if savedArticles.isEmpty {
                        emptyStateView
                    } else {
                        savedList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationBarHidden(true)
            .refreshable {
                await loadSavedArticles()
            }
            .task {
                await loadSavedArticles()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Saved")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(titleColor)

            Spacer()

            Button {
                Task { await loadSavedArticles() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(titleColor.opacity(0.7))
                    .frame(width: 34, height: 34)
                    .background(cardColor, in: Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading saved articles...")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(titleColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.orange)

            Text("No saved articles")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(titleColor)

            Text("Save stories from Home or Browse to see them here.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(titleColor.opacity(0.7))
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
    }

    private func failedView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.orange)

            Text("Unable to load saved articles")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(titleColor)

            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(titleColor.opacity(0.72))
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Button("Retry") {
                Task { await loadSavedArticles() }
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }

    private var savedList: some View {
        LazyVStack(spacing: 10) {
            ForEach(savedArticles) { saved in
                savedListItem(saved)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await removeSavedArticle(saved) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func savedListItem(_ saved: SavedArticle) -> some View {
        ZStack(alignment: .trailing) {
            NavigationLink {
                ArticleDetailView(article: makeArticle(from: saved))
            } label: {
                savedRow(saved)
            }
            .buttonStyle(.plain)

            Button {
                Task { await removeSavedArticle(saved) }
            } label: {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.orange)
                    .frame(width: 32, height: 32)
                    .background(cardColor.opacity(0.75), in: Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .padding(.trailing, 10)
        }
    }

    private func savedRow(_ saved: SavedArticle) -> some View {
        HStack(spacing: 12) {
            AsyncImageView(imageString: saved.imageURL)
                .frame(width: 78, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(saved.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .foregroundStyle(titleColor)

                Text(saved.sourceName ?? "Saved Story")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(titleColor.opacity(0.65))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(cardColor.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @MainActor
    private func loadSavedArticles() async {
        isLoading = true
        errorMessage = nil

        do {
            savedArticles = try await viewModel.supabaseManager.fetchSavedArticles()
        } catch {
            if isMissingSession(error) {
                await viewModel.supabaseManager.refreshSession()
                do {
                    savedArticles = try await viewModel.supabaseManager.fetchSavedArticles()
                    isLoading = false
                    return
                } catch {
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    @MainActor
    private func removeSavedArticle(_ saved: SavedArticle) async {
        do {
            try await viewModel.supabaseManager.removeSavedArticle(articleURL: saved.articleURL)
            withAnimation(.easeInOut(duration: 0.2)) {
                savedArticles.removeAll { $0.id == saved.id }
            }
        } catch {
            if isMissingSession(error) {
                await viewModel.supabaseManager.refreshSession()
            }
            await loadSavedArticles()
        }
    }

    private func isMissingSession(_ error: Error) -> Bool {
        guard let typed = error as? SupaBaseError else { return false }
        return typed == .missingUserSession
    }

    private func makeArticle(from saved: SavedArticle) -> Article {
        Article(
            source: Source(id: nil, name: saved.sourceName ?? "Saved"),
            author: nil,
            title: saved.title,
            description: nil,
            url: saved.articleURL,
            urlToImage: saved.imageURL,
            publishedAt: saved.savedAt ?? "",
            content: nil
        )
    }
}

#Preview {
    SavedView()
        .environment(ViewModel())
}
