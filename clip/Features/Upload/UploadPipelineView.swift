//
//  UploadPipelineView.swift
//  clip
//

import AVFoundation
import SwiftUI

struct UploadPipelineView: View {
    var previewImage: CGImage?
    var onContinueEditing: () -> Void
    var onSave: () -> Void

    @State private var stage: UploadPipelineStage = .loading
    @State private var exportSoundPlayer: AVAudioPlayer?
    @State private var stageAutomationStarted = false
    @State private var loadingStartedAt = Date()

    var body: some View {
        ZStack {
            switch stage {
            case .loading:
                UploadLoadingStageView(previewImage: previewImage)
                    .transition(.opacity)
            case .exporting:
                UploadExportingStageView(previewImage: previewImage)
                    .transition(.opacity)
            case .complete:
                if let previewImage {
                    UploadCompleteStageView(
                        previewImage: previewImage,
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
            loadingStartedAt = Date()
            startStageAutomationIfNeeded()
        }
        .onChange(of: previewImage) { _, _ in
            startStageAutomationIfNeeded()
        }
        .onChange(of: stage) { _, newStage in
            if newStage == .exporting {
                playExportMemeSound()
            }
        }
    }

    private func startStageAutomationIfNeeded() {
        guard !stageAutomationStarted else { return }
        stageAutomationStarted = true
        Task { @MainActor in
            await runStageAutomation()
        }
    }

    @MainActor
    private func runStageAutomation() async {
        let minLoadingEnd = loadingStartedAt.addingTimeInterval(UploadPipelineTiming.loadingDuration)

        while Date() < minLoadingEnd || previewImage == nil {
            try? await Task.sleep(for: .milliseconds(50))
            if Task.isCancelled { return }
        }

        guard stage == .loading else { return }
        stage = .exporting

        try? await Task.sleep(for: .seconds(UploadPipelineTiming.exportingDuration))
        guard stage == .exporting, previewImage != nil else { return }
        stage = .complete
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
        previewImage: PreviewSupport.yellowPortraitMockCGImage(),
        onContinueEditing: {},
        onSave: {}
    )
}

#Preview("Upload Pipeline Preparing") {
    UploadPipelineView(
        previewImage: nil,
        onContinueEditing: {},
        onSave: {}
    )
}
