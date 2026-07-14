//
//  BTCPriceLoaderWithFallback.swift
//  BTCPrice
//
//  Created by mike on 2026/7/14.
//

public final class BTCPriceLoaderWithFallback: BTCPriceLoader {
    private let primary: BTCPriceLoader
    private let fallback: BTCPriceLoader
    
    public init(primary: BTCPriceLoader, fallback: BTCPriceLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    public func load() async throws -> BTCPriceItem {
        do {
            return try await primary.load()
        } catch {
            return try await fallback.load()
        }
    }
}
