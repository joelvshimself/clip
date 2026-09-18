//
//  ManifestoFlashFlowView.swift
//  clip
//

import SwiftUI

struct ManifestoFlashFlowView: View {
    let containerSize: CGSize
    var onSettled: () -> Void

    @State private var flashIndex = 0
    @State private var sequenceFinished = false
    @State private var showMemeOrbit = false
    @State private var didReportSettled = false
    @State private var didPlayHandSting = false

    var body: some View {
        ZStack {
            Color.black

            if showMemeOrbit {
                ManifestoMemeOrbitView(containerSize: containerSize, onSettled: reportSettledOnce)
            } else if !sequenceFinished, flashIndex < ManifestoTiming.flashes.count {
                let entry = ManifestoTiming.flashes[flashIndex]
                ManifestoWordFlashView(
                    word: entry.text,
                    isRedBackground: entry.isRedBackground,
                    showsSilhouette: entry.showsSilhouette,
                    handVideoURL: entry.showsHandVideo ? ManifestoMedia.glovePoofHitURL : nil
                )
                .id(flashIndex)
            }
        }
        .frame(width: containerSize.width, height: containerSize.height)
        .ignoresSafeArea()
        .animation(nil, value: flashIndex)
        .animation(nil, value: sequenceFinished)
        .animation(nil, value: showMemeOrbit)
        .onAppear {
            beginFlashSequence()
        }
    }

    private func beginFlashSequence() {
        flashIndex = 0
        sequenceFinished = false
        showMemeOrbit = false
        didReportSettled = false
        didPlayHandSting = false
        onFlashAppeared(at: 0)
        scheduleAdvance(from: 0)
    }

    private func onFlashAppeared(at index: Int) {
        guard index < ManifestoTiming.flashes.count else { return }
        let entry = ManifestoTiming.flashes[index]
        JourneyAudio.play(entry.isRedBackground ? .flashRed : .flashBlack)
        if entry.text == "your" {
            DispatchQueue.main.asyncAfter(deadline: .now() + ManifestoTiming.punchAfterYourDelay) {
                let scale = ManifestoTiming.punchAfterYourHandStingScale
                let volume = JourneyAudioMix.current.handSting * scale
                JourneyAudio.play(.handSting, volumeOverride: volume)
            }
        }
        guard entry.showsSilhouette, !didPlayHandSting else { return }
        didPlayHandSting = true
        ManifestoHandSting.play()
    }

    private func scheduleAdvance(from index: Int) {
        let duration = ManifestoTiming.flashes[index].duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            let next = index + 1
            if next >= ManifestoTiming.flashes.count {
                sequenceFinished = true
                showMemeOrbit = true
            } else {
                flashIndex = next
                onFlashAppeared(at: next)
                scheduleAdvance(from: next)
            }
        }
    }

    private func reportSettledOnce() {
        guard !didReportSettled else { return }
        didReportSettled = true
        onSettled()
    }
}

#Preview {
    ManifestoFlashFlowView(containerSize: CGSize(width: 390, height: 844), onSettled: {})
}
