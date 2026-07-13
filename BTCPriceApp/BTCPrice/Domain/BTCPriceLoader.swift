//
//  BTCPriceLoader.swift
//  BTCPrice
//
//  Created by mike on 2026/7/14.
//

public protocol BTCPriceLoader {
    func load() async throws -> BTCPriceItem
}
