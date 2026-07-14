//
//  SceneDelegate.swift
//  BTCPriceApp
//
//  Created by mike on 2026/7/13.
//

import UIKit
import BTCPrice

@MainActor
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    private lazy var httpClient: HTTPClient = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    private lazy var scheduler: Scheduler = DispatchSourceTimerScheduler()
    
    override init() {
        super.init()
    }
    
    convenience init(httpClient: HTTPClient, scheduler: Scheduler) {
        self.init()
        self.httpClient = httpClient
        self.scheduler = scheduler
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        configureWindow()
    }
    
    func configureWindow() {
        window?.rootViewController = BTCPriceUIComposer.compose(
            httpClient: httpClient,
            scheduler: scheduler
        )
        window?.makeKeyAndVisible()
    }
    
}
