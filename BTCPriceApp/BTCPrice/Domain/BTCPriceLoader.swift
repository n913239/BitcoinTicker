//
//  BTCPriceLoader.swift
//  BTCPrice
//
//  Created by mike on 2026/6/22.
//

public protocol BTCPriceLoader {
    func load() async throws -> BTCPriceItem
}
