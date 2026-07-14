//
//  CryptoCompareBTCPriceMapper.swift
//  BTCPrice
//
//  Created by mike on 2026/7/14.
//

import Foundation

public enum CryptoCompareBTCPriceMapper {
    
    private struct Root: Decodable {
        let raw: Aggregate
        
        private enum CodingKeys: String, CodingKey {
            case raw = "RAW"
        }
        
        struct Aggregate: Decodable {
            let price: Double
            
            private enum CodingKeys: String, CodingKey {
                case price = "PRICE"
            }
        }
    }
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> BTCPriceItem {
        guard response.statusCode == 200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw Error.invalidData
        }
        
        return BTCPriceItem(price: root.raw.price)
    }
    
}
