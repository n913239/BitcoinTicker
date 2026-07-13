//
//  BTCPriceItemTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/7/14.
//

import XCTest
@testable import BTCPrice

final class BTCPriceItemTests: XCTestCase {
    
    func test_btcPriceItem_holdsPrice() {
        let item = BTCPriceItem(price: 83000.50)
        
        XCTAssertEqual(item.price, 83000.50)
    }
    
}
