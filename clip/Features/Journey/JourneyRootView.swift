//
//  JourneyRootView.swift
//  clip
//

import Photos
import SwiftUI

struct JourneyRootView: View {
    @Binding var journeyPhase: JourneyPhase

    @State private var scrollProgress: CGFloat = 0
    @State private var isFullyOpen = false
    @State private var hintBounce = false
    @State private var catLaunched = false
    @State private var journeyStarted = false
    @State private var showFallingClips = false
    @State private var clipsSettled = false
    @State private var showJourneyCTA = false

    private var openAmount: CGFloat {
        isFullyOpen ? 1 : scrollProgress * RevealArt.manualOpenCap
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
            let scrollRange = height * (RevealArt.scrollContentMultiplier - 1)

            ZStack {
                Color.black

                if journeyPhase == .blast, let explosionURL = FallingClipCatalog.explosionURL {
                    AlphaVideoPlayer(url: explosionURL) {
                        journeyPhase = .wait
                        scheduleRain(after: JourneyTiming.waitAfterExplosion)
                    }
                    .frame(width: width, height: height)
                    .clipped()
                    .allowsHitTesting(false)
                }

                if showFallingClips {
                    ScreenStageView(
                        containerSize: CGSize(width: width, height: height),
                        showCTA: shouldShowCTA,
                        onCTA: handleEnterJourney,
                        onSettled: handleClipsSettled
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .zIndex(5)
                    .transition(.opacity)
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

                if !journeyActive {
                    ScrollView {
                        Color.clear
                            .frame(height: height * RevealArt.scrollContentMultiplier)
                    }
                    .scrollIndicators(.hidden)
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y + geometry.contentInsets.top
                    } action: { _, offset in
                        handleScroll(offset: offset, scrollRange: scrollRange)
                    }
                }
            }
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
            } else if phase == .rain || phase == .cta {
                DeviceTiltMonitor.shared.start()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                hintBounce = true
            }
        }
        .onDisappear {
            DeviceTiltMonitor.shared.stop()
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

    private var scrollHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.down")
                .font(.caption.weight(.bold))
                .offset(y: hintBounce ? 5 : -3)

            Text("scroll")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 22)
        .padding(.vertical, 11)
        .glassEffect(.regular, in: .capsule)
        .shadow(color: .black.opacity(0.28), radius: 12, y: 5)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 36)
    }

    private var hintOpacity: Double {
        Double(max(0, 1 - scrollProgress * 2.5))
    }

    private func handleScroll(offset: CGFloat, scrollRange: CGFloat) {
        guard scrollRange > 0, !journeyStarted else { return }

        let rawProgress = min(max(offset / scrollRange, 0), 1)

        if rawProgress >= RevealArt.snapThreshold, !isFullyOpen {
            withAnimation(.easeIn(duration: RevealArt.snapDuration)) {
                isFullyOpen = true
            }
        } else if rawProgress < RevealArt.snapReleaseThreshold, isFullyOpen {
            isFullyOpen = false
        }

        scrollProgress = rawProgress
    }

    private func startJourney() {
        journeyStarted = true
        journeyPhase = .blast
        withAnimation(.easeOut(duration: JourneyTiming.catLaunchDuration)) {
            catLaunched = true
        }
    }

    private func scheduleRain(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard journeyPhase == .wait else { return }
            showFallingClips = true
            journeyPhase = .rain
            scheduleCTABackup()
        }
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
                journeyPhase = .home
            }
        }
        #else
        journeyPhase = .home
        #endif
    }
}
