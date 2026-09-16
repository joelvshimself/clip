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

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        LoopingPlayerUIView(url: url)
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {}
}

final class LoopingPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var observer: NSObjectProtocol?

    init(url: URL) {
        super.init(frame: .zero)
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .pause
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        if let item = player.currentItem {
            observer = NotificationCenter.default.addObserver(
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

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
#else
struct LoopingVideoView: View {
    let url: URL
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
