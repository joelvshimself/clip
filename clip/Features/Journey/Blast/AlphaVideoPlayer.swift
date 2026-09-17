//
//  AlphaVideoPlayer.swift
//  clip
//

import AVFoundation
import SwiftUI

#if canImport(UIKit)
import UIKit

struct AlphaVideoPlayer: UIViewRepresentable {
    let url: URL
    var onFinished: (() -> Void)?

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.configure(url: url, coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        context.coordinator.onFinished = onFinished
        uiView.configure(url: url, coordinator: context.coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    final class Coordinator: NSObject {
        var onFinished: (() -> Void)?
        private var endObserver: NSObjectProtocol?
        private var statusObserver: NSKeyValueObservation?
        private var didFinish = false

        init(onFinished: (() -> Void)?) {
            self.onFinished = onFinished
        }

        func observeItem(_ item: AVPlayerItem, player: AVPlayer) {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
            statusObserver?.invalidate()
            didFinish = false

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.finishOnce()
            }

            statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                guard let self else { return }
                DispatchQueue.main.async {
                    switch item.status {
                    case .readyToPlay:
                        player.play()
                    case .failed:
                        self.finishOnce()
                    default:
                        break
                    }
                }
            }
        }

        func finishOnce() {
            guard !didFinish else { return }
            didFinish = true
            onFinished?()
        }

        deinit {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
            statusObserver?.invalidate()
        }
    }

    final class PlayerUIView: UIView {
        private let playerLayer = AVPlayerLayer()
        private var currentURL: URL?

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.backgroundColor = UIColor.clear.cgColor
            layer.addSublayer(playerLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }

        func configure(url: URL, coordinator: Coordinator) {
            guard currentURL != url else { return }
            currentURL = url

            JourneyAudio.prepareSession()

            let item = ExplosionPlaybackCache.playerItem(for: url)
            let player = AVPlayer(playerItem: item)
            player.isMuted = false
            player.volume = JourneyAudioMix.current.explosionVideo
            player.actionAtItemEnd = .pause
            player.automaticallyWaitsToMinimizeStalling = false
            playerLayer.player = player
            coordinator.observeItem(item, player: player)
        }
    }
}
#else
struct AlphaVideoPlayer: View {
    let url: URL
    var onFinished: (() -> Void)?

    var body: some View {
        Color.clear
            .onAppear {
                onFinished?()
            }
    }
}
#endif

#Preview("Explosion") {
    Group {
        if let url = PreviewSupport.sampleExplosionURL {
            AlphaVideoPlayer(url: url)
                .frame(width: 320, height: 480)
                .background(Color.black)
        } else {
            Text("explosion.mov not in bundle")
                .foregroundStyle(.white)
                .frame(width: 320, height: 480)
                .background(Color.black)
        }
    }
}
