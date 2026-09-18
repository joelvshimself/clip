//
//  JourneyAudio.swift
//  clip
//

import AVFoundation

enum JourneyAudioCue {
    case curtainSnap
    case explosion
    case flashRed
    case flashBlack
    case handSting
    case memeStep
    case ringSwell
    case catResolve
    case morph
    case ctaResolve
    case ringSpin
}

enum JourneyAudio {
    private static var activePlayers: [AVAudioPlayer] = []
    private static var loopingPlayer: AVAudioPlayer?
    private static var sessionPrepared = false

    static func prepareSession() {
        guard !sessionPrepared else { return }
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        sessionPrepared = true
    }

    static func play(_ cue: JourneyAudioCue, volumeOverride: Float? = nil) {
        prepareSession()
        pruneFinishedPlayers()

        guard let url = url(for: cue) else { return }
        let targetVolume = volumeOverride ?? volume(for: cue)
        playURL(url, volume: min(1, targetVolume))
        if targetVolume > 1 {
            playURL(url, volume: min(1, targetVolume - 1))
        }
    }

    private static func playURL(_ url: URL, volume: Float) {
        guard volume > 0 else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = volume
        player.prepareToPlay()
        player.play()
        activePlayers.append(player)
    }

    static func playLooping(_ cue: JourneyAudioCue, volumeOverride: Float? = nil) {
        prepareSession()
        stopLooping()

        guard let url = url(for: cue) else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }

        let targetVolume = volumeOverride ?? volume(for: cue)
        player.volume = 0
        player.numberOfLoops = -1
        player.prepareToPlay()
        player.play()
        player.setVolume(targetVolume, fadeDuration: 0.25)
        loopingPlayer = player
    }

    static func stopLooping() {
        loopingPlayer?.stop()
        loopingPlayer = nil
    }

    static func stopAll() {
        stopLooping()
        for player in activePlayers {
            player.stop()
        }
        activePlayers.removeAll()
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
        sessionPrepared = false
    }

    private static func pruneFinishedPlayers() {
        activePlayers.removeAll { !$0.isPlaying }
    }

    private static func url(for cue: JourneyAudioCue) -> URL? {
        let name: String
        let subdirectory: String?

        switch cue {
        case .curtainSnap:
            name = "curtain_snap"
            subdirectory = "Resources/Media/Onboarding"
        case .explosion:
            name = "explosion"
            subdirectory = "Resources/Media/Onboarding"
        case .flashRed:
            name = "flash_red"
            subdirectory = "Resources/Media/Onboarding"
        case .flashBlack:
            name = "flash_black"
            subdirectory = "Resources/Media/Onboarding"
        case .handSting:
            name = "manifesto_hand_sting"
            subdirectory = "Resources/Media"
        case .memeStep:
            name = "meme_step"
            subdirectory = "Resources/Media/Onboarding"
        case .ringSwell:
            name = "ring_swell"
            subdirectory = "Resources/Media/Onboarding"
        case .catResolve:
            name = "cat_resolve"
            subdirectory = "Resources/Media/Onboarding"
        case .morph:
            name = "morph"
            subdirectory = "Resources/Media/Onboarding"
        case .ctaResolve:
            name = "cta_resolve"
            subdirectory = "Resources/Media/Onboarding"
        case .ringSpin:
            name = "ring_spin"
            subdirectory = "Resources/Media/Onboarding"
        }

        return Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: subdirectory)
            ?? Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Media/Onboarding")
            ?? Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Media")
            ?? Bundle.main.url(forResource: name, withExtension: "wav")
    }

    private static func volume(for cue: JourneyAudioCue) -> Float {
        JourneyAudioMix.current.volume(for: cue)
    }
}

enum ManifestoHandSting {
    static func play() {
        JourneyAudio.play(.handSting)
    }
}
