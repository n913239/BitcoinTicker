//
//  BTCPriceViewControllerSnapshotTests.swift
//  BTCPriceiOSTests
//
//  Created by mike on 2026/6/23.
//

import XCTest
import BTCPrice
@testable import BTCPriceApp

@MainActor
final class BTCPriceViewControllerSnapshotTests: XCTestCase {
    
    func test_priceDisplay_light() {
        let (sut, presenter) = makeSUT()
        
        presenter.didFinishLoading(with: BTCPriceItem(price: 72615.55))
        
        assert(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "BTC_PRICE_DISPLAY_light")
    }
    
    func test_priceDisplay_dark() {
        let (sut, presenter) = makeSUT()
        
        presenter.didFinishLoading(with: BTCPriceItem(price: 72615.55))
        
        assert(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "BTC_PRICE_DISPLAY_dark")
    }
    
    func test_loadingState_light() {
        let (sut, presenter) = makeSUT()
        
        presenter.didStartLoading()
        
        assert(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "BTC_PRICE_LOADING_light")
    }
    
    func test_loadingState_dark() {
        let (sut, presenter) = makeSUT()
        
        presenter.didStartLoading()
        
        assert(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "BTC_PRICE_LOADING_dark")
    }
    
    func test_errorState_light() {
        let fixedDate = Date(timeIntervalSince1970: 1737720420)
        let (sut, presenter) = makeSUT(currentDate: { fixedDate })
        
        presenter.didFinishLoading(with: BTCPriceItem(price: 72615.55))
        presenter.didFinishLoading(with: anyError())
        
        assert(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "BTC_PRICE_ERROR_light")
    }
    
    func test_errorState_dark() {
        let fixedDate = Date(timeIntervalSince1970: 1737720420)
        let (sut, presenter) = makeSUT(currentDate: { fixedDate })
        
        presenter.didFinishLoading(with: BTCPriceItem(price: 72615.55))
        presenter.didFinishLoading(with: anyError())
        
        assert(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "BTC_PRICE_ERROR_dark")
    }
    
    func test_priceDisplay_extraExtraExtraLargeContentSize() {
        let (sut, presenter) = makeSUT()
        
        presenter.didFinishLoading(with: BTCPriceItem(price: 72615.55))
        
        assert(snapshot: sut.snapshot(for: .iPhone(style: .light, contentSize: .accessibilityExtraExtraExtraLarge)), named: "BTC_PRICE_DISPLAY_XXXL")
    }
    
    func test_errorState_extraExtraExtraLargeContentSize() {
        let fixedDate = Date(timeIntervalSince1970: 1737720420)
        let (sut, presenter) = makeSUT(currentDate: { fixedDate })
        
        presenter.didFinishLoading(with: BTCPriceItem(price: 72615.55))
        presenter.didFinishLoading(with: anyError())
        
        assert(snapshot: sut.snapshot(for: .iPhone(style: .light, contentSize: .accessibilityExtraExtraExtraLarge)), named: "BTC_PRICE_ERROR_XXXL")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (BTCPriceViewController, BTCPricePresenter) {
        let sut = BTCPriceViewController()
        let presenter = BTCPricePresenter(
            priceView: sut,
            loadingView: sut,
            errorView: sut,
            currentDate: currentDate,
            locale: Locale(identifier: "en_US"),
            calendar: utcCalendar()
        )
        // NOTE: trackForMemoryLeaks 故意不套在 VC 上。UIKit 透過 SnapshotWindow 的 dummy
        // UIWindowScene retain 住 VC，即使清了 rootViewController 也釋放不掉。官方 EssentialFeed
        // 的 snapshot 測試同樣略過 VC 的 leak tracking——leak 把關交給 presenter/acceptance 測試。
        trackForMemoryLeaks(presenter, file: file, line: line)
        return (sut, presenter)
    }
    
    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }
    
    private func anyError() -> NSError {
        NSError(domain: "test", code: 0)
    }
}
