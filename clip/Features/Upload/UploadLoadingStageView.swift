//
//  UploadLoadingStageView.swift
//  clip
//

import SwiftUI

struct UploadLoadingStageView: View {
    let videoURL: URL?

    @State private var anchor: LoadingCatAnchor = .top
    @State private var topVariantIndex = 0
    @State private var tickOpacity = 1.0

    private let tickInterval: TimeInterval = 1.0

    var body: some View {
        GeometryReader { geometry in
            LoadingCatPlacementContent(
                containerWidth: geometry.size.width,
                videoURL: videoURL,
                anchor: anchor,
                topVariantIndex: topVariantIndex,
                catOpacity: tickOpacity
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

            withAnimation(.easeInOut(duration: 0.15)) {
                tickOpacity = 0.35
            }

            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }

            let next = anchor.next()
            if next == .top {
                topVariantIndex = (topVariantIndex + 1) % LoadingCatPose.topVariantCount
            }
            anchor = next

            withAnimation(.easeInOut(duration: 0.15)) {
                tickOpacity = 1
            }
        }
    }
}

#Preview("Stage Loading") {
    UploadLoadingStageView(videoURL: PreviewSupport.sampleVideoURL)
        .background(Color.black)
}
