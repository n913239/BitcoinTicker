//
//  BTCPriceLoadingViewModel.swift
//  BTCPrice
//
//  Created by mike on 2026/7/14.
//

public struct BTCPriceLoadingViewModel: Equatable {
    public let isLoading: Bool
    
    public init(isLoading: Bool) {
        self.isLoading = isLoading
    }
}
