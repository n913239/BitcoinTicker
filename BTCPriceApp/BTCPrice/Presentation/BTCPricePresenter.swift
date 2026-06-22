//
//  BTCPricePresenter.swift
//  BTCPrice
//
//  Created by mike on 2026/6/22.
//

import Foundation

public final class BTCPricePresenter {
    private let priceView: BTCPriceView
    private let loadingView: BTCPriceLoadingView
    private let errorView: BTCPriceErrorView
    
    private let currentDate: () -> Date
    private let locale: Locale
    private let calendar: Calendar
    
    private var lastSuccessfulPrice: String?
    private var lastSuccessfulDate: Date?
    
    public init(
        priceView: BTCPriceView,
        loadingView: BTCPriceLoadingView,
        errorView: BTCPriceErrorView,
        currentDate: @escaping () -> Date = Date.init,
        locale: Locale = Locale(identifier: "en_US"),
        calendar: Calendar = .current
    ) {
        self.priceView = priceView
        self.loadingView = loadingView
        self.errorView = errorView
        self.currentDate = currentDate
        self.locale = locale
        self.calendar = calendar
    }
    
    @MainActor
    public func didStartLoading() {
        errorView.display(.noError)
        loadingView.display(BTCPriceLoadingViewModel(isLoading: true))
    }
    
    @MainActor
    public func didFinishLoading(with item: BTCPriceItem) {
        let formatted = format(price: item.price)
        lastSuccessfulPrice = formatted
        lastSuccessfulDate = currentDate()
        errorView.display(.noError)
        priceView.display(BTCPriceViewModel(price: formatted))
        loadingView.display(BTCPriceLoadingViewModel(isLoading: false))
    }
    
    // MARK: - Formatting
    
    private func format(price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
}
