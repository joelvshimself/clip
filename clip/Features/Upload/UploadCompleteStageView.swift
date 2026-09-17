//
//  UploadCompleteStageView.swift
//  clip
//

import SwiftUI

struct UploadCompleteStageView: View {
    let videoURL: URL
    var previewImage: CGImage?
    var onContinueEditing: () -> Void
    var onSave: () -> Void

    @State private var resolvedPreview: CGImage?

    private var displayPreview: CGImage? {
        resolvedPreview ?? previewImage
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = displayPreview {
                    UploadPreviewCarousel(
                        previewImage: image,
                        progress: 1,
                        maxWidth: geometry.size.width
                    )
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.5)
                }

                VStack(spacing: 0) {
                    Spacer()

                    HStack(spacing: 16) {
                        Button(action: onContinueEditing) {
                            Text("Continue editing")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .instructionGlassOutlineRoundedRect(cornerRadius: 6)
                        }
                        .buttonStyle(.plain)

                        PrimaryGlassButton(
                            title: "Save",
                            shape: .roundedRect(cornerRadius: 6),
                            action: onSave
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task(id: previewTaskID) {
            await resolvePreviewIfNeeded()
        }
    }

    private var previewTaskID: String {
        let previewKey = previewImage.map { "\($0.width)x\($0.height)" } ?? "nil"
        return "\(previewKey)|\(videoURL.absoluteString)"
    }

    @MainActor
    private func resolvePreviewIfNeeded() async {
        if let previewImage {
            if resolvedPreview == nil {
                resolvedPreview = previewImage
            }
            return
        }
        guard resolvedPreview == nil else { return }
        if let frame = await UploadVideoFirstFrameLoader.load(from: videoURL) {
            resolvedPreview = frame
        }
    }
}

#Preview("Stage Complete") {
    UploadCompleteStageView(
        videoURL: PreviewSupport.sampleVideoURL,
        previewImage: PreviewSupport.yellowPortraitMockCGImage(),
        onContinueEditing: {},
        onSave: {}
    )
}
