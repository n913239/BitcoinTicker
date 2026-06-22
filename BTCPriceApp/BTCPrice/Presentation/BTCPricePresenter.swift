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
}
