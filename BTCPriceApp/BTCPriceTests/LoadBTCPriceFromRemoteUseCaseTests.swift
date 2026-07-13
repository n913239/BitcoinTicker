//
//  LoadBTCPriceFromRemoteUseCaseTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/7/14.
//

import XCTest
@testable import BTCPrice

final class LoadBTCPriceFromRemoteUseCaseTests: XCTestCase {
    
    func test_map_throwsErrorOnNon200HTTPResponse() throws {
        let samples = [199, 201, 300, 400, 500]
        
        try samples.forEach { code in
            XCTAssertThrowsError(
                try BinanceBTCPriceMapper.map(makeItemJSON(price: "72000.00"), from: makeHTTPURLResponse(statusCode: code))
            )
        }
    }
    
    func test_map_throwsErrorOn200HTTPResponseWithInvalidJSON() {
        let invalidJSON = Data("invalid json".utf8)
        
        XCTAssertThrowsError(
            try BinanceBTCPriceMapper.map(invalidJSON, from: makeHTTPURLResponse(statusCode: 200))
        )
    }
    
    func test_map_deliversItemOn200HTTPResponseWithValidJSON() throws {
        let item = try BinanceBTCPriceMapper.map(
            makeItemJSON(price: "72615.55000000"),
            from: makeHTTPURLResponse(statusCode: 200)
        )
        
        XCTAssertEqual(item.price, 72615.55, accuracy: 0.01)
    }
    
    // MARK: - Helpers
    
    private func makeItemJSON(price: String) -> Data {
        let json = ["symbol": "BTCUSDT", "price": price]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeHTTPURLResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://any-url.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
    
}
