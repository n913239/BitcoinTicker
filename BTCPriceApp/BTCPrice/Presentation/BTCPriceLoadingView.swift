//
//  BTCPriceLoadingView.swift
//  BTCPrice
//
//  Created by mike on 2026/7/14.
//

import Foundation

@MainActor
public protocol BTCPriceLoadingView {
    func display(_ viewModel: BTCPriceLoadingViewModel)
}
