//
//  ManifestoMedia.swift
//  clip
//

import Foundation

enum ManifestoMedia {
    static var glovePoofHitURL: URL? {
        Bundle.main.url(
            forResource: "glove_poof_hit_2s",
            withExtension: "mp4",
            subdirectory: "Resources/Media/Onboarding"
        )
            ?? Bundle.main.url(forResource: "glove_poof_hit_2s", withExtension: "mp4", subdirectory: "Media/Onboarding")
            ?? Bundle.main.url(forResource: "glove_poof_hit_2s", withExtension: "mp4")
    }
}
