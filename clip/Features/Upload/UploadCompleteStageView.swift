//
//  UploadCompleteStageView.swift
//  clip
//

import SwiftUI

struct UploadCompleteStageView: View {
    let previewImage: CGImage
    var onContinueEditing: () -> Void
    var onSave: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                UploadPreviewCarousel(
                    previewImage: previewImage,
                    progress: 1,
                    maxWidth: geometry.size.width
                )
                .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.42)

                Text("Here you have, Darling")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 20)

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
                            leadingImageName: "LoadingCatTop6",
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
    }
}

#Preview("Stage Complete") {
    UploadCompleteStageView(
        previewImage: PreviewSupport.yellowPortraitMockCGImage()!,
        onContinueEditing: {},
        onSave: {}
    )
}
