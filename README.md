# Layman

Layman is a SwiftUI-based iOS news app that helps users understand current events in a simpler and more approachable way. The app delivers top headlines, category-based browsing, article search, saved articles, and an AI-powered explanation feature that breaks down news stories into easy-to-follow language.

## Overview

Layman is built for readers who want a cleaner and simpler way to consume news. Instead of only showing raw headlines, the app focuses on readability, quick summaries, and conversational explanations so users can better understand what a story means and why it matters.

## Features

- Browse top US headlines in a clean and modern SwiftUI interface
- Explore news by category including business, entertainment, general, health, science, sports, and technology
- Search articles by title, description, or source
- Open article detail pages with image previews and summary cards
- Save and remove articles for later reading
- Sign up, sign in, and sign out with Supabase authentication
- Update profile name from the app
- Switch between system, light, and dark appearance modes
- Use the "Ask Layman" AI assistant to get simple explanations about a news article
- Share article links and open original sources inside the app

## Tech Stack

- Swift
- SwiftUI
- Supabase
- NewsAPI
- Gemini API
- Xcode

## Project Structure

```text
Layman/
├── LaymanApp.swift
├── ContentView.swift
├── WelcomeScreen.swift
├── AuthView.swift
├── SignInView.swift
├── SignUpView.swift
├── LaymanTabView.swift
├── HomeView.swift
├── BrowseView.swift
├── SearchView.swift
├── ViewAllView.swift
├── SavedView.swift
├── ProfileView.swift
├── ArticleDetailView.swift
├── ChartView.swift
├── NetworkManager.swift
├── SupaBaseManager.swift
├── NewsResponse.swift
├── Category.swift
├── FetchStatus.swift
└── AsyncImageView.swift
