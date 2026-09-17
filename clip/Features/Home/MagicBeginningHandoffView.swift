//
//  MagicBeginningHandoffView.swift
//  clip
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum MagicHandoffTiming {
    static let totalDuration: TimeInterval = 3.0
    static let maxPreviewWait: TimeInterval = 5.0
    static let magnetDelay: TimeInterval = 0.85
    static let magnetSpringResponse: TimeInterval = 0.82
    static let magnetSpringDamping: CGFloat = 0.74
    static let contactPixelDuration: TimeInterval = 0.22
    static let spinPeriod: TimeInterval = 5.75
    static let bobAmplitude: CGFloat = 12
    static let bobPeriod: TimeInterval = 1.4
}

enum MagicHandoffLayout {
    static let cajaAspect: CGFloat = 1024 / 881
    static let cajaScale: CGFloat = 0.7
    static let cajaVerticalOffset: CGFloat = 28

    /// Portrait frame width:height = 9:16
    static let frameAspectHeightOverWidth: CGFloat = 16 / 9
    static let frameWidthFraction: CGFloat = 0.42
    static let frameStartYFraction: CGFloat = 1.1
    static let frameCenterYFraction: CGFloat = 0.5
    static let frameCenterRightNudge: CGFloat = 12
}

struct MagicBeginningHandoffView: View {
    let previewImage: CGImage?
    var videoURL: URL?
    var onPreviewResolved: (CGImage) -> Void = { _ in }
    var onFinished: () -> Void

    @State private var resolvedPreview: CGImage?
    @State private var magnetProgress: CGFloat = 0
    @State private var framePixelAmount: CGFloat = 0
    @State private var sequenceStarted = false
    @State private var didFinish = false

    private var displayPreview: CGImage? {
        resolvedPreview ?? previewImage
    }

    var body: some View {
        ZStack {
            Image("CatOcaja2")
                .resizable()
                .scaledToFit()
                .scaleEffect(MagicHandoffLayout.cajaScale)
                .offset(y: MagicHandoffLayout.cajaVerticalOffset)

            if let image = displayPreview {
                spinningFrame(previewImage: image)
                    .aspectRatio(MagicHandoffLayout.cajaAspect, contentMode: .fit)
                    .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(MagicHandoffLayout.cajaAspect, contentMode: .fit)
        .task(id: previewTaskID) {
            await resolvePreviewIfNeeded()
        }
        .task {
            await waitForPreviewThenRunBeat()
        }
    }

    private var previewTaskID: String {
        let previewKey = previewImage.map { "\($0.width)x\($0.height)" } ?? "nil"
        let urlKey = videoURL?.absoluteString ?? "nil"
        return "\(previewKey)|\(urlKey)"
    }

    @ViewBuilder
    private func spinningFrame(previewImage: CGImage) -> some View {
        GeometryReader { geometry in
            let heroWidth = geometry.size.width
            let heroHeight = geometry.size.height
            let frameWidth = heroWidth * MagicHandoffLayout.frameWidthFraction
            let frameHeight = frameWidth * MagicHandoffLayout.frameAspectHeightOverWidth

            let start = CGPoint(
                x: heroWidth * 0.5,
                y: heroHeight * MagicHandoffLayout.frameStartYFraction
            )
            let end = CGPoint(
                x: heroWidth * 0.5 + MagicHandoffLayout.frameCenterRightNudge,
                y: heroHeight * MagicHandoffLayout.frameCenterYFraction
            )
            let position = CGPoint(
                x: start.x + (end.x - start.x) * magnetProgress,
                y: start.y + (end.y - start.y) * magnetProgress
            )

            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let bob = sin(t * (2 * .pi / MagicHandoffTiming.bobPeriod)) * MagicHandoffTiming.bobAmplitude
                let spin = (t / MagicHandoffTiming.spinPeriod).truncatingRemainder(dividingBy: 1) * 360
                let idleBob = magnetProgress < 0.02 ? bob : 0
                let spinAmount = magnetProgress < 0.95 ? spin : spin * (1 - magnetProgress)

                frameContent(previewImage: previewImage, width: frameWidth, height: frameHeight)
                    .rotation3DEffect(.degrees(spinAmount), axis: (x: 0, y: 1, z: 0), perspective: 0.65)
                    .layerEffect(
                        LoadingCatPixelation.shader(amount: framePixelAmount),
                        maxSampleOffset: LoadingCatPixelation.maxSampleOffset
                    )
                    .position(x: position.x, y: position.y + idleBob)
            }
        }
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
                onPreviewResolved(previewImage)
            }
            return
        }
        guard resolvedPreview == nil, let videoURL else { return }
        if let frame = await UploadVideoFirstFrameLoader.load(from: videoURL) {
            resolvedPreview = frame
            onPreviewResolved(frame)
        }
    }

    @MainActor
    private func waitForPreviewThenRunBeat() async {
        guard !didFinish else { return }

        let waitStart = Date()
        while displayPreview == nil {
            if Date().timeIntervalSince(waitStart) >= MagicHandoffTiming.maxPreviewWait {
                break
            }
            try? await Task.sleep(for: .seconds(0.05))
        }

        guard !sequenceStarted else { return }
        sequenceStarted = true
        await runHandoffBeat()
    }

    @MainActor
    private func runHandoffBeat() async {
        guard !didFinish else { return }

        try? await Task.sleep(for: .seconds(MagicHandoffTiming.magnetDelay))

        withAnimation(
            .spring(
                response: MagicHandoffTiming.magnetSpringResponse,
                dampingFraction: MagicHandoffTiming.magnetSpringDamping
            )
        ) {
            magnetProgress = 1
        }

        let magnetAnim = MagicHandoffTiming.magnetSpringResponse + 0.15
        try? await Task.sleep(for: .seconds(magnetAnim))

        withAnimation(.easeOut(duration: MagicHandoffTiming.contactPixelDuration)) {
            framePixelAmount = 1
        }
        try? await Task.sleep(for: .seconds(MagicHandoffTiming.contactPixelDuration))
        withAnimation(.easeIn(duration: MagicHandoffTiming.contactPixelDuration * 0.85)) {
            framePixelAmount = 0
        }

        let elapsed = MagicHandoffTiming.magnetDelay + magnetAnim + MagicHandoffTiming.contactPixelDuration * 2
        let remaining = max(0, MagicHandoffTiming.totalDuration - elapsed)
        try? await Task.sleep(for: .seconds(remaining))

        finishOnce()
    }

    private func finishOnce() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }
}

#Preview {
    MagicBeginningHandoffView(previewImage: nil, videoURL: nil, onFinished: {})
        .padding()
        .background(Color.black)
}
