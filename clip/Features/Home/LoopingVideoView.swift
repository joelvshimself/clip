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

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        LoopingPlayerUIView(url: url, previewLoopDuration: previewLoopDuration)
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        uiView.configure(url: url, previewLoopDuration: previewLoopDuration)
    }
}

final class LoopingPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var timeObserver: Any?
    private var previewLoopDuration: TimeInterval?
    private var currentURL: URL?

    init(url: URL, previewLoopDuration: TimeInterval?) {
        super.init(frame: .zero)
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        configure(url: url, previewLoopDuration: previewLoopDuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(url: URL, previewLoopDuration: TimeInterval?) {
        guard currentURL != url || self.previewLoopDuration != previewLoopDuration else { return }
        currentURL = url
        self.previewLoopDuration = previewLoopDuration
        teardownObservers()

        let player = AVPlayer(url: url)
        player.isMuted = true
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
