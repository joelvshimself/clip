//
//  MagicBeginningHeroView.swift
//  clip
//

import SwiftUI

struct MagicBeginningHeroView: View {
    var videoURL: URL?
    var animateEyes: Bool = true

    @State private var lookController = CatEyeLookController()

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = width / MagicBeginningLayout.aspect
            let size = CGSize(width: width, height: height)
            let screen = MagicBeginningLayout.screenRect(in: size)

            ZStack(alignment: .topLeading) {
                MagicBeginningCatFaceView(
                    width: width,
                    animateEyes: false,
                    lookController: lookController
                )

                if let videoURL {
                    LoopingVideoView(url: videoURL)
                        .frame(width: screen.width, height: screen.height)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: MagicBeginningLayout.screenCornerRadius,
                                style: .continuous
                            )
                        )
                        .position(x: screen.midX, y: screen.midY)
                }
            }
            .frame(width: width, height: height)
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(MagicBeginningLayout.aspect, contentMode: .fit)
        .onAppear {
            if animateEyes {
                lookController.startIdleLook()
            }
        }
        .onDisappear {
            lookController.stopIdleLook()
        }
    }
}

#Preview("Magic Beginning") {
    MagicBeginningHeroView()
        .padding()
        .background(Color.black)
}

#Preview("Magic Beginning + Video") {
    MagicBeginningHeroView(videoURL: PreviewSupport.sampleVideoURL)
        .padding()
        .background(Color.black)
}
