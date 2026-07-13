//
//  URLSessionHTTPClientTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/7/14.
//

import XCTest
@testable import BTCPrice

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startIntercepting()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopIntercepting()
    }
    
    func test_getFromURL_failsOnRequestError() async {
        let expectedError = anyError()
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)
        
        do {
            _ = try await makeSUT().get(from: anyURL())
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() async throws {
        let expectedData = Data("any data".utf8)
        let expectedResponse = makeHTTPURLResponse(statusCode: 200)
        URLProtocolStub.stub(data: expectedData, response: expectedResponse, error: nil)
        
        let (data, response) = try await makeSUT().get(from: anyURL())
        
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual(response.statusCode, expectedResponse.statusCode)
    }
    
    func test_getFromURL_failsOnNonHTTPURLResponse() async {
        let nonHTTPResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        URLProtocolStub.stub(data: Data(), response: nonHTTPResponse, error: nil)
        
        do {
            _ = try await makeSUT().get(from: anyURL())
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertTrue(error is URLSessionHTTPClient.UnexpectedValuesRepresentation, "Expected UnexpectedValuesRepresentation, got \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func anyURL() -> URL {
        URL(string: "https://any-url.com")!
    }
    
    private func makeHTTPURLResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
    
    private func anyError() -> NSError {
        NSError(domain: "any error", code: 0)
    }
    
}

// MARK: - URLProtocol Stub

private class URLProtocolStub: URLProtocol {
    private static var stub: Stub?
    
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }
    
    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        stub = Stub(data: data, response: response, error: error)
    }
    
    static func startIntercepting() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopIntercepting() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stub = nil
    }
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    
    override func startLoading() {
        if let error = URLProtocolStub.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {}
}
