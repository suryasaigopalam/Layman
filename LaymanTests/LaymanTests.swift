//
//  LaymanTests.swift
//  LaymanTests
//
//  Created by Surya Sai Gopalam on 31/03/26.
//

import Testing
@testable import Layman

@MainActor
struct NewsAppTestswithswiftTesting {

    @Test
  func example() async {
        let viewModel = ViewModel()
        await viewModel.fetchHeadLines()
        #expect(viewModel.headLinesStatus == FetchStatus.success)
    }
    
    
    @Test(arguments: Category.allCases)
    func categoryTest(category: Category) async {
        let viewModel = ViewModel()
        viewModel.currrentCategory = category
        await viewModel.fetchCategory()

        for article in viewModel.categoryNews {
            print("[\(category.rawValue)] \(article.title)")
        }

        #expect(viewModel.categoryStatus == FetchStatus.success)
    }

}
