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
    @State private var didReportSettled = false
    @State private var didPlayHandSting = false

    var body: some View {
        ZStack {
            Color.black

            if !sequenceFinished, flashIndex < ManifestoTiming.flashes.count {
                let entry = ManifestoTiming.flashes[flashIndex]
                ManifestoWordFlashView(
                    word: entry.text,
                    isRedBackground: entry.isRedBackground,
                    showsSilhouette: entry.showsSilhouette
                )
                .id(flashIndex)
            }
        }
        .frame(width: containerSize.width, height: containerSize.height)
        .ignoresSafeArea()
        .animation(nil, value: flashIndex)
        .animation(nil, value: sequenceFinished)
        .onAppear {
            beginFlashSequence()
        }
    }

    private func beginFlashSequence() {
        flashIndex = 0
        sequenceFinished = false
        didReportSettled = false
        didPlayHandSting = false
        onFlashAppeared(at: 0)
        scheduleAdvance(from: 0)
    }

    private func onFlashAppeared(at index: Int) {
        guard index < ManifestoTiming.flashes.count else { return }
        let entry = ManifestoTiming.flashes[index]
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
                reportSettledOnce()
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
