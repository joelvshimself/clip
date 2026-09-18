//
//  SoundEffectsPreviewView.swift
//  clip
//

import AVFoundation
import SwiftUI

#if os(iOS)
import UIKit
#endif

/// Canvas-style audition lab for every SFX in the app. Does not replace in-flow playback.
struct SoundEffectsPreviewView: View {
    @State private var mix = JourneyAudioMix.current
    @State private var memeExportVolume: Float = 1.0
    @State private var adHocPlayers: [AVAudioPlayer] = []

    var body: some View {
        VStack(spacing: 0) {
            header
            List {
                Section("Journey / onboarding") {
                    effectRow(
                        title: "Curtain snap",
                        file: "curtain_snap.wav",
                        context: "Journey curtains fully open — JourneyRootView.commitFullOpen()",
                        volume: $mix.curtainSnap,
                        play: { JourneyAudio.play(.curtainSnap) }
                    )
                    effectRow(
                        title: "Explosion boom",
                        file: "explosion.wav + explosion.mov audio",
                        context: "Cat blast / reveal — JourneyRootView.startJourney() + AlphaVideoPlayer",
                        volume: $mix.explosionVideo,
                        play: { JourneyAudio.play(.explosion) }
                    )
                    effectRow(
                        title: "Flash red",
                        file: "flash_red.wav",
                        context: "Manifesto red flash cards — ManifestoFlashFlowView",
                        volume: $mix.flashRed,
                        play: { JourneyAudio.play(.flashRed) }
                    )
                    effectRow(
                        title: "Flash black",
                        file: "flash_black.wav",
                        context: "Manifesto black flash cards — ManifestoFlashFlowView",
                        volume: $mix.flashBlack,
                        play: { JourneyAudio.play(.flashBlack) }
                    )
                    effectRow(
                        title: "Hand sting",
                        file: "manifesto_hand_sting.wav",
                        context: "Power silhouette + 0.3s punch after “your” before hand video + vomit reveal — ManifestoFlashFlowView / UploadExportingStageView",
                        volume: $mix.handSting,
                        play: { JourneyAudio.play(.handSting) }
                    )
                    effectRow(
                        title: "Meme step",
                        file: "meme_step.wav",
                        context: "Each meme step in the orbit — ManifestoMemeOrbitView",
                        volume: $mix.memeStep,
                        play: { JourneyAudio.play(.memeStep) }
                    )
                    effectRow(
                        title: "Ring swell",
                        file: "ring_swell.wav",
                        context: "Ring swell before cat resolve — ManifestoMemeOrbitView",
                        volume: $mix.ringSwell,
                        play: { JourneyAudio.play(.ringSwell) }
                    )
                    effectRow(
                        title: "Cat resolve",
                        file: "cat_resolve.wav",
                        context: "Cat resolve beat in meme orbit — ManifestoMemeOrbitView",
                        volume: $mix.catResolve,
                        play: { JourneyAudio.play(.catResolve) }
                    )
                    effectRow(
                        title: "Morph",
                        file: "morph.wav",
                        context: "Meme orbit morph + loading cat pixel-in — ManifestoMemeOrbitView / UploadLoadingStageView",
                        volume: $mix.morph,
                        play: { JourneyAudio.play(.morph) }
                    )
                    effectRow(
                        title: "Ring spin (loop)",
                        file: "ring_spin.wav",
                        context: "Looping ring spin during meme orbit — ManifestoMemeOrbitView.playLooping",
                        volume: $mix.ringSpin,
                        play: { JourneyAudio.playLooping(.ringSpin) },
                        playLabel: "Loop"
                    )
                    effectRow(
                        title: "CTA resolve",
                        file: "cta_resolve.wav",
                        context: "Enter-journey CTA resolve — JourneyRootView.revealCTA()",
                        volume: $mix.ctaResolve,
                        play: { JourneyAudio.play(.ctaResolve) }
                    )
                }

                Section("Upload / export") {
                    effectRow(
                        title: "Meme export",
                        file: "meme_export.mp3 / .m4a",
                        context: "When upload stage becomes exporting — UploadPipelineView.playExportMemeSound()",
                        volume: $memeExportVolume,
                        play: { playBundled(named: "meme_export", extensions: ["mp3", "m4a"], volume: memeExportVolume) }
                    )
                    effectRow(
                        title: "Vomit reveal (hand sting)",
                        file: "manifesto_hand_sting.wav",
                        context: "Cat vomit reveal beat — UploadExportingStageView.playVomitCongratulations()",
                        volume: $mix.handSting,
                        play: { JourneyAudio.play(.handSting) }
                    )
                    effectRow(
                        title: "Loading pixel morph",
                        file: "morph.wav",
                        context: "Each loading pose pixel-in — UploadLoadingStageView.runPositionCycle()",
                        volume: $mix.morph,
                        play: { JourneyAudio.play(.morph) }
                    )
                }
            }
            .listStyle(.insetGrouped)

            footer
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .onChange(of: mix) { _, newValue in
            JourneyAudioMix.current = newValue
        }
        .onDisappear {
            JourneyAudio.stopAll()
            stopAdHoc()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sound effects")
                    .font(.headline.weight(.semibold))
                Text("Preview only — in-flow cues stay wired")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Stop all") {
                JourneyAudio.stopAll()
                stopAdHoc()
            }
            .buttonStyle(.borderedProminent)
            .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(white: 0.14))
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Journey mix snippet")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Button("Copy") {
                    #if os(iOS)
                    UIPasteboard.general.string = mix.swiftSnippet
                    #endif
                }
                .font(.caption.weight(.semibold))
            }
            Text(mix.swiftSnippet)
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.7))
                .textSelection(.enabled)
            Text("Upload preview sliders only affect Play here (not production yet).")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(white: 0.12))
    }

    private func effectRow(
        title: String,
        file: String,
        context: String,
        volume: Binding<Float>,
        play: @escaping () -> Void,
        playLabel: String = "Play"
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button(playLabel) {
                    JourneyAudioMix.current = mix
                    play()
                }
                .font(.caption.weight(.semibold))
            }

            Text(file)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)

            Text(context)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Slider(value: volume, in: 0...1.5, step: 0.01)
                Text(String(format: "%.2f", volume.wrappedValue))
                    .font(.caption.monospacedDigit())
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding(.vertical, 6)
    }

    private func stopAdHoc() {
        for player in adHocPlayers {
            player.stop()
        }
        adHocPlayers.removeAll()
    }

    private func playBundled(
        named name: String,
        extensions: [String],
        subdirectories: [String?] = [nil],
        volume: Float
    ) {
        JourneyAudio.prepareSession()
        stopAdHoc()

        var url: URL?
        for subdirectory in subdirectories {
            for ext in extensions {
                if let subdirectory {
                    url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
                } else {
                    url = Bundle.main.url(forResource: name, withExtension: ext)
                }
                if url != nil { break }
            }
            if url != nil { break }
        }

        guard let url else { return }

        func enqueue(_ volume: Float) {
            guard volume > 0,
                  let player = try? AVAudioPlayer(contentsOf: url)
            else { return }
            player.volume = min(1, volume)
            player.prepareToPlay()
            player.play()
            adHocPlayers.append(player)
        }

        enqueue(min(1, volume))
        if volume > 1 {
            enqueue(min(1, volume - 1))
        }
    }
}

#Preview("Sound effects lab") {
    SoundEffectsPreviewView()
}
