//
//  UploadLoadingStageView.swift
//  clip
//

import SwiftUI

struct UploadLoadingStageView: View {
    var previewImage: CGImage?

    @State private var anchor: LoadingCatAnchor = .top
    @State private var topVariantIndex = 0
    @State private var catPixelAmount = 0.0

    private let tickInterval: TimeInterval = 1.0
    private let pixelInDuration: TimeInterval = 0.14
    private let pixelHoldDuration: TimeInterval = 0.04
    private let pixelOutDuration: TimeInterval = 0.14

    var body: some View {
        GeometryReader { geometry in
            LoadingCatPlacementContent(
                containerWidth: geometry.size.width,
                previewImage: previewImage,
                anchor: anchor,
                topVariantIndex: topVariantIndex,
                catPixelAmount: catPixelAmount
            )
        }
        .task {
            await runPositionCycle()
        }
    }

    @MainActor
    private func runPositionCycle() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(tickInterval))
            guard !Task.isCancelled else { return }

            JourneyAudio.play(.morph)
            withAnimation(.easeIn(duration: pixelInDuration)) {
                catPixelAmount = 1
            }

            try? await Task.sleep(for: .seconds(pixelInDuration + pixelHoldDuration))
            guard !Task.isCancelled else { return }

            let next = anchor.next()
            if next == .top {
                topVariantIndex = (topVariantIndex + 1) % LoadingCatPose.topVariantCount
            }
            anchor = next

            withAnimation(.easeOut(duration: pixelOutDuration)) {
                catPixelAmount = 0
            }
        }
    }
}

#Preview("Stage Loading") {
    UploadLoadingStageView(previewImage: nil)
        .background(Color.black)
}
