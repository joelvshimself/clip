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
    static let vomitTravelDuration: TimeInterval = 1.35
    /// Fraction of full cat image height visible at the top of the screen.
    static let visibleCatHeightFraction: CGFloat = 0.5
    /// Screen Y at mouth (start of vomit travel), as fraction of top clip height.
    static let mouthStartFraction: CGFloat = 0.85
}

enum UploadExportingLayout {
    static let walkingAspectHeightOverWidth: CGFloat = 1
    static let vomitAspectHeightOverWidth: CGFloat = 1369 / 1254
    /// Display scale for FelixWalking, FelixGub, and FelixFut (2× + 30%).
    static let exportCatScale: CGFloat = 2.6
    static let frameWidthFraction: CGFloat = 0.44
    static let frameAspectHeightOverWidth: CGFloat = 16 / 9
}

struct UploadExportingStageView: View {
    var previewImage: CGImage? = nil
    var videoURL: URL? = nil

    @State private var resolvedPreview: CGImage?
    @State private var catPixelAmount: Double = 0
    @State private var showVomitLayers = false
    /// 0 = frame at mouth; 1 = frame at screen center.
    @State private var frameTravel: CGFloat = 0
    @State private var sequenceStarted = false

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
            let frameWidth = width * UploadExportingLayout.frameWidthFraction
            let frameHeight = frameWidth * UploadExportingLayout.frameAspectHeightOverWidth

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    catStack(
                        width: width,
                        walkingWidth: walkingWidth,
                        walkingHeight: walkingHeight,
                        vomitWidth: vomitWidth,
                        vomitHeight: vomitHeight,
                        visibleHeight: visibleHeight
                    )
                    Spacer(minLength: 0)
                }
                .zIndex(0)

                if showVomitLayers, let image = displayPreview {
                    vomitFrameOverlay(
                        previewImage: image,
                        screenSize: screenSize,
                        visibleHeight: visibleHeight,
                        frameWidth: frameWidth,
                        frameHeight: frameHeight
                    )
                    .zIndex(1)
                }

                if showVomitLayers {
                    scaledTopCatClip(
                        width: width,
                        catWidth: vomitWidth,
                        catHeight: vomitHeight,
                        visibleHeight: visibleHeight
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
        visibleHeight: CGFloat
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

            Spacer(minLength: 0)
        }
        .frame(width: width, height: visibleHeight, alignment: .bottom)
        .clipped()
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func scaledTopCatClip<Content: View>(
        width: CGFloat,
        catWidth: CGFloat,
        catHeight: CGFloat,
        visibleHeight: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack(alignment: .bottom) {
                    content()
                }
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

    @ViewBuilder
    private func vomitFrameOverlay(
        previewImage: CGImage,
        screenSize: CGSize,
        visibleHeight: CGFloat,
        frameWidth: CGFloat,
        frameHeight: CGFloat
    ) -> some View {
        let startY = visibleHeight * UploadExportingTiming.mouthStartFraction
        let endY = screenSize.height * 0.5
        let y = startY + (endY - startY) * frameTravel

        frameContent(previewImage: previewImage, width: frameWidth, height: frameHeight)
            .position(x: screenSize.width * 0.5, y: y)
    }

    @ViewBuilder
    private func frameContent(previewImage: CGImage, width: CGFloat, height: CGFloat) -> some View {
        #if canImport(UIKit)
        Image(uiImage: UIImage(cgImage: previewImage))
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.white.opacity(0.55), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.45), radius: 12, y: 6)
        #else
        Color(white: 0.4)
            .frame(width: width, height: height)
        #endif
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
        withAnimation(.easeIn(duration: UploadExportingTiming.pixelDuration * 0.85)) {
            catPixelAmount = 0
        }
        try? await Task.sleep(for: .seconds(UploadExportingTiming.pixelDuration * 0.85))

        withAnimation(.easeOut(duration: UploadExportingTiming.vomitTravelDuration)) {
            frameTravel = 1
        }
    }
}

#Preview("Stage Exporting") {
    UploadExportingStageView(previewImage: PreviewSupport.yellowPortraitMockCGImage())
        .background(Color.black)
}
