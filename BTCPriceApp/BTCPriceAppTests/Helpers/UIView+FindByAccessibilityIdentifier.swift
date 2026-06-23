//
//  UIView+FindByAccessibilityIdentifier.swift
//  BTCPriceAppTests
//
//  Created by mike on 2026/6/23.
//

import UIKit

extension UIView {
    
    /// Depth-first search for a descendant view whose `accessibilityIdentifier` matches.
    /// Returns `self` if it matches.
    func findElement(byAccessibilityIdentifier identifier: String) -> UIView? {
        if accessibilityIdentifier == identifier { return self }
        for subview in subviews {
            if let match = subview.findElement(byAccessibilityIdentifier: identifier) {
                return match
            }
        }
        return nil
    }
    
    func findLabel(byAccessibilityIdentifier identifier: String) -> UILabel? {
        findElement(byAccessibilityIdentifier: identifier) as? UILabel
    }
    
    func findActivityIndicator(byAccessibilityIdentifier identifier: String) -> UIActivityIndicatorView? {
        findElement(byAccessibilityIdentifier: identifier) as? UIActivityIndicatorView
    }
}
