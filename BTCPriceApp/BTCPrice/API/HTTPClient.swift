//
//  HTTPClient.swift
//  BTCPrice
//
//  Created by mike on 2026/6/22.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}
