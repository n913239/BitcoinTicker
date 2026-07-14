//
//  BTCPriceErrorView.swift
//  BTCPrice
//
//  Created by mike on 2026/7/14.
//

import Foundation

@MainActor
public protocol BTCPriceErrorView {
    func display(_ viewModel: BTCPriceErrorViewModel)
}
