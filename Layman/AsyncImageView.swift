//
//  AsyncImageView.swift
//  Layman
//
//  Created by Surya Sai Gopalam on 31/03/26.
//
import SwiftUI
import Foundation
import UIKit

struct AsyncImageView: View {
    var imageString: String?
    @State private var uiImage: UIImage?
    var body: some View {
        Group {
            
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
            
            
            
        }
        .task {
            await loadImage()
        }
    }

    @MainActor
    private func loadImage() async {
        guard uiImage == nil else { return }
        guard let imageString, let imageURL = URL(string: imageString) else { return }
        guard let data = await getImageData(url: imageURL) else { return }
        uiImage = UIImage(data: data)
    }
    
    func getImageData(url: URL) async -> Data? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            return nil
        }
    }
}

#Preview {
    AsyncImageView(imageString: "https://www.hollywoodreporter.com/wp-content/uploads/2026/03/GettyImages-2266303210-Conan-OBrien-Oscar-Host-2026-Show-H.jpg?w=1296&h=730&crop=1")
}
