//
//  ConsolePriceView.swift
//  BTCPrice
//
//  Created by mike on 2026/6/23.
//

import Foundation

@MainActor
public final class ConsolePriceView: BTCPriceView, BTCPriceLoadingView, BTCPriceErrorView {
    private let output: (String) -> Void
    
    public init(output: @escaping (String) -> Void) {
        self.output = output
    }
    
    public func display(_ viewModel: BTCPriceViewModel) {
        output("BTC/USD: \(viewModel.price)")
    }
    
    public func display(_ viewModel: BTCPriceLoadingViewModel) {
        // No loading indicator for textual output
    }
    
    public func display(_ viewModel: BTCPriceErrorViewModel) {
        if let message = viewModel.message {
            output("ERROR: \(message)")
        }
    }
}
