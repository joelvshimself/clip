//
//  UploadPipelineView.swift
//  clip
//

import AVFoundation
import SwiftUI

struct UploadPipelineView: View {
    let videoURL: URL
    var onContinueEditing: () -> Void
    var onSave: () -> Void

    @State private var stage: UploadPipelineStage = .loading
    @State private var exportSoundPlayer: AVAudioPlayer?

    var body: some View {
        ZStack {
            switch stage {
            case .loading:
                UploadLoadingStageView(videoURL: videoURL)
                    .transition(.opacity)
            case .exporting:
                UploadExportingStageView()
                    .transition(.opacity)
            case .complete:
                UploadCompleteStageView(
                    videoURL: videoURL,
                    onContinueEditing: onContinueEditing,
                    onSave: onSave
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: stage)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            runStageAutomation()
        }
        .onChange(of: stage) { _, newStage in
            if newStage == .exporting {
                playExportMemeSound()
            }
        }
    }

    private func runStageAutomation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + UploadPipelineTiming.loadingDuration) {
            guard stage == .loading else { return }
            stage = .exporting
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + UploadPipelineTiming.loadingDuration + UploadPipelineTiming.exportingDuration
        ) {
            guard stage == .exporting else { return }
            stage = .complete
        }
    }

    private func playExportMemeSound() {
        guard let url = Bundle.main.url(forResource: "meme_export", withExtension: "mp3")
            ?? Bundle.main.url(forResource: "meme_export", withExtension: "m4a")
        else { return }
        exportSoundPlayer = try? AVAudioPlayer(contentsOf: url)
        exportSoundPlayer?.play()
    }
}

// MARK: - Stage 1: Loading

private struct UploadLoadingStageView: View {
    let videoURL: URL

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            MagicBeginningHeroView(videoURL: videoURL)
                .padding(.horizontal, 16)

            Spacer(minLength: 24)
        }
    }
}

// MARK: - Stage 2: Exporting

private struct UploadExportingStageView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
        ZStack {
            Color.black.ignoresSafeArea()

            HStack(alignment: .center, spacing: 0) {
                Image("Cat")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(200, geometry.size.width * 0.42))
                    .scaleEffect(x: -1, y: 1)
                    .padding(.leading, 8)

                Spacer(minLength: 0)

                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        CricketBallView()
                            .frame(width: ballSize(for: index), height: ballSize(for: index))
                            .offset(ballOffset(for: index, active: animate))
                            .opacity(animate ? 1 : 0.35)
                    }
                }
                .frame(width: 160, height: 220)
                .padding(.trailing, 24)
            }
        }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }

    private func ballSize(for index: Int) -> CGFloat {
        [44, 62, 82][index]
    }

    private func ballOffset(for index: Int, active: Bool) -> CGSize {
        let baseY = CGFloat(index) * 52 + 20
        let travel: CGFloat = active ? 28 : 0
        return CGSize(width: CGFloat(index) * 18 + travel, height: baseY + travel * 0.6)
    }
}

private struct CricketBallView: View {
    var body: some View {
        Circle()
            .fill(Color.white)
            .overlay {
                Capsule()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 6, height: 44)
                    .rotationEffect(.degrees(32))
                Capsule()
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [3, 4]))
                    .foregroundStyle(Color.black.opacity(0.5))
                    .frame(width: 28, height: 52)
                    .rotationEffect(.degrees(32))
            }
    }
}

// MARK: - Stage 3: Complete

private struct UploadCompleteStageView: View {
    let videoURL: URL
    var onContinueEditing: () -> Void
    var onSave: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("HEre you are, Darling")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.top, 56)
                .padding(.horizontal, 24)

            Spacer()

            ZStack {
                ForEach(0..<4, id: \.self) { layer in
                    let depth = 3 - layer
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(white: 0.35 + Double(depth) * 0.12))
                        .aspectRatio(0.72, contentMode: .fit)
                        .scaleEffect(1 - CGFloat(depth) * 0.04)
                        .offset(x: CGFloat(depth) * 10, y: CGFloat(depth) * 8)
                        .opacity(layer == 0 ? 1 : 0.55)
                        .overlay {
                            if layer == 0 {
                                LoopingVideoView(url: videoURL)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            } else {
                                Text("{video}")
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(.black.opacity(0.5))
                            }
                        }
                }
            }
            .padding(.horizontal, 48)

            Spacer()

            HStack(spacing: 16) {
                Button(action: onContinueEditing) {
                    Text("Continue editing")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.white.opacity(0.85), lineWidth: 2)
                        }
                }
                .buttonStyle(.plain)

                Button(action: onSave) {
                    Text("Save")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(white: 0.72), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview("Upload Pipeline") {
    UploadPipelineView(
        videoURL: PreviewSupport.sampleVideoURL,
        onContinueEditing: {},
        onSave: {}
    )
}

#Preview("Stage Loading") {
    UploadLoadingStageView(videoURL: PreviewSupport.sampleVideoURL)
        .background(Color.black)
}

#Preview("Stage Exporting") {
    UploadExportingStageView()
}

#Preview("Cricket Ball") {
    CricketBallView()
        .frame(width: 64, height: 64)
        .padding()
        .background(Color.black)
}

#Preview("Stage Complete") {
    UploadCompleteStageView(
        videoURL: PreviewSupport.sampleVideoURL,
        onContinueEditing: {},
        onSave: {}
    )
}
