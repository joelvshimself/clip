//
//  FallingClipsView.swift
//  clip
//

import SpriteKit
import SwiftUI

struct FallingClipsView: View {
    let size: CGSize
    var onSettled: () -> Void

    @State private var scene: FallingClipsScene?

    var body: some View {
        Group {
            if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .allowsHitTesting(false)
            } else {
                Color.clear
                    .frame(width: size.width, height: size.height)
            }
        }
        .onAppear {
            guard scene == nil else { return }
            DeviceTiltMonitor.shared.start()
            let created = FallingClipsScene(
                size: size,
                clipURLs: FallingClipCatalog.urls,
                playfield: ScreenMockup.playfieldPadding(for: size)
            )
            created.onSettled = onSettled
            scene = created
        }
    }
}
