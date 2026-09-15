//
//  FallingClipCatalog.swift
//  clip
//

import Foundation

enum FallingClipCatalog {
    static let resourceNames: [String] = [
        "clip01", "clip02", "clip03", "clip04", "clip05",
        "clip06", "clip07", "clip08", "clip09", "clip10",
    ]

    static func url(for resourceName: String) -> URL? {
        Bundle.main.url(
            forResource: resourceName,
            withExtension: "mp4",
            subdirectory: "Resources/Media/Clips"
        )
            ?? Bundle.main.url(forResource: resourceName, withExtension: "mp4", subdirectory: "Media/Clips")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "mp4")
    }

    static var urls: [URL] {
        resourceNames.compactMap { url(for: $0) }
    }

    static var explosionURL: URL? {
        Bundle.main.url(forResource: "explosion", withExtension: "mov", subdirectory: "Resources/Media")
            ?? Bundle.main.url(forResource: "explosion", withExtension: "mov", subdirectory: "Media")
            ?? Bundle.main.url(forResource: "explosion", withExtension: "mov")
    }
}
