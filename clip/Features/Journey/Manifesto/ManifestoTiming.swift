//
//  ManifestoTiming.swift
//  clip
//

import CoreGraphics
import Foundation

struct ManifestoFlashEntry: Equatable {
    let text: String
    let isRedBackground: Bool
    var showsSilhouette: Bool = false
    var showsHandVideo: Bool = false
    var duration: TimeInterval = ManifestoTiming.flashDuration
}

enum ManifestoTiming {
    static let flashDuration: TimeInterval = 0.3
    static let handFlashDuration: TimeInterval = 1.0
    static let handWordVideoDuration: TimeInterval = 2.0

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
        ManifestoFlashEntry(
            text: "hand",
            isRedBackground: false,
            showsHandVideo: true,
            duration: handWordVideoDuration
        ),
    ]

    static var flashSequenceDuration: TimeInterval {
        flashes.reduce(0) { $0 + $1.duration }
    }

    // Meme orbit sequence (after word flashes)
    static let memeSoloClipDuration: TimeInterval = 0.4
    static let memeSoloFadeDuration: TimeInterval = 0.08
    static let memeRingFormDuration: TimeInterval = 2.0
    static let memeCatPixelResolveDuration: TimeInterval = 0.28
    static let memeCatHoldBeforeMorph: TimeInterval = 1.0
    static let memeCatMorphPixelIn: TimeInterval = 0.16
    static let memeCatMorphPixelOut: TimeInterval = 0.16
    static let memeOrbitClipCount = 8
    static let memeRingRadiusXFraction: CGFloat = 0.36
    static let memeRingRadiusYFraction: CGFloat = 0.50
    static let memeRingMorphRadiusBoost: CGFloat = 0.04
    static let memeRingSpinPeriod: TimeInterval = 4.5
    static let memeSoloVideoVolume: Float = 0.85
    static let memeSoloAudioFadeDuration: TimeInterval = 0.1
    static let catThnxHorizontalNudge: CGFloat = -14

    static var memeSoloSequenceDuration: TimeInterval {
        Double(memeOrbitClipCount) * memeSoloClipDuration
    }

    static var memeOrbitSequenceDuration: TimeInterval {
        memeSoloSequenceDuration
            + memeRingFormDuration
            + memeCatHoldBeforeMorph
            + memeCatMorphPixelIn
            + memeCatMorphPixelOut
    }
}
