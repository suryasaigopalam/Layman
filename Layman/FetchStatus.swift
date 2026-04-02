//
//  FetchStatus.swift
//  Layman
//
//  Created by Surya Sai Gopalam on 31/03/26.
//

import Foundation
enum FetchStatus: Equatable {
    case notStarted, loading, success, failed(Error)

    static func == (lhs: FetchStatus, rhs: FetchStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
             (.loading, .loading),
             (.success, .success):
            return true
        case let (.failed(lhsError), .failed(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
