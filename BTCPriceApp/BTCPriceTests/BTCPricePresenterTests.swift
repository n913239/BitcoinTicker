//
//  BTCPricePresenterTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/7/14.
//

import XCTest
@testable import BTCPrice

@MainActor
final class BTCPricePresenterTests: XCTestCase {
    
    func test_init_doesNotSendMessagesToView() {
        let (_, spy) = makeSUT()
        
        XCTAssertTrue(spy.messages.isEmpty, "Expected no view messages on init")
    }
    
    func test_didStartLoading_withNoPreviousValue_startsLoading() {
        let (sut, spy) = makeSUT()
        
        sut.didStartLoading()
        
        XCTAssertEqual(spy.messages, [.loading(true)])
    }
    
    func test_didStartLoading_withPreviousValue_doesNotShowLoadingIndicator() {
        let (sut, spy) = makeSUT()
        sut.didFinishLoading(with: BTCPriceItem(price: 72615.55))
        spy.reset()
        
        sut.didStartLoading()
        
        XCTAssertEqual(spy.messages, [.loading(false)], "A price is already on screen, so refreshing it must not flash a spinner every second")
    }
    
    func test_didStartLoading_afterFailure_keepsErrorMessageOnScreen() {
        let (sut, spy) = makeSUT()
        sut.didFinishLoading(with: anyError())
        spy.reset()
        
        sut.didStartLoading()
        
        XCTAssertFalse(spy.messages.contains(.errorMessage(nil)), "The error must stay visible until a load succeeds, not blink on every poll")
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
    
    func test_didFinishLoadingWithError_withNoPreviousValue_displaysLoadErrorAndStopsLoading() {
        let (sut, spy) = makeSUT()
        
        sut.didFinishLoading(with: anyError())
        
        XCTAssertEqual(spy.messages, [
            .errorMessage(BTCPricePresenter.loadError),
            .loading(false)
        ])
    }
    
    func test_didFinishLoadingWithError_withPreviousValue_displaysLastKnownPriceWithStaleMessage() {
        let fixedDate = Date(timeIntervalSince1970: 1737720420) // Jan 24, 2025 12:07 UTC
        let (sut, spy) = makeSUT(
            currentDate: { fixedDate },
            locale: Locale(identifier: "en_US"),
            calendar: utcCalendar()
        )
        
        sut.didFinishLoading(with: BTCPriceItem(price: 72615.55))
        spy.reset()
        
        sut.didFinishLoading(with: anyError())
        
        XCTAssertEqual(spy.messages, [
            .errorMessage("Failed to update value. Displaying last updated value from Jan 24th, 12:07"),
            .price("$72,615.55"),
            .loading(false)
        ])
    }
    
    func test_didFinishLoadingWithItem_afterFailure_clearsErrorMessage() {
        let (sut, spy) = makeSUT()
        sut.didFinishLoading(with: anyError())
        spy.reset()
        
        sut.didFinishLoading(with: BTCPriceItem(price: 72615.55))
        
        XCTAssertTrue(spy.messages.contains(.errorMessage(nil)), "Expected presenter to clear error message after recovery")
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
    
    private func anyError() -> NSError {
        NSError(domain: "test", code: 0)
    }
    
    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
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
