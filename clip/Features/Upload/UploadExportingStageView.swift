//
//  UploadExportingStageView.swift
//  clip
//

import AVFoundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum UploadExportingTiming {
    static let pixelStartDelay: TimeInterval = 1.5
    static let pixelDuration: TimeInterval = 0.22
    static let revealDuration: TimeInterval = 1.35
    static let visibleCatHeightFraction: CGFloat = 0.5
    static let mouthStartFraction: CGFloat = 0.85
}

enum UploadExportingLayout {
    static let walkingAspectHeightOverWidth: CGFloat = 1
    static let vomitAspectHeightOverWidth: CGFloat = 1369 / 1254
    static let exportCatScale: CGFloat = 2.6
    /// How far Felix travels upward during reveal (fraction of screen height).
    static let felixExitTravelFraction: CGFloat = 0.42
}

struct UploadExportingStageView: View {
    var previewImage: CGImage? = nil
    var videoURL: URL? = nil

    @State private var resolvedPreview: CGImage?
    @State private var catPixelAmount: Double = 0
    @State private var showVomitLayers = false
    /// Mouth → center carousel, scale/fan, Felix exit upward.
    @State private var revealProgress: CGFloat = 0
    @State private var sequenceStarted = false
    @State private var vomitSoundPlayer: AVAudioPlayer?

    private var displayPreview: CGImage? {
        resolvedPreview ?? previewImage
    }

    var body: some View {
        GeometryReader { geometry in
            let screenSize = geometry.size
            let width = screenSize.width
            let scale = UploadExportingLayout.exportCatScale
            let vomitWidth = width * scale
            let vomitHeight = width * UploadExportingLayout.vomitAspectHeightOverWidth * scale
            let walkingWidth = width * scale
            let walkingHeight = width * UploadExportingLayout.walkingAspectHeightOverWidth * scale
            let visibleHeight = (showVomitLayers ? vomitHeight : walkingHeight)
                * UploadExportingTiming.visibleCatHeightFraction
            let felixLift = screenSize.height * UploadExportingLayout.felixExitTravelFraction * revealProgress
            let mouthY = visibleHeight * UploadExportingTiming.mouthStartFraction
            let centerY = screenSize.height * 0.5
            let carouselY = mouthY + (centerY - mouthY) * revealProgress

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    catStack(
                        width: width,
                        walkingWidth: walkingWidth,
                        walkingHeight: walkingHeight,
                        vomitWidth: vomitWidth,
                        vomitHeight: vomitHeight,
                        visibleHeight: visibleHeight,
                        felixLift: felixLift
                    )
                    Spacer(minLength: 0)
                }
                .zIndex(0)

                if showVomitLayers, let image = displayPreview {
                    UploadPreviewCarousel(
                        previewImage: image,
                        progress: revealProgress,
                        maxWidth: width
                    )
                    .position(x: screenSize.width * 0.5, y: carouselY)
                    .zIndex(1)
                }

                if showVomitLayers {
                    scaledTopCatClip(
                        width: width,
                        vomitWidth: vomitWidth,
                        vomitHeight: vomitHeight,
                        visibleHeight: visibleHeight,
                        felixLift: felixLift
                    ) {
                        Image("FelixFut")
                            .resizable()
                            .scaledToFit()
                            .frame(width: vomitWidth, height: vomitHeight)
                            .allowsHitTesting(false)
                    }
                    .zIndex(2)
                }
            }
        }
        .task(id: previewTaskID) {
            await resolvePreviewIfNeeded()
        }
        .task {
            await runExportBeatIfNeeded()
        }
    }

    private var previewTaskID: String {
        let previewKey = previewImage.map { "\($0.width)x\($0.height)" } ?? "nil"
        let urlKey = videoURL?.absoluteString ?? "nil"
        return "\(previewKey)|\(urlKey)"
    }

    @ViewBuilder
    private func catStack(
        width: CGFloat,
        walkingWidth: CGFloat,
        walkingHeight: CGFloat,
        vomitWidth: CGFloat,
        vomitHeight: CGFloat,
        visibleHeight: CGFloat,
        felixLift: CGFloat
    ) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            ZStack(alignment: .bottom) {
                if showVomitLayers {
                    vomitCatLayer(width: vomitWidth, height: vomitHeight)
                } else {
                    Image("FelixWalking")
                        .resizable()
                        .scaledToFit()
                        .frame(width: walkingWidth, height: walkingHeight)
                        .layerEffect(
                            LoadingCatPixelation.shader(amount: catPixelAmount),
                            maxSampleOffset: LoadingCatPixelation.maxSampleOffset
                        )
                }
            }
            .offset(y: -felixLift)

            Spacer(minLength: 0)
        }
        .frame(width: width, height: visibleHeight, alignment: .bottom)
        .clipped()
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func scaledTopCatClip<Content: View>(
        width: CGFloat,
        vomitWidth: CGFloat,
        vomitHeight: CGFloat,
        visibleHeight: CGFloat,
        felixLift: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack(alignment: .bottom) {
                    content()
                }
                .offset(y: -felixLift)
                Spacer(minLength: 0)
            }
            .frame(width: width, height: visibleHeight, alignment: .bottom)
            .clipped()
            .frame(maxWidth: .infinity, alignment: .top)

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func vomitCatLayer(width: CGFloat, height: CGFloat) -> some View {
        Image("FelixGub")
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
            .layerEffect(
                LoadingCatPixelation.shader(amount: catPixelAmount),
                maxSampleOffset: LoadingCatPixelation.maxSampleOffset
            )
    }

    @MainActor
    private func resolvePreviewIfNeeded() async {
        if let previewImage {
            if resolvedPreview == nil {
                resolvedPreview = previewImage
            }
            return
        }
        guard resolvedPreview == nil, let videoURL else { return }
        if let frame = await UploadVideoFirstFrameLoader.load(from: videoURL) {
            resolvedPreview = frame
        }
    }

    @MainActor
    private func runExportBeatIfNeeded() async {
        guard !sequenceStarted else { return }
        sequenceStarted = true

        try? await Task.sleep(for: .seconds(UploadExportingTiming.pixelStartDelay))

        withAnimation(.easeOut(duration: UploadExportingTiming.pixelDuration)) {
            catPixelAmount = 1
        }
        try? await Task.sleep(for: .seconds(UploadExportingTiming.pixelDuration))

        showVomitLayers = true
        playVomitCongratulations()
        withAnimation(.easeIn(duration: UploadExportingTiming.pixelDuration * 0.85)) {
            catPixelAmount = 0
        }
        try? await Task.sleep(for: .seconds(UploadExportingTiming.pixelDuration * 0.85))

        withAnimation(.easeOut(duration: UploadExportingTiming.revealDuration)) {
            revealProgress = 1
        }
    }

    private func playVomitCongratulations() {
        let subdirectories = [
            "Resources/Media",
            "Media",
            nil as String?,
        ]
        var soundURL: URL?
        for subdirectory in subdirectories {
            if let subdirectory {
                soundURL = Bundle.main.url(
                    forResource: "congratulations",
                    withExtension: "wav",
                    subdirectory: subdirectory
                )
            } else {
                soundURL = Bundle.main.url(forResource: "congratulations", withExtension: "wav")
            }
            if soundURL != nil { break }
        }

        if let soundURL {
            vomitSoundPlayer = try? AVAudioPlayer(contentsOf: soundURL)
            vomitSoundPlayer?.play()
            return
        }

        JourneyAudio.play(.ctaResolve)
    }
}

#Preview("Stage Exporting") {
    UploadExportingStageView(previewImage: PreviewSupport.yellowPortraitMockCGImage())
        .background(Color.black)
}
