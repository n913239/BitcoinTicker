//
//  BTCPriceAPIEndToEndTests.swift
//  BTCPriceAPIEndToEndTests
//
//  Created by mike on 2026/7/14.
//

import XCTest
import BTCPrice

final class BTCPriceAPIEndToEndTests: XCTestCase {
    
    func test_endToEndBinanceLoad_deliversItemWithPositivePrice() async {
        switch await loadResult(from: BTCPriceLoaderFactory.binanceURL) {
        case let .success(item):
            XCTAssertGreaterThan(item.price, 0, "Expected Binance to deliver a positive BTC price, got \(item.price) instead")
            
        case let .failure(error):
            XCTFail("Expected successful Binance result, got \(error) instead")
        }
    }
    
    func test_endToEndCoinbaseLoad_deliversItemWithPositivePrice() async {
        switch await loadResult(from: BTCPriceLoaderFactory.coinbaseURL, mapper: CoinbaseBTCPriceMapper.map) {
        case let .success(item):
            XCTAssertGreaterThan(item.price, 0, "Expected Coinbase to deliver a positive BTC price, got \(item.price) instead")
            
        case let .failure(error):
            XCTFail("Expected successful Coinbase result, got \(error) instead")
        }
    }
    
    func test_endToEndFallbackChain_deliversItemWithPositivePriceWhileASourceIsUnavailable() async {
        let loader = BTCPriceLoaderFactory.makeBTCPriceLoader(
            httpClient: ephemeralClient(),
            timeout: 10.0,
            primaryTimeout: 5.0
        )
        
        do {
            let item = try await loader.load()
            XCTAssertGreaterThan(item.price, 0, "Expected the fallback chain to deliver a positive BTC price, got \(item.price) instead")
        } catch {
            XCTFail("Expected the fallback chain to deliver a price, got \(error) instead")
        }
    }
    
    // MARK: - Helpers
    
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
