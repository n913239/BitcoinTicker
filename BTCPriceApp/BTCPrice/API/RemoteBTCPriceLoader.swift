//
//  RemoteBTCPriceLoader.swift
//  BTCPrice
//
//  Created by mike on 2026/7/14.
//

import Foundation

public final class RemoteBTCPriceLoader: BTCPriceLoader {
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    private let url: URL
    private let client: HTTPClient
    private let mapper: (Data, HTTPURLResponse) throws -> BTCPriceItem
    
    public init(url: URL, client: HTTPClient, mapper: @escaping (Data, HTTPURLResponse) throws -> BTCPriceItem) {
        self.url = url
        self.client = client
        self.mapper = mapper
    }
    
    public func load() async throws -> BTCPriceItem {
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await client.get(from: url)
        } catch {
            throw Error.connectivity
        }
        
        do {
            return try mapper(data, response)
        } catch {
            throw Error.invalidData
        }
    }
}
