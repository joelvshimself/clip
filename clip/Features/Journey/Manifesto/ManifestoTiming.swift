//
//  ManifestoTiming.swift
//  clip
//

import Foundation

struct ManifestoFlashEntry: Equatable {
    let text: String
    let isRedBackground: Bool
    var showsSilhouette: Bool = false
    var duration: TimeInterval = ManifestoTiming.flashDuration
}

enum ManifestoTiming {
    static let flashDuration: TimeInterval = 0.3
    static let handFlashDuration: TimeInterval = 1.0

    static let flashes: [ManifestoFlashEntry] = [
        ManifestoFlashEntry(text: "all", isRedBackground: true),
        ManifestoFlashEntry(text: "of", isRedBackground: false),
        ManifestoFlashEntry(text: "this", isRedBackground: true),
        ManifestoFlashEntry(
            text: "power",
            isRedBackground: false,
            showsSilhouette: true,
            duration: handFlashDuration
        ),
        ManifestoFlashEntry(text: "is", isRedBackground: true),
        ManifestoFlashEntry(text: "in", isRedBackground: false),
        ManifestoFlashEntry(text: "your", isRedBackground: true),
        ManifestoFlashEntry(text: "hand", isRedBackground: false),
    ]

    static var flashSequenceDuration: TimeInterval {
        flashes.reduce(0) { $0 + $1.duration }
    }
}
