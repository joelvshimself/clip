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
    /// Hold at keyframe 1 (idle spin + bob) before flying into the caja.
    static let pauseDuration: TimeInterval = 0.85
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
    static let frameWidthFraction: CGFloat = 0.34
    static let frameCenterRightNudge: CGFloat = 12
}

struct MagicHandoffKeyframe {
    var time: TimeInterval
    var xFraction: CGFloat
    var yFraction: CGFloat
    var scale: CGFloat
    /// Extra horizontal offset in points (positive = right).
    var xOffset: CGFloat = 0
    /// Extra vertical offset in points (positive = down).
    var yOffset: CGFloat = 0
}

enum MagicHandoffPath {
    /// Edit these three keyframes to tune the handoff path.
    static let keyframes: [MagicHandoffKeyframe] = [
        // 0: enters from below
        .init(time: 0.00, xFraction: 0.50, yFraction: 1.25, scale: 1),
        // 1: pauses briefly (idle)
        .init(time: 0.55, xFraction: 0.50, yFraction: 1.10, scale: 1),
        // 2: lands in the caja, 200× smaller
        .init(
            time: 1.55,
            xFraction: 0.50,
            yFraction: 0.50,
            scale: 1.0 / 200.0,
            xOffset: 30,
            yOffset: 5
        ),
    ]

    static func pose(
        pathProgress: CGFloat,
        heroWidth: CGFloat,
        heroHeight: CGFloat
    ) -> (position: CGPoint, scale: CGFloat) {
        let clamped = min(max(pathProgress, 0), CGFloat(keyframes.count - 1))
        let segment = min(Int(floor(clamped)), keyframes.count - 2)
        let t = clamped - CGFloat(segment)
        let from = keyframes[segment]
        let to = keyframes[segment + 1]

        let xFraction = from.xFraction + (to.xFraction - from.xFraction) * t
        let yFraction = from.yFraction + (to.yFraction - from.yFraction) * t
        let scale = from.scale + (to.scale - from.scale) * t
        let xOffset = from.xOffset + (to.xOffset - from.xOffset) * t
        let yOffset = from.yOffset + (to.yOffset - from.yOffset) * t

        let nudgeT = segment == 1 ? t : (clamped >= 2 ? 1 : 0)
        let x = heroWidth * xFraction + xOffset + MagicHandoffLayout.frameCenterRightNudge * nudgeT
        let y = heroHeight * yFraction + yOffset

        return (CGPoint(x: x, y: y), scale)
    }

    static func segmentDuration(from startIndex: Int, to endIndex: Int) -> TimeInterval {
        keyframes[endIndex].time - keyframes[startIndex].time
    }
}

struct MagicBeginningHandoffView: View {
    let previewImage: CGImage?
    var onPreviewResolved: (CGImage) -> Void = { _ in }
    var onFinished: () -> Void

    @State private var resolvedPreview: CGImage?
    /// 0 = KF0, 1 = KF1, 2 = KF2 (interpolates between keyframes)
    @State private var pathProgress: CGFloat = 0
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
        previewImage.map { "\($0.width)x\($0.height)" } ?? "nil"
    }

    @ViewBuilder
    private func spinningFrame(previewImage: CGImage) -> some View {
        GeometryReader { geometry in
            let heroWidth = geometry.size.width
            let heroHeight = geometry.size.height
            let frameWidth = heroWidth * MagicHandoffLayout.frameWidthFraction
            let frameHeight = frameWidth * MagicHandoffLayout.frameAspectHeightOverWidth

            let pose = MagicHandoffPath.pose(
                pathProgress: pathProgress,
                heroWidth: heroWidth,
                heroHeight: heroHeight
            )

            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let bob = sin(t * (2 * .pi / MagicHandoffTiming.bobPeriod)) * MagicHandoffTiming.bobAmplitude
                let spin = (t / MagicHandoffTiming.spinPeriod).truncatingRemainder(dividingBy: 1) * 360
                let atPause = abs(pathProgress - 1) < 0.04
                let idleBob = atPause ? bob : 0
                let flyProgress = max(0, min(1, pathProgress - 1))
                let spinAmount = flyProgress < 0.95 ? spin : spin * (1 - flyProgress)

                frameContent(previewImage: previewImage, width: frameWidth, height: frameHeight)
                    .scaleEffect(pose.scale)
                    .rotation3DEffect(.degrees(spinAmount), axis: (x: 0, y: 1, z: 0), perspective: 0.65)
                    .layerEffect(
                        LoadingCatPixelation.shader(amount: framePixelAmount),
                        maxSampleOffset: LoadingCatPixelation.maxSampleOffset
                    )
                    .position(x: pose.position.x, y: pose.position.y + idleBob)
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
        guard let previewImage else { return }
        if resolvedPreview == nil {
            resolvedPreview = previewImage
            onPreviewResolved(previewImage)
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

        let entryDuration = MagicHandoffPath.segmentDuration(from: 0, to: 1)
        withAnimation(.easeInOut(duration: entryDuration)) {
            pathProgress = 1
        }
        try? await Task.sleep(for: .seconds(entryDuration))

        try? await Task.sleep(for: .seconds(MagicHandoffTiming.pauseDuration))

        let flyDuration = MagicHandoffPath.segmentDuration(from: 1, to: 2)
        withAnimation(.easeInOut(duration: flyDuration)) {
            pathProgress = 2
        }
        try? await Task.sleep(for: .seconds(flyDuration))

        withAnimation(.easeOut(duration: MagicHandoffTiming.contactPixelDuration)) {
            framePixelAmount = 1
        }
        try? await Task.sleep(for: .seconds(MagicHandoffTiming.contactPixelDuration))
        withAnimation(.easeIn(duration: MagicHandoffTiming.contactPixelDuration * 0.85)) {
            framePixelAmount = 0
        }

        let elapsed =
            entryDuration
            + MagicHandoffTiming.pauseDuration
            + flyDuration
            + MagicHandoffTiming.contactPixelDuration * 2
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
    MagicBeginningHandoffView(previewImage: nil, onFinished: {})
        .padding()
        .background(Color.black)
}
