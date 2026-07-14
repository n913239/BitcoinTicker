//
//  BTCPriceViewController.swift
//  BTCPriceApp
//
//  Created by mike on 2026/7/14.
//

import UIKit
import BTCPrice

@MainActor
final class BTCPriceViewController: UIViewController, BTCPriceView, BTCPriceLoadingView, BTCPriceErrorView {
    
    enum AccessibilityIdentifier {
        static let priceLabel = "btc-price-label"
        static let errorLabel = "btc-error-label"
        static let loadingIndicator = "btc-loading-indicator"
    }
    
    var onAppear: (() -> Void)?
    var onDisappear: (() -> Void)?
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 48, weight: .bold))
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = AccessibilityIdentifier.priceLabel
        return label
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = AccessibilityIdentifier.errorLabel
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.accessibilityIdentifier = AccessibilityIdentifier.loadingIndicator
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onAppear?()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDisappear?()
    }
    
    // MARK: - View Protocols
    
    func display(_ viewModel: BTCPriceViewModel) {
        priceLabel.text = viewModel.price
    }
    
    func display(_ viewModel: BTCPriceLoadingViewModel) {
        if viewModel.isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
    
    func display(_ viewModel: BTCPriceErrorViewModel) {
        errorLabel.text = viewModel.message
        errorLabel.isHidden = viewModel.message == nil
    }
    
    // MARK: - Private
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(priceLabel)
        view.addSubview(errorLabel)
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            priceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            priceLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            priceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            priceLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            
            errorLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: priceLabel.topAnchor, constant: -32)
        ])
    }
}
