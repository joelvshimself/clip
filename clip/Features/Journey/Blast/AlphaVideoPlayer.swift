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

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    final class Coordinator: NSObject {
        var onFinished: (() -> Void)?
        private var endObserver: NSObjectProtocol?

        init(onFinished: (() -> Void)?) {
            self.onFinished = onFinished
        }

        func observeEnd(of item: AVPlayerItem, player: AVPlayer) {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.onFinished?()
            }
            player.play()
        }

        deinit {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }
    }

    final class PlayerUIView: UIView {
        private let playerLayer = AVPlayerLayer()

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
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            player.actionAtItemEnd = .pause
            playerLayer.player = player
            coordinator.observeEnd(of: item, player: player)
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
