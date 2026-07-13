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
        let url = URL(string: "https://any-url.com")!
        let expectedError = NSError(domain: "any error", code: 0)
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        
        do {
            _ = try await sut.get(from: url)
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_getFromURL_failsOnNonHTTPURLResponse() async {
        let url = URL(string: "https://any-url.com")!
        let nonHTTPResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        URLProtocolStub.stub(data: Data(), response: nonHTTPResponse, error: nil)
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        
        do {
            _ = try await sut.get(from: url)
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertTrue(error is URLSessionHTTPClient.UnexpectedValuesRepresentation, "Expected UnexpectedValuesRepresentation, got \(error)")
        }
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() async throws {
        let url = URL(string: "https://any-url.com")!
        let expectedData = Data("any data".utf8)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        URLProtocolStub.stub(data: expectedData, response: expectedResponse, error: nil)
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        
        let (data, response) = try await sut.get(from: url)
        
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual(response.statusCode, expectedResponse.statusCode)
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
