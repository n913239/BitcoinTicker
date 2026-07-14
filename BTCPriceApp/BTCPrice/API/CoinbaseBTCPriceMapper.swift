//
//  CoinbaseBTCPriceMapper.swift
//  BTCPrice
//
//  Created by mike on 2026/7/14.
//

import Foundation

public enum CoinbaseBTCPriceMapper {
    
    private struct Root: Decodable {
        let data: SpotPrice
        
        struct SpotPrice: Decodable {
            let amount: String
        }
    }
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> BTCPriceItem {
        guard response.statusCode == 200,
              let root = try? JSONDecoder().decode(Root.self, from: data),
              let price = Double(root.data.amount) else {
            throw Error.invalidData
        }
        
        return BTCPriceItem(price: price)
    }
    
}
