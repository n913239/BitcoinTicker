//
//  BTCPricePresenterTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/6/22.
//

import XCTest
@testable import BTCPrice

@MainActor
final class BTCPricePresenterTests: XCTestCase {
    
    func test_init_doesNotSendMessagesToView() {
        let (_, spy) = makeSUT()
        
        XCTAssertTrue(spy.messages.isEmpty, "Expected no view messages on init")
    }
    
    func test_didStartLoading_displaysNoErrorMessageAndStartsLoading() {
        let (sut, spy) = makeSUT()
        
        sut.didStartLoading()
        
        XCTAssertEqual(spy.messages, [
            .errorMessage(nil),
            .loading(true)
        ])
    }
    
    func test_didFinishLoadingWithItem_displaysFormattedPriceAndStopsLoading() {
        let (sut, spy) = makeSUT()
        
        sut.didFinishLoading(with: BTCPriceItem(price: 72615.55))
        
        XCTAssertEqual(spy.messages, [
            .errorMessage(nil),
            .price("$72,615.55"),
            .loading(false)
        ])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        locale: Locale = Locale(identifier: "en_US"),
        calendar: Calendar = .current,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (BTCPricePresenter, ViewSpy) {
        let spy = ViewSpy()
        let sut = BTCPricePresenter(
            priceView: spy,
            loadingView: spy,
            errorView: spy,
            currentDate: currentDate,
            locale: locale,
            calendar: calendar
        )
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, spy)
    }
    
    @MainActor
    private final class ViewSpy: BTCPriceView, BTCPriceLoadingView, BTCPriceErrorView {
        enum Message: Hashable {
            case price(String)
            case loading(Bool)
            case errorMessage(String?)
        }
        
        private(set) var messages: [Message] = []
        
        func display(_ viewModel: BTCPriceViewModel) {
            messages.append(.price(viewModel.price))
        }
        
        func display(_ viewModel: BTCPriceLoadingViewModel) {
            messages.append(.loading(viewModel.isLoading))
        }
        
        func display(_ viewModel: BTCPriceErrorViewModel) {
            messages.append(.errorMessage(viewModel.message))
        }
        
        func reset() {
            messages = []
        }
    }
    
}
