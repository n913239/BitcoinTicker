//
//  RemoteBTCPriceLoaderTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/7/14.
//

import XCTest
@testable import BTCPrice

final class RemoteBTCPriceLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() async throws {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        client.stub(data: makeValidData(), response: makeHTTPURLResponse(statusCode: 200), error: nil)
        
        _ = try await sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_deliversConnectivityErrorOnClientError() async {
        let (sut, client) = makeSUT()
        client.stub(data: nil, response: nil, error: anyError())
        
        do {
            _ = try await sut.load()
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertEqual(error as? RemoteBTCPriceLoader.Error, .connectivity)
        }
    }
    
    func test_load_deliversInvalidDataErrorOnMapperError() async {
        let (sut, client) = makeSUT()
        client.stub(data: makeInvalidData(), response: makeHTTPURLResponse(statusCode: 200), error: nil)
        
        do {
            _ = try await sut.load()
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertEqual(error as? RemoteBTCPriceLoader.Error, .invalidData)
        }
    }
    
    func test_load_deliversItemOnSuccessfulMapping() async throws {
        let (sut, client) = makeSUT()
        client.stub(data: makeValidData(), response: makeHTTPURLResponse(statusCode: 200), error: nil)
        
        let item = try await sut.load()
        
        XCTAssertEqual(item.price, 72615.55, accuracy: 0.01)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        url: URL = URL(string: "https://any-url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteBTCPriceLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteBTCPriceLoader(url: url, client: client, mapper: BinanceBTCPriceMapper.map)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func makeValidData() -> Data {
        let json = ["symbol": "BTCUSDT", "price": "72615.55000000"]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeInvalidData() -> Data {
        Data("invalid".utf8)
    }
    
    private func makeHTTPURLResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://any-url.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
    
    private func anyError() -> NSError {
        NSError(domain: "any error", code: 0)
    }
    
}

// MARK: - Spy

private class HTTPClientSpy: HTTPClient {
    private(set) var requestedURLs: [URL] = []
    private var stub: (data: Data?, response: HTTPURLResponse?, error: Error?)?
    
    func stub(data: Data?, response: HTTPURLResponse?, error: Error?) {
        self.stub = (data, response, error)
    }
    
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        requestedURLs.append(url)
        
        if let error = stub?.error {
            throw error
        }
        
        return (stub!.data!, stub!.response!)
    }
}
