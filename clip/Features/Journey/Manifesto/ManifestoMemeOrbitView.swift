//
//  ManifestoMemeOrbitView.swift
//  clip
//

import SwiftUI

private enum MemeOrbitPhase: Equatable {
    case solo
    case formingRing
    case holding
    case morphing
    case finished
}

struct ManifestoMemeOrbitView: View {
    let containerSize: CGSize
    var onSettled: () -> Void

    @State private var phase: MemeOrbitPhase = .solo
    @State private var soloIndex = 0
    @State private var ringProgress: CGFloat = 0
    @State private var ringRotation: Double = 0
    @State private var ringBlur: CGFloat = 0
    @State private var ringExpansion: CGFloat = 0
    @State private var showCat = false
    @State private var catPixelAmount = 0.0
    @State private var catShowsThnx = false
    @State private var didReportSettled = false

    private let clipURLs: [URL]
    private let rotationJitter: [Double]

    init(containerSize: CGSize, onSettled: @escaping () -> Void) {
        self.containerSize = containerSize
        self.onSettled = onSettled
        let all = FallingClipCatalog.urls
        let count = ManifestoTiming.memeOrbitClipCount
        self.clipURLs = Array(all.prefix(count))
        self.rotationJitter = (0..<count).map { i in
            Double(i) * 0.17 + (i % 2 == 0 ? -0.08 : 0.11)
        }
    }

    var body: some View {
        let layout = MemeOrbitLayout(size: containerSize, ringExpansion: ringExpansion)

        ZStack {
            Color.black

            ZStack {
                ForEach(Array(clipURLs.enumerated()), id: \.offset) { index, url in
                    clipCard(
                        url: url,
                        index: index,
                        layout: layout
                    )
                }
            }
            .rotationEffect(.degrees(ringRotation))
            .blur(radius: ringBlur)

            if showCat {
                catView(layout: layout)
            }
        }
        .frame(width: containerSize.width, height: containerSize.height)
        .clipped()
        .task {
            await runSequence()
        }
    }

    @ViewBuilder
    private func clipCard(url: URL, index: Int, layout: MemeOrbitLayout) -> some View {
        let cardSize = cardSize(for: index, layout: layout)
        let position = cardPosition(for: index, layout: layout)
        let opacity = cardOpacity(for: index)
        let rotation = cardRotation(for: index)

        MemeClipCard(
            url: url,
            size: cardSize,
            cornerRadius: layout.cornerRadius,
            isAudible: phase == .solo && index == soloIndex
        )
            .blur(radius: peekBlur(for: index))
            .rotationEffect(.degrees(rotation))
            .position(position)
            .opacity(opacity)
            .zIndex(index == soloIndex ? 2 : (peekBlur(for: index) > 0 ? 1 : 0))
            .animation(
                phase == .solo ? .easeOut(duration: ManifestoTiming.memeSoloFadeDuration) : nil,
                value: soloIndex
            )
    }

    private func catView(layout: MemeOrbitLayout) -> some View {
        let name = catShowsThnx ? "CatWithTuxedoThnx" : "CatWithTuxedo"
        return Image(name)
            .resizable()
            .scaledToFit()
            .frame(height: layout.catHeight)
            .layerEffect(
                LoadingCatPixelation.shader(amount: catPixelAmount),
                maxSampleOffset: LoadingCatPixelation.maxSampleOffset
            )
            .offset(x: catShowsThnx ? ManifestoTiming.catThnxHorizontalNudge : 0)
            .position(x: layout.center.x, y: layout.center.y)
    }

    private func cardSize(for index: Int, layout: MemeOrbitLayout) -> CGSize {
        switch phase {
        case .solo:
            if index == soloIndex {
                return layout.soloCardSize
            }
            if index == soloPeekIndex(offset: -1) || index == soloPeekIndex(offset: 1) {
                return layout.peekCardSize
            }
            return layout.soloCardSize
        case .formingRing, .holding, .morphing, .finished:
            let t = easedRingProgress(ringProgress)
            let w = layout.soloCardSize.width + (layout.ringCardSize.width - layout.soloCardSize.width) * t
            let h = layout.soloCardSize.height + (layout.ringCardSize.height - layout.soloCardSize.height) * t
            return CGSize(width: w, height: h)
        }
    }

    private func cardPosition(for index: Int, layout: MemeOrbitLayout) -> CGPoint {
        switch phase {
        case .solo:
            if index == soloIndex {
                return layout.center
            }
            if index == soloPeekIndex(offset: -1) {
                return CGPoint(
                    x: layout.center.x - layout.peekOffset,
                    y: layout.center.y
                )
            }
            if index == soloPeekIndex(offset: 1) {
                return CGPoint(
                    x: layout.center.x + layout.peekOffset,
                    y: layout.center.y
                )
            }
            return layout.center
        case .formingRing, .holding, .morphing, .finished:
            let t = easedRingProgress(ringProgress)
            let ringPoint = layout.ringPosition(
                index: index,
                count: clipURLs.count,
                jitter: rotationJitter[index]
            )
            return CGPoint(
                x: layout.center.x + (ringPoint.x - layout.center.x) * t,
                y: layout.center.y + (ringPoint.y - layout.center.y) * t
            )
        }
    }

    private func cardOpacity(for index: Int) -> Double {
        switch phase {
        case .solo:
            if index == soloIndex { return 1 }
            if index == soloPeekIndex(offset: -1) || index == soloPeekIndex(offset: 1) {
                return 0.35
            }
            return 0
        case .formingRing, .holding, .morphing, .finished:
            return 1
        }
    }

    private func peekBlur(for index: Int) -> CGFloat {
        guard phase == .solo else { return 0 }
        if index == soloPeekIndex(offset: -1) || index == soloPeekIndex(offset: 1) {
            return 14
        }
        return 0
    }

    private func cardRotation(for index: Int) -> Double {
        switch phase {
        case .solo:
            return 0
        case .formingRing, .holding, .morphing, .finished:
            let t = easedRingProgress(ringProgress)
            return rotationJitter[index] * t * 180 / .pi
        }
    }

    private func soloPeekIndex(offset: Int) -> Int? {
        guard !clipURLs.isEmpty else { return nil }
        let count = clipURLs.count
        let value = (soloIndex + offset + count * 4) % count
        return value
    }

    private func easedRingProgress(_ progress: CGFloat) -> CGFloat {
        let t = min(max(progress, 0), 1)
        return 1 - pow(1 - t, 3)
    }

    @MainActor
    private func runSequence() async {
        guard !clipURLs.isEmpty else {
            reportSettledOnce()
            return
        }

        phase = .solo
        soloIndex = 0
        ringProgress = 0
        ringRotation = 0
        ringBlur = 0
        ringExpansion = 0
        showCat = false
        catPixelAmount = 0
        catShowsThnx = false

        for index in 0..<clipURLs.count {
            soloIndex = index
            JourneyAudio.play(.memeStep)
            try? await Task.sleep(for: .seconds(ManifestoTiming.memeSoloClipDuration))
            guard !Task.isCancelled else { return }
        }

        phase = .formingRing
        showCat = true
        catPixelAmount = 1
        JourneyAudio.play(.ringSwell)
        JourneyAudio.play(.catResolve)

        withAnimation(.easeOut(duration: ManifestoTiming.memeRingFormDuration)) {
            ringProgress = 1
        }

        withAnimation(.easeOut(duration: ManifestoTiming.memeCatPixelResolveDuration)) {
            catPixelAmount = 0
        }

        try? await Task.sleep(for: .seconds(ManifestoTiming.memeRingFormDuration))
        guard !Task.isCancelled else { return }

        phase = .holding
        try? await Task.sleep(for: .seconds(ManifestoTiming.memeCatHoldBeforeMorph))
        guard !Task.isCancelled else { return }

        phase = .morphing
        startRingSpinAndBlur()
        JourneyAudio.play(.morph)

        withAnimation(.easeIn(duration: ManifestoTiming.memeCatMorphPixelIn)) {
            catPixelAmount = 1
        }
        try? await Task.sleep(for: .seconds(ManifestoTiming.memeCatMorphPixelIn))
        guard !Task.isCancelled else { return }

        catShowsThnx = true

        withAnimation(.easeOut(duration: ManifestoTiming.memeCatMorphPixelOut)) {
            catPixelAmount = 0
        }
        try? await Task.sleep(for: .seconds(ManifestoTiming.memeCatMorphPixelOut))
        guard !Task.isCancelled else { return }

        phase = .finished
        reportSettledOnce()
    }

    private func startRingSpinAndBlur() {
        JourneyAudio.playLooping(.ringSpin)
        withAnimation(.linear(duration: ManifestoTiming.memeRingSpinPeriod).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        withAnimation(.easeInOut(duration: ManifestoTiming.memeCatMorphPixelIn + ManifestoTiming.memeCatMorphPixelOut)) {
            ringBlur = 11
            ringExpansion = 1
        }
    }

    private func reportSettledOnce() {
        guard !didReportSettled else { return }
        didReportSettled = true
        onSettled()
    }
}

private struct MemeClipCard: View {
    let url: URL
    let size: CGSize
    var cornerRadius: CGFloat
    var isAudible: Bool = false

    var body: some View {
        LoopingVideoView(
            url: url,
            isMuted: !isAudible,
            playbackVolume: ManifestoTiming.memeSoloVideoVolume,
            volumeFadeDuration: ManifestoTiming.memeSoloAudioFadeDuration
        )
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct MemeOrbitLayout {
    let size: CGSize
    var ringExpansion: CGFloat = 0

    var center: CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2)
    }

    var shortSide: CGFloat {
        min(size.width, size.height)
    }

    var soloCardSize: CGSize {
        let width = size.width * 0.72
        let height = width * 0.625
        return CGSize(width: width, height: height)
    }

    var peekCardSize: CGSize {
        let width = soloCardSize.width * 0.55
        return CGSize(width: width, height: width * 0.625)
    }

    var peekOffset: CGFloat {
        size.width * 0.38
    }

    var ringCardSize: CGSize {
        let width = size.width * 0.24
        return CGSize(width: width, height: width * 0.72)
    }

    var ringRadiusX: CGFloat {
        shortSide * (ManifestoTiming.memeRingRadiusXFraction + ringExpansion * ManifestoTiming.memeRingMorphRadiusBoost)
    }

    var ringRadiusY: CGFloat {
        shortSide * (ManifestoTiming.memeRingRadiusYFraction + ringExpansion * ManifestoTiming.memeRingMorphRadiusBoost)
    }

    var catHeight: CGFloat {
        shortSide * 0.45
    }

    var cornerRadius: CGFloat {
        18
    }

    func ringPosition(index: Int, count: Int, jitter: Double) -> CGPoint {
        let step = (2 * Double.pi) / Double(count)
        let angle = -Double.pi / 2 + step * Double(index) + jitter
        return CGPoint(
            x: center.x + CGFloat(cos(angle)) * ringRadiusX,
            y: center.y + CGFloat(sin(angle)) * ringRadiusY
        )
    }
}

#Preview {
    ManifestoMemeOrbitView(
        containerSize: CGSize(width: 390, height: 844),
        onSettled: {}
    )
}
