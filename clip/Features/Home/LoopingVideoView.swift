//
//  LoopingVideoView.swift
//  clip
//

import AVFoundation
import SwiftUI

#if os(iOS)
import UIKit

struct LoopingVideoView: UIViewRepresentable {
    let url: URL
    var previewLoopDuration: TimeInterval? = nil
    var isMuted: Bool = true
    var playbackVolume: Float = 1.0
    var volumeFadeDuration: TimeInterval = 0.1

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        LoopingPlayerUIView(
            url: url,
            previewLoopDuration: previewLoopDuration,
            isMuted: isMuted,
            playbackVolume: playbackVolume,
            volumeFadeDuration: volumeFadeDuration
        )
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        uiView.configure(
            url: url,
            previewLoopDuration: previewLoopDuration,
            isMuted: isMuted,
            playbackVolume: playbackVolume,
            volumeFadeDuration: volumeFadeDuration
        )
    }
}

final class LoopingPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var timeObserver: Any?
    private var previewLoopDuration: TimeInterval?
    private var currentURL: URL?
    private var currentMuted = true
    private var currentVolume: Float = 1.0
    private var volumeFadeTask: Task<Void, Never>?

    private var volumeFadeDuration: TimeInterval = 0.1

    init(
        url: URL,
        previewLoopDuration: TimeInterval?,
        isMuted: Bool,
        playbackVolume: Float,
        volumeFadeDuration: TimeInterval
    ) {
        super.init(frame: .zero)
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        self.volumeFadeDuration = volumeFadeDuration
        configure(
            url: url,
            previewLoopDuration: previewLoopDuration,
            isMuted: isMuted,
            playbackVolume: playbackVolume,
            volumeFadeDuration: volumeFadeDuration
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        url: URL,
        previewLoopDuration: TimeInterval?,
        isMuted: Bool,
        playbackVolume: Float,
        volumeFadeDuration: TimeInterval
    ) {
        self.volumeFadeDuration = volumeFadeDuration
        if currentURL == url,
           self.previewLoopDuration == previewLoopDuration,
           currentMuted == isMuted,
           abs(currentVolume - playbackVolume) < 0.001 {
            return
        }

        let urlChanged = currentURL != url || self.previewLoopDuration != previewLoopDuration
        currentURL = url
        self.previewLoopDuration = previewLoopDuration
        currentMuted = isMuted
        currentVolume = playbackVolume

        if urlChanged {
            teardownObservers()
            let player = AVPlayer(url: url)
            player.actionAtItemEnd = .pause
            self.player = player
            playerLayer.player = player

            if let previewLoopDuration, previewLoopDuration > 0 {
                attachShortLoopObserver(player: player, duration: previewLoopDuration)
            } else if let item = player.currentItem {
                endObserver = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: item,
                    queue: .main
                ) { [weak player] _ in
                    player?.seek(to: .zero)
                    player?.play()
                }
            }
            player.play()
        }

        applyAudio(muted: isMuted, volume: playbackVolume, fadeDuration: urlChanged ? 0 : volumeFadeDuration)
    }

    private func applyAudio(muted: Bool, volume: Float, fadeDuration: TimeInterval) {
        volumeFadeTask?.cancel()
        volumeFadeTask = nil
        guard let player else { return }
        player.isMuted = muted
        if muted {
            player.volume = 0
            return
        }
        if fadeDuration <= 0 {
            player.volume = volume
            return
        }

        let startVolume = player.volume
        volumeFadeTask = Task { @MainActor [weak player] in
            let steps = max(1, Int(fadeDuration / 0.02))
            let stepDuration = fadeDuration / Double(steps)
            for step in 1...steps {
                guard !Task.isCancelled, let player else { return }
                let t = Float(step) / Float(steps)
                player.volume = startVolume + (volume - startVolume) * t
                try? await Task.sleep(for: .seconds(stepDuration))
            }
            guard !Task.isCancelled, let player else { return }
            player.volume = volume
        }
    }

    private func attachShortLoopObserver(player: AVPlayer, duration: TimeInterval) {
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak player] time in
            guard let player else { return }
            if time.seconds >= duration {
                player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
    }

    private func teardownObservers() {
        volumeFadeTask?.cancel()
        volumeFadeTask = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    deinit {
        teardownObservers()
    }
}
#else
struct LoopingVideoView: View {
    let url: URL
    var previewLoopDuration: TimeInterval? = nil
    var isMuted: Bool = true
    var playbackVolume: Float = 1.0

    var body: some View {
        Color(white: 0.7)
    }
}
#endif

#Preview {
    LoopingVideoView(url: PreviewSupport.sampleVideoURL)
        .frame(width: 200, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 8))
}
