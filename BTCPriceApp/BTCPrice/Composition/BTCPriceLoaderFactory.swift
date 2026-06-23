//
//  BTCPriceLoaderFactory.swift
//  BTCPrice
//
//  Created by mike on 2026/6/23.
//

import Foundation

public enum BTCPriceLoaderFactory {
    public static let defaultTimeout: TimeInterval = 1.0
    
    public static let binanceURL = URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT")!
    public static let coinbaseURL = URL(string: "https://api.coinbase.com/v2/prices/BTC-USD/spot")!
    
    public static func makeBTCPriceLoader(
        httpClient: HTTPClient,
        timeout: TimeInterval = defaultTimeout
    ) -> BTCPriceLoader {
        let primary = RemoteBTCPriceLoader(
            url: binanceURL,
            client: httpClient,
            mapper: BinanceBTCPriceMapper.map
        )
        let fallback = RemoteBTCPriceLoader(
            url: coinbaseURL,
            client: httpClient,
            mapper: CoinbaseBTCPriceMapper.map
        )
        return BTCPriceLoaderWithTimeout(
            loader: BTCPriceLoaderWithFallback(primary: primary, fallback: fallback),
            timeout: timeout
        )
    }
}
