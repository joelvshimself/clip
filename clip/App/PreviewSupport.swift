//
//  PreviewSupport.swift
//  clip
//

import CoreGraphics
import Foundation

enum PreviewSupport {
    static var sampleVideoURL: URL {
        FallingClipCatalog.urls.first
            ?? URL(fileURLWithPath: "/tmp/clip-preview-placeholder.mp4")
    }

    static var sampleExplosionURL: URL? {
        FallingClipCatalog.explosionURL
    }

    static let phoneSize = CGSize(width: 393, height: 852)

    /// 9:16 portrait placeholder (matches export vomit frame aspect).
    static func yellowPortraitMockCGImage(width: Int = 200) -> CGImage? {
        let height = width * 16 / 9
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.setFillColor(CGColor(red: 1, green: 0.92, blue: 0.23, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}
