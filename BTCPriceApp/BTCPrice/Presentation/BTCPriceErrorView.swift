//
//  BTCPriceErrorView.swift
//  BTCPrice
//
//  Created by mike on 2026/6/22.
//

import Foundation

@MainActor
public protocol BTCPriceErrorView {
    func display(_ viewModel: BTCPriceErrorViewModel)
}
