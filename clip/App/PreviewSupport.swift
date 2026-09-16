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
}
