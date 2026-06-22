//
//  URLSessionHTTPClient.swift
//  BTCPrice
//
//  Created by mike on 2026/6/22.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession) {
        self.session = session
    }
    
    public func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(from: url)
        return (data, response as! HTTPURLResponse)
    }
}
