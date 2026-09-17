//
//  UploadPreviewCarousel.swift
//  clip
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum UploadPreviewCarouselLayout {
    static let widthFraction: CGFloat = 0.44
    static let heightOverWidth: CGFloat = 16 / 9
    static let startWidthFraction: CGFloat = 0.34
    static let cornerRadius: CGFloat = 10
    static let layerCount = 4
    static let scaleStepPerDepth: CGFloat = 0.04
    static let verticalStepPerDepth: CGFloat = 10
}

struct UploadPreviewCarousel: View {
    let previewImage: CGImage
    /// 0 = single tiny front card; 1 = full deck stepped upward behind front.
    var progress: CGFloat
    var maxWidth: CGFloat

    private var clampedProgress: CGFloat {
        min(max(progress, 0), 1)
    }

    private var tier: CGFloat {
        clampedProgress
    }

    private var cardWidth: CGFloat {
        let final = maxWidth * UploadPreviewCarouselLayout.widthFraction
        let start = final * UploadPreviewCarouselLayout.startWidthFraction
        return start + (final - start) * clampedProgress
    }

    private var cardHeight: CGFloat {
        cardWidth * UploadPreviewCarouselLayout.heightOverWidth
    }

    private var stackTopPadding: CGFloat {
        CGFloat(UploadPreviewCarouselLayout.layerCount - 1)
            * UploadPreviewCarouselLayout.verticalStepPerDepth
            * tier
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ForEach(0 ..< UploadPreviewCarouselLayout.layerCount, id: \.self) { layer in
                let depth = UploadPreviewCarouselLayout.layerCount - 1 - layer

                previewCard
                    .scaleEffect(1 - CGFloat(depth) * UploadPreviewCarouselLayout.scaleStepPerDepth * tier, anchor: .bottom)
                    .offset(y: -CGFloat(depth) * UploadPreviewCarouselLayout.verticalStepPerDepth * tier)
                    .opacity(cardOpacity(depth: depth))
                    .zIndex(Double(layer))
            }
        }
        .frame(width: cardWidth, height: cardHeight + stackTopPadding)
    }

    private func cardOpacity(depth: Int) -> Double {
        if depth == 0 { return 1 }
        let bases: [Double] = [0, 0.55, 0.50, 0.45]
        let base = bases[min(depth, bases.count - 1)]
        return base * Double(tier)
    }

    @ViewBuilder
    private var previewCard: some View {
        #if canImport(UIKit)
        Image(uiImage: UIImage(cgImage: previewImage))
            .resizable()
            .scaledToFill()
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: UploadPreviewCarouselLayout.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: UploadPreviewCarouselLayout.cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.55), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.45), radius: 12, y: 6)
        #else
        Color(white: 0.4)
            .frame(width: cardWidth, height: cardHeight)
        #endif
    }
}

#Preview("Carousel Reveal") {
    ZStack {
        Color.black.ignoresSafeArea()
        if let image = PreviewSupport.yellowPortraitMockCGImage() {
            UploadPreviewCarousel(previewImage: image, progress: 1, maxWidth: 393)
        }
    }
}
