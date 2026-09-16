//
//  UploadVideoLoadingPreviewView.swift
//  clip
//

import SwiftUI

/// Lightweight loading preview: optional still image plus a continuous scan shimmer.
struct UploadVideoLoadingPreviewView: View {
    var previewImage: CGImage?

    @State private var scanProgress = -1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(white: 0.12)

                if let previewImage {
                    Image(decorative: previewImage, scale: 1)
                        .resizable()
                        .scaledToFill()
                }

                shimmerOverlay(in: geometry.size)
            }
            .clipped()
        }
        .onAppear {
            startScanAnimation()
        }
    }

    @ViewBuilder
    private func shimmerOverlay(in size: CGSize) -> some View {
        LinearGradient(
            colors: [.clear, .white.opacity(previewImage == nil ? 0.1 : 0.16), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: max(40, size.width * 0.24))
        .offset(x: scanProgress * size.width)
        .blendMode(.screen)
    }

    private func startScanAnimation() {
        scanProgress = -1
        withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
            scanProgress = 1
        }
    }
}
