//
//  SnapshotTestHelpers.swift
//  BTCPriceiOSTests
//
//  Created by mike on 2026/6/23.
//

import XCTest
import UIKit

// MARK: - XCTestCase Snapshot Assertions

extension XCTestCase {
    
    func assert(snapshot: UIImage, named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let snapshotURL = makeSnapshotURL(named: name, file: file)
        
        guard
            let storedSnapshotData = try? Data(contentsOf: snapshotURL),
            let storedSnapshot = UIImage(data: storedSnapshotData)
        else {
            XCTFail("No reference snapshot found at \(snapshotURL). Use record(snapshot:named:) to store one first.", file: file, line: line)
            return
        }
        
        if !snapshot.matchesSnapshot(storedSnapshot, precision: 0.98, perChannelTolerance: 32) {
            let temporarySnapshotURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent(snapshotURL.lastPathComponent)
            try? snapshot.pngData()?.write(to: temporarySnapshotURL)
            XCTFail("New snapshot does not match stored snapshot. New: \(temporarySnapshotURL). Stored: \(snapshotURL).", file: file, line: line)
        }
    }
    
    func record(snapshot: UIImage, named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let snapshotURL = makeSnapshotURL(named: name, file: file)
        let snapshotData = makeSnapshotData(for: snapshot, file: file, line: line)
        
        do {
            try FileManager.default.createDirectory(
                at: snapshotURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try snapshotData?.write(to: snapshotURL)
            XCTFail("Record succeeded. Switch to assert(snapshot:named:) to verify from now on.", file: file, line: line)
        } catch {
            XCTFail("Failed to record snapshot with error: \(error)", file: file, line: line)
        }
    }
    
    private func makeSnapshotURL(named name: String, file: StaticString) -> URL {
        URL(fileURLWithPath: String(describing: file))
            .deletingLastPathComponent()
            .appendingPathComponent("snapshots")
            .appendingPathComponent("\(name).png")
    }
    
    private func makeSnapshotData(for snapshot: UIImage, file: StaticString, line: UInt) -> Data? {
        guard let data = snapshot.pngData() else {
            XCTFail("Failed to generate PNG data from snapshot", file: file, line: line)
            return nil
        }
        return data
    }
}

// MARK: - SnapshotConfiguration

struct SnapshotConfiguration {
    let size: CGSize
    let safeAreaInsets: UIEdgeInsets
    let layoutMargins: UIEdgeInsets
    let traitCollection: UITraitCollection
    
    static func iPhone(
        style: UIUserInterfaceStyle,
        contentSize: UIContentSizeCategory = .medium
    ) -> SnapshotConfiguration {
        SnapshotConfiguration(
            size: CGSize(width: 390, height: 844),
            safeAreaInsets: UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0),
            layoutMargins: UIEdgeInsets(top: 55, left: 8, bottom: 42, right: 8),
            traitCollection: UITraitCollection(mutations: { traits in
                traits.forceTouchCapability = .unavailable
                traits.layoutDirection = .leftToRight
                traits.preferredContentSizeCategory = contentSize
                traits.userInterfaceIdiom = .phone
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .regular
                traits.displayScale = 3
                traits.accessibilityContrast = .normal
                traits.displayGamut = .P3
                traits.userInterfaceStyle = style
            })
        )
    }
}

// MARK: - UIViewController Snapshot

extension UIViewController {
    func snapshot(for configuration: SnapshotConfiguration = .iPhone(style: .light)) -> UIImage {
        let window = SnapshotWindow(configuration: configuration, root: self)
        let image = window.snapshot()
        window.rootViewController = nil
        window.isHidden = true
        return image
    }
}

// MARK: - SnapshotWindow

private final class SnapshotWindow: UIWindow {
    private var configuration: SnapshotConfiguration = .iPhone(style: .light)
    
    convenience init(configuration: SnapshotConfiguration, root: UIViewController) {
        let dummyScene = (UIWindowScene.self as NSObject.Type).init() as! UIWindowScene
        self.init(windowScene: dummyScene)
        self.frame = CGRect(origin: .zero, size: configuration.size)
        self.configuration = configuration
        self.layoutMargins = configuration.layoutMargins
        self.rootViewController = root
        self.isHidden = false
        root.view.layoutMargins = configuration.layoutMargins
    }
    
    override var safeAreaInsets: UIEdgeInsets {
        configuration.safeAreaInsets
    }
    
    override var traitCollection: UITraitCollection {
        configuration.traitCollection
    }
    
    func snapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: .init(for: traitCollection))
        return renderer.image { action in
            layer.render(in: action.cgContext)
        }
    }
}

// MARK: - Tolerant image comparison

private extension UIImage {
    /// 容許小幅每像素差異的比對。
    /// - precision: 必須相符的像素比例（0...1）。
    /// - perChannelTolerance: 每個 RGBA channel 容許的最大差（0...255）。
    func matchesSnapshot(_ other: UIImage, precision: Double, perChannelTolerance: UInt8) -> Bool {
        guard
            let a = cgImage, let b = other.cgImage,
            a.width == b.width, a.height == b.height,
            let bytesA = a.rgbaBytes(), let bytesB = b.rgbaBytes(),
            bytesA.count == bytesB.count
        else { return false }
        
        let tolerance = Int(perChannelTolerance)
        let pixelCount = bytesA.count / 4
        guard pixelCount > 0 else { return false }
        
        var matching = 0
        var i = 0
        while i < bytesA.count {
            let dr = abs(Int(bytesA[i]) - Int(bytesB[i]))
            let dg = abs(Int(bytesA[i + 1]) - Int(bytesB[i + 1]))
            let db = abs(Int(bytesA[i + 2]) - Int(bytesB[i + 2]))
            let da = abs(Int(bytesA[i + 3]) - Int(bytesB[i + 3]))
            if dr <= tolerance && dg <= tolerance && db <= tolerance && da <= tolerance {
                matching += 1
            }
            i += 4
        }
        
        return Double(matching) / Double(pixelCount) >= precision
    }
}

private extension CGImage {
    func rgbaBytes() -> [UInt8]? {
        let bytesPerRow = width * 4
        var data = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return data
    }
}
