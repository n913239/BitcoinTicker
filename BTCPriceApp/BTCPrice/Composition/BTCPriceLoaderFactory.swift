//
//  BTCPriceLoaderFactory.swift
//  BTCPrice
//
//  Created by mike on 2026/7/14.
//

import Foundation

public enum BTCPriceLoaderFactory {
    public static let defaultTimeout: TimeInterval = 1.0
    public static let defaultPrimaryTimeout: TimeInterval = 0.5
    
    public static let binanceURL = URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT")!
    public static let cryptoCompareURL = URL(string: "https://min-api.cryptocompare.com/data/generateAvg?fsym=BTC&tsym=USD&e=coinbase")!
    public static let coinbaseURL = URL(string: "https://api.coinbase.com/v2/prices/BTC-USD/spot")!
    
    public static func makeBTCPriceLoader(
        httpClient: HTTPClient,
        timeout: TimeInterval = defaultTimeout,
        primaryTimeout: TimeInterval = defaultPrimaryTimeout
    ) -> BTCPriceLoader {
        let binance = BTCPriceLoaderWithTimeout(
            loader: RemoteBTCPriceLoader(
                url: binanceURL,
                client: httpClient,
                mapper: BinanceBTCPriceMapper.map
            ),
            timeout: primaryTimeout
        )
        let cryptoCompare = RemoteBTCPriceLoader(
            url: cryptoCompareURL,
            client: httpClient,
            mapper: CryptoCompareBTCPriceMapper.map
        )
        let coinbase = RemoteBTCPriceLoader(
            url: coinbaseURL,
            client: httpClient,
            mapper: CoinbaseBTCPriceMapper.map
        )
        
        return BTCPriceLoaderWithTimeout(
            loader: BTCPriceLoaderWithFallback(
                primary: binance,
                fallback: BTCPriceLoaderWithFallback(
                    primary: cryptoCompare,
                    fallback: coinbase
                )
            ),
            timeout: timeout
        )
    }
}
