//
//  ExplosionPlaybackCache.swift
//  clip
//

import AVFoundation

enum ExplosionPlaybackCache {
    private static var warmedURL: URL?
    private static var warmedItem: AVPlayerItem?

    static func prewarm(url: URL) {
        guard warmedURL != url else { return }
        JourneyAudio.prepareSession()
        warmedURL = url
        warmedItem = AVPlayerItem(url: url)
    }

    static func playerItem(for url: URL) -> AVPlayerItem {
        if warmedURL == url, let warmedItem {
            self.warmedItem = nil
            return warmedItem
        }
        return AVPlayerItem(url: url)
    }

    static func clear() {
        warmedURL = nil
        warmedItem = nil
    }
}
