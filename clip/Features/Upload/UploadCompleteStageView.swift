//
//  UploadCompleteStageView.swift
//  clip
//

import SwiftUI

struct UploadCompleteStageView: View {
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

#Preview("Stage Complete") {
    UploadCompleteStageView(
        videoURL: PreviewSupport.sampleVideoURL,
        onContinueEditing: {},
        onSave: {}
    )
}
