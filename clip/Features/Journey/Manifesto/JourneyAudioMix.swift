//
//  JourneyAudioMix.swift
//  clip
//

import Foundation

struct JourneyAudioMix: Equatable {
    var curtainSnap: Float = 0.55
    var explosionVideo: Float = 1.0
    var flashRed: Float = 0.5
    var flashBlack: Float = 0.45
    var handSting: Float = 0.85
    var memeStep: Float = 0.78
    var ringSwell: Float = 0.45
    var catResolve: Float = 0.5
    var morph: Float = 0.65
    var ctaResolve: Float = 0.42
    var ringSpin: Float = 0.38

    static var current = JourneyAudioMix()

    func volume(for cue: JourneyAudioCue) -> Float {
        switch cue {
        case .curtainSnap: return curtainSnap
        case .explosion: return explosionVideo
        case .flashRed: return flashRed
        case .flashBlack: return flashBlack
        case .handSting: return handSting
        case .memeStep: return memeStep
        case .ringSwell: return ringSwell
        case .catResolve: return catResolve
        case .morph: return morph
        case .ctaResolve: return ctaResolve
        case .ringSpin: return ringSpin
        }
    }

    var swiftSnippet: String {
        """
        static var current = JourneyAudioMix(
            curtainSnap: \(format(curtainSnap)),
            explosionVideo: \(format(explosionVideo)),
            flashRed: \(format(flashRed)),
            flashBlack: \(format(flashBlack)),
            handSting: \(format(handSting)),
            memeStep: \(format(memeStep)),
            ringSwell: \(format(ringSwell)),
            catResolve: \(format(catResolve)),
            morph: \(format(morph)),
            ctaResolve: \(format(ctaResolve)),
            ringSpin: \(format(ringSpin))
        )
        """
    }

    private func format(_ value: Float) -> String {
        String(format: "%.2f", value)
    }
}
