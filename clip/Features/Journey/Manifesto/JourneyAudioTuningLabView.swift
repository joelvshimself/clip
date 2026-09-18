//
//  JourneyAudioTuningLabView.swift
//  clip
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

struct JourneyAudioTuningLabView: View {
    @State private var mix = JourneyAudioMix.current

    var body: some View {
        VStack(spacing: 0) {
            controlBar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(white: 0.14))

            List {
                cueRow(
                    title: "Curtain snap",
                    volume: $mix.curtainSnap,
                    play: { JourneyAudio.play(.curtainSnap) }
                )
                explosionVideoRow
                cueRow(
                    title: "Flash rojo",
                    volume: $mix.flashRed,
                    play: { JourneyAudio.play(.flashRed) }
                )
                cueRow(
                    title: "Flash negro",
                    volume: $mix.flashBlack,
                    play: { JourneyAudio.play(.flashBlack) }
                )
                cueRow(
                    title: "Hand sting (power)",
                    volume: $mix.handSting,
                    play: { JourneyAudio.play(.handSting) }
                )
                cueRow(
                    title: "Meme step",
                    volume: $mix.memeStep,
                    play: { JourneyAudio.play(.memeStep) }
                )
                cueRow(
                    title: "Ring swell",
                    volume: $mix.ringSwell,
                    play: { JourneyAudio.play(.ringSwell) }
                )
                cueRow(
                    title: "Cat resolve",
                    volume: $mix.catResolve,
                    play: { JourneyAudio.play(.catResolve) }
                )
                cueRow(
                    title: "Morph",
                    volume: $mix.morph,
                    play: { JourneyAudio.play(.morph) }
                )
                ringSpinRow
                cueRow(
                    title: "CTA resolve",
                    volume: $mix.ctaResolve,
                    play: { JourneyAudio.play(.ctaResolve) }
                )
            }
            .listStyle(.plain)

            snippetPanel
                .padding(16)
                .background(Color(white: 0.12))
        }
        .background(Color.black)
        .onChange(of: mix) { _, newValue in
            JourneyAudioMix.current = newValue
        }
    }

    private var controlBar: some View {
        HStack(spacing: 12) {
            Button("Stop all") {
                JourneyAudio.stopAll()
            }
            .buttonStyle(.borderedProminent)

            Button("Stop loop") {
                JourneyAudio.stopLooping()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .font(.subheadline.weight(.semibold))
    }

    private var explosionVideoRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Explosión (video MOV)")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button("Play WAV") {
                    syncMix()
                    JourneyAudio.play(.explosion)
                }
                .font(.caption.weight(.semibold))
            }
            sliderRow(volume: $mix.explosionVideo)
            Text("AlphaVideoPlayer usa explosionVideo. Play WAV es proxy del boom.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var ringSpinRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Ring spin (loop)")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button("Play loop") {
                    syncMix()
                    JourneyAudio.playLooping(.ringSpin)
                }
                .font(.caption.weight(.semibold))
            }
            sliderRow(volume: $mix.ringSpin)
        }
        .padding(.vertical, 4)
    }

    private func cueRow(
        title: String,
        volume: Binding<Float>,
        play: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button("Play") {
                    syncMix()
                    play()
                }
                .font(.caption.weight(.semibold))
            }
            sliderRow(volume: volume)
        }
        .padding(.vertical, 4)
    }

    private func sliderRow(volume: Binding<Float>) -> some View {
        HStack(spacing: 10) {
            Slider(value: volume, in: 0...1.5, step: 0.01)
            Text(String(format: "%.2f", volume.wrappedValue))
                .font(.caption.monospacedDigit())
                .frame(width: 40, alignment: .trailing)
        }
    }

    private var snippetPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pegar en JourneyAudioMix")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Button("Copy") {
                    copySnippet()
                }
                .font(.caption.weight(.semibold))
            }
            Text(mix.swiftSnippet)
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.75))
                .textSelection(.enabled)
        }
    }

    private func syncMix() {
        JourneyAudioMix.current = mix
    }

    private func copySnippet() {
        #if os(iOS)
        UIPasteboard.general.string = mix.swiftSnippet
        #endif
    }
}

#Preview("Journey audio mix") {
    SoundEffectsPreviewView()
}

#Preview("Journey audio mix (legacy)") {
    JourneyAudioTuningLabView()
}
