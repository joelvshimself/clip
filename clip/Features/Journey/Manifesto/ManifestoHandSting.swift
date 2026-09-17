//
//  ManifestoHandSting.swift
//  clip
//

import AVFoundation

enum ManifestoHandSting {
    private static var player: AVAudioPlayer?

    static func play() {
        guard let url = Bundle.main.url(
            forResource: "manifesto_hand_sting",
            withExtension: "wav",
            subdirectory: "Resources/Media"
        ) ?? Bundle.main.url(forResource: "manifesto_hand_sting", withExtension: "wav")
        else { return }

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        player?.play()
    }
}
