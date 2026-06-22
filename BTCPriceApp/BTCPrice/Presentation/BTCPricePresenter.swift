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
    
    public static var loadError: String {
        "Failed to load data."
    }
    
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
    
    @MainActor
    public func didFinishLoading(with error: Error) {
        if let price = lastSuccessfulPrice, let date = lastSuccessfulDate {
            errorView.display(.error(message: "Failed to update value. Displaying last updated value from \(format(date: date))"))
            priceView.display(BTCPriceViewModel(price: price))
        } else {
            errorView.display(.error(message: Self.loadError))
        }
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
    
    private func format(date: Date) -> String {
        let day = calendar.component(.day, from: date)
        let ordinal = ordinalSuffix(for: day)
        
        let monthFormatter = DateFormatter()
        monthFormatter.locale = locale
        monthFormatter.calendar = calendar
        monthFormatter.timeZone = calendar.timeZone
        monthFormatter.dateFormat = "MMM"
        
        let timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.calendar = calendar
        timeFormatter.timeZone = calendar.timeZone
        timeFormatter.dateFormat = "HH:mm"
        
        return "\(monthFormatter.string(from: date)) \(day)\(ordinal), \(timeFormatter.string(from: date))"
    }
    
    private func ordinalSuffix(for day: Int) -> String {
        switch day {
        case 11, 12, 13: return "th"
        default:
            switch day % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }
}
