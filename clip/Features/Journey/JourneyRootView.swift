//
//  JourneyRootView.swift
//  clip
//

import Photos
import SwiftUI

struct JourneyRootView: View {
    @Binding var journeyPhase: JourneyPhase

    @State private var revealProgress: CGFloat = 0
    @State private var pinchAnchor: CGFloat = 1
    @State private var scrollRevealAnchor: CGFloat = 0
    @State private var isFullyOpen = false
    @State private var hintBounce = false
    @State private var catLaunched = false
    @State private var journeyStarted = false
    @State private var clipsSettled = false
    @State private var showJourneyCTA = false

    private var showManifestoFlashes: Bool {
        journeyPhase == .rain || journeyPhase == .cta
    }

    private var openAmount: CGFloat {
        if isFullyOpen { return 1 }
        return min(1, revealProgress * RevealArt.manualOpenCap)
    }

    private var journeyActive: Bool {
        journeyPhase != .idle
    }

    private var shouldShowCTA: Bool {
        showJourneyCTA && (journeyPhase == .rain || journeyPhase == .cta)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let arribaHeight = width * RevealArt.arribaAspect
            let abajoHeight = width * RevealArt.abajoAspect
            ZStack {
                Color.black

                if journeyPhase == .blast, let explosionURL = FallingClipCatalog.explosionURL {
                    AlphaVideoPlayer(url: explosionURL) {
                        startManifestoFlashes()
                    }
                    .id(explosionURL)
                    .frame(width: width, height: height)
                    .clipped()
                    .allowsHitTesting(false)
                }

                if showManifestoFlashes {
                    ZStack {
                        ManifestoFlashFlowView(
                            containerSize: CGSize(width: width, height: height),
                            onSettled: handleClipsSettled
                        )

                        if shouldShowCTA {
                            VStack {
                                Spacer(minLength: 0)
                                JourneyCTAButton(action: handleEnterJourney)
                                    .padding(.horizontal, 36)
                                    .padding(.bottom, 48)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(5)
                }

                if journeyPhase == .idle || journeyPhase == .blast {
                    catView(width: width, height: height)
                }

                if !journeyActive {
                    Image("Arriba")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .offset(y: -openAmount * (arribaHeight + RevealArt.travelPadding))
                        .ignoresSafeArea(edges: .top)

                    Image("Abajo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .offset(y: openAmount * (abajoHeight + RevealArt.travelPadding))
                        .ignoresSafeArea(edges: .bottom)

                    scrollHint
                        .opacity(hintOpacity)
                        .allowsHitTesting(false)
                }

            }
            .contentShape(Rectangle())
            .gesture(openRevealGesture)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.35), value: journeyPhase)
        .animation(.easeInOut(duration: 0.35), value: showJourneyCTA)
        .onChange(of: isFullyOpen) { _, open in
            if open, !journeyStarted {
                startJourney()
            }
        }
        .onChange(of: journeyPhase) { _, phase in
            if phase == .home || phase == .idle {
                DeviceTiltMonitor.shared.stop()
                JourneyAudio.stopAll()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                hintBounce = true
            }
        }
        .onDisappear {
            DeviceTiltMonitor.shared.stop()
            JourneyAudio.stopAll()
        }
    }

    @ViewBuilder
    private func catView(width: CGFloat, height: CGFloat) -> some View {
        Image("Cat")
            .resizable()
            .scaledToFit()
            .frame(
                maxWidth: width * 0.88,
                maxHeight: height * 0.78
            )
            .offset(y: catLaunched ? -height * 1.35 : 0)
            .scaleEffect(catLaunched ? 0.72 : 1)
            .opacity(catLaunched ? 0 : 1)
            .allowsHitTesting(false)
    }

    private var openRevealGesture: some Gesture {
        pinchOpenGesture.simultaneously(with: scrollOpenGesture)
    }

    private var pinchOpenGesture: some Gesture {
        MagnificationGesture()
            .onChanged { magnification in
                guard !journeyActive else { return }
                let scale = pinchAnchor * magnification
                let rawProgress = progress(fromPinchScale: clampedPinchScale(scale))
                handleRevealProgress(rawProgress, ended: false)
            }
            .onEnded { magnification in
                guard !journeyActive else { return }
                pinchAnchor = clampedPinchScale(pinchAnchor * magnification)
                let rawProgress = progress(fromPinchScale: pinchAnchor)
                handleRevealProgress(rawProgress, ended: true)
            }
    }

    private var scrollOpenGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard !journeyActive else { return }
                let rawProgress = progress(fromScrollTranslation: value.translation.height)
                handleRevealProgress(rawProgress, ended: false)
            }
            .onEnded { value in
                guard !journeyActive else { return }
                let rawProgress = progress(fromScrollTranslation: value.translation.height)
                handleRevealProgress(rawProgress, ended: true)
            }
    }

    private var scrollHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.pinch.fill")
                .font(.subheadline.weight(.semibold))
                .scaleEffect(hintBounce ? 1.12 : 0.92)

            Text("pinch to open")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
        .padding(.horizontal, 22)
        .padding(.vertical, 11)
        .instructionGlassCapsule()
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 36)
    }

    private var hintOpacity: Double {
        Double(max(0, 1 - revealProgress * 2.5))
    }

    private func clampedPinchScale(_ scale: CGFloat) -> CGFloat {
        let minScale = RevealArt.pinchBaseline
        let maxScale = RevealArt.pinchBaseline + RevealArt.pinchFullSpan
        return min(max(scale, minScale), maxScale)
    }

    private func progress(fromPinchScale scale: CGFloat) -> CGFloat {
        let raw = (scale - RevealArt.pinchBaseline) / RevealArt.pinchFullSpan
        return min(max(raw, 0), 1)
    }

    private func progress(fromScrollTranslation translationY: CGFloat) -> CGFloat {
        let raw = scrollRevealAnchor - translationY / RevealArt.scrollDistanceForFullOpen
        return min(max(raw, 0), 1)
    }

    private func handleRevealProgress(_ rawProgress: CGFloat, ended: Bool) {
        guard !journeyStarted, !isFullyOpen else { return }

        let progress = min(max(rawProgress, 0), 1)

        if ended {
            scrollRevealAnchor = progress
            pinchAnchor = RevealArt.pinchBaseline + progress * RevealArt.pinchFullSpan
            if progress >= RevealArt.snapThreshold {
                prewarmExplosionIfNeeded()
                commitFullOpen()
            } else {
                withAnimation(.easeOut(duration: RevealArt.pinchFollowDuration)) {
                    revealProgress = progress
                }
            }
            return
        }

        if progress >= RevealArt.explosionPrewarmProgress {
            prewarmExplosionIfNeeded()
        }

        withAnimation(.easeOut(duration: RevealArt.pinchFollowDuration)) {
            revealProgress = progress
        }
    }

    private func prewarmExplosionIfNeeded() {
        guard !journeyStarted, let url = FallingClipCatalog.explosionURL else { return }
        ExplosionPlaybackCache.prewarm(url: url)
    }

    private func commitFullOpen() {
        startJourney()
        JourneyAudio.prepareSession()
        JourneyAudio.play(.curtainSnap)
        pinchAnchor = RevealArt.pinchBaseline + RevealArt.pinchFullSpan
        scrollRevealAnchor = 1
        withAnimation(.easeIn(duration: RevealArt.snapDuration)) {
            revealProgress = RevealArt.revealProgressForFullOpen
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + RevealArt.snapDuration) {
            isFullyOpen = true
        }
    }

    private func startJourney() {
        JourneyAudio.prepareSession()
        journeyStarted = true
        journeyPhase = .blast
        JourneyAudio.play(.explosion)
        withAnimation(.easeOut(duration: JourneyTiming.catLaunchDuration)) {
            catLaunched = true
        }
    }

    private func startManifestoFlashes() {
        journeyPhase = .rain
        scheduleCTABackup()
    }

    private func scheduleCTABackup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + JourneyTiming.ctaBackupDelay) {
            guard journeyPhase == .rain || journeyPhase == .cta else { return }
            revealCTA()
        }
    }

    private func handleClipsSettled() {
        guard !clipsSettled else { return }
        clipsSettled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + JourneyTiming.waitAfterSettled) {
            guard journeyPhase == .rain || journeyPhase == .cta else { return }
            revealCTA()
        }
    }

    private func revealCTA() {
        if !showJourneyCTA {
            JourneyAudio.play(.ctaResolve)
        }
        showJourneyCTA = true
        if journeyPhase == .rain {
            journeyPhase = .cta
        }
    }

    private func handleEnterJourney() {
        #if os(iOS)
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
            DispatchQueue.main.async {
                DeviceTiltMonitor.shared.stop()
                JourneyAudio.stopAll()
                journeyPhase = .home
            }
        }
        #else
        JourneyAudio.stopAll()
        journeyPhase = .home
        #endif
    }
}

#Preview("Journey Reveal") {
    @Previewable @State var phase: JourneyPhase = .idle
    JourneyRootView(journeyPhase: $phase)
}
