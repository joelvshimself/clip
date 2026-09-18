//
//  UploadExportingStageView.swift
//  clip
//

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

    @State private var catPixelAmount: Double = 0
    @State private var showVomitLayers = false
    /// Mouth → center carousel, scale/fan, Felix exit upward.
    @State private var revealProgress: CGFloat = 0
    @State private var sequenceStarted = false

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
            let centerY = screenSize.height * 0.42
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

                if showVomitLayers, let image = previewImage {
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
        .task {
            await runExportBeatIfNeeded()
        }
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
        JourneyAudio.play(.handSting)
    }
}

#Preview("Stage Exporting") {
    UploadExportingStageView(previewImage: PreviewSupport.yellowPortraitMockCGImage())
        .background(Color.black)
}
