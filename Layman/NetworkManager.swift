//
//  NetworkManager.swift
//  Layman
//
//  Created by Surya Sai Gopalam on 31/03/26.
//

import Foundation
enum NetworkError: Error {
    case invalidUrl
    case invalidResponse
    case missingApiKey
}

class NetworkManager {
    private func loadAPIKey() throws -> String {
        if let value = AppConfig.value(for: "NEWS_API_KEY"),
           !AppConfig.isUnresolvedBuildSetting(value) {
            return value
        }

        throw NetworkError.missingApiKey
    }

    func getHeadLines() async throws -> NewsResponse {
        let apiKey = try loadAPIKey()
        let urlString = "https://newsapi.org/v2/top-headlines?country=us&apiKey=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidUrl
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(NewsResponse.self, from: data)
    }
    
    func getCategory(category:Category)async throws -> NewsResponse {
        let apiKey = try loadAPIKey()
        let urlString = "https://newsapi.org/v2/top-headlines?country=us&category=\(category.rawValue)&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidUrl
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try (decoder.decode(NewsResponse.self, from: data))
    }
}
