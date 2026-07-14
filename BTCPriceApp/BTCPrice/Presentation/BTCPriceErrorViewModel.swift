//
//  BTCPriceErrorViewModel.swift
//  BTCPrice
//
//  Created by mike on 2026/7/14.
//

public struct BTCPriceErrorViewModel: Equatable {
    public let message: String?
    
    public static var noError: BTCPriceErrorViewModel {
        BTCPriceErrorViewModel(message: nil)
    }
    
    public static func error(message: String) -> BTCPriceErrorViewModel {
        BTCPriceErrorViewModel(message: message)
    }
}
