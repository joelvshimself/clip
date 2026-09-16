//
//  UploadPipelineView.swift
//  clip
//

import AVFoundation
import SwiftUI

struct UploadPipelineView: View {
    let videoURL: URL?
    var onContinueEditing: () -> Void
    var onSave: () -> Void

    @State private var stage: UploadPipelineStage = .loading
    @State private var exportSoundPlayer: AVAudioPlayer?
    @State private var stageAutomationStarted = false

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
                if let videoURL {
                    UploadCompleteStageView(
                        videoURL: videoURL,
                        onContinueEditing: onContinueEditing,
                        onSave: onSave
                    )
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.45), value: stage)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            startStageAutomationIfNeeded()
        }
        .onChange(of: videoURL) { _, newURL in
            if newURL != nil {
                startStageAutomationIfNeeded()
            }
        }
        .onChange(of: stage) { _, newStage in
            if newStage == .exporting {
                playExportMemeSound()
            }
        }
    }

    private func startStageAutomationIfNeeded() {
        guard videoURL != nil, !stageAutomationStarted else { return }
        stageAutomationStarted = true
        runStageAutomation()
    }

    private func runStageAutomation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + UploadPipelineTiming.loadingDuration) {
            guard stage == .loading, videoURL != nil else { return }
            stage = .exporting
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + UploadPipelineTiming.loadingDuration + UploadPipelineTiming.exportingDuration
        ) {
            guard stage == .exporting, videoURL != nil else { return }
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

#Preview("Upload Pipeline") {
    UploadPipelineView(
        videoURL: PreviewSupport.sampleVideoURL,
        onContinueEditing: {},
        onSave: {}
    )
}

#Preview("Upload Pipeline Preparing") {
    UploadPipelineView(
        videoURL: nil,
        onContinueEditing: {},
        onSave: {}
    )
}
