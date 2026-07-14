//
//  CoinbaseBTCPriceMapperTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/7/14.
//

import XCTest
@testable import BTCPrice

final class CoinbaseBTCPriceMapperTests: XCTestCase {
    
    func test_map_throwsErrorOnNon200HTTPResponse() throws {
        let samples = [199, 201, 300, 400, 500]
        
        try samples.forEach { code in
            XCTAssertThrowsError(
                try CoinbaseBTCPriceMapper.map(makeItemJSON(amount: "72000.00"), from: makeHTTPURLResponse(statusCode: code))
            )
        }
    }
    
    func test_map_throwsErrorOn200HTTPResponseWithInvalidJSON() {
        let invalidJSON = Data("invalid json".utf8)
        
        XCTAssertThrowsError(
            try CoinbaseBTCPriceMapper.map(invalidJSON, from: makeHTTPURLResponse(statusCode: 200))
        )
    }
    
    func test_map_throwsErrorOn200HTTPResponseWithNonNumericAmount() {
        XCTAssertThrowsError(
            try CoinbaseBTCPriceMapper.map(makeItemJSON(amount: "not-a-number"), from: makeHTTPURLResponse(statusCode: 200))
        )
    }
    
    func test_map_deliversItemOn200HTTPResponseWithValidJSON() throws {
        let item = try CoinbaseBTCPriceMapper.map(
            makeItemJSON(amount: "72648.73"),
            from: makeHTTPURLResponse(statusCode: 200)
        )
        
        XCTAssertEqual(item.price, 72648.73, accuracy: 0.01)
    }
    
    // MARK: - Helpers
    
    private func makeItemJSON(amount: String) -> Data {
        let json: [String: Any] = ["data": ["amount": amount, "base": "BTC", "currency": "USD"]]
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
