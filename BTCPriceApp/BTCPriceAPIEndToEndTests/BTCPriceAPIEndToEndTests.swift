//
//  BTCPriceAPIEndToEndTests.swift
//  BTCPriceAPIEndToEndTests
//
//  Created by mike on 2026/6/22.
//

import XCTest
import BTCPrice

/// End-to-end tests that hit the real Binance and Coinbase endpoints.
///
/// These tests are intentionally excluded from the CI test plans because they depend on
/// network reachability and the third-party APIs being up. Run them locally before
/// shipping changes that touch the networking or mapper layers.
final class BTCPriceAPIEndToEndTests: XCTestCase {
    
    func test_endToEndBinanceLoad_deliversItemWithPositivePrice() async {
        switch await loadResult(from: binanceURL) {
        case let .success(item):
            XCTAssertGreaterThan(item.price, 0, "Expected Binance to deliver a positive BTC price, got \(item.price) instead")
            
        case let .failure(error):
            XCTFail("Expected successful Binance result, got \(error) instead")
        }
    }
    
    func test_endToEndCoinbaseLoad_deliversItemWithPositivePrice() async {
        switch await loadResult(from: coinbaseURL, mapper: CoinbaseBTCPriceMapper.map) {
        case let .success(item):
            XCTAssertGreaterThan(item.price, 0, "Expected Coinbase to deliver a positive BTC price, got \(item.price) instead")
            
        case let .failure(error):
            XCTFail("Expected successful Coinbase result, got \(error) instead")
        }
    }
    
    // MARK: - Helpers
    
    private var binanceURL: URL {
        URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT")!
    }
    
    private var coinbaseURL: URL {
        URL(string: "https://api.coinbase.com/v2/prices/BTC-USD/spot")!
    }
    
    private func loadResult(
        from url: URL,
        mapper: @escaping (Data, HTTPURLResponse) throws -> BTCPriceItem = BinanceBTCPriceMapper.map,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> Result<BTCPriceItem, Error> {
        let client = ephemeralClient(file: file, line: line)
        do {
            let (data, response) = try await client.get(from: url)
            return .success(try mapper(data, response))
        } catch {
            return .failure(error)
        }
    }
    
    private func ephemeralClient(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        let client = URLSessionHTTPClient(session: URLSession(configuration: configuration))
        trackForMemoryLeaks(client, file: file, line: line)
        return client
    }
    
    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
