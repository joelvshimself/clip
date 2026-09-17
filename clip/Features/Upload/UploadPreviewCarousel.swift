//
//  UploadPreviewCarousel.swift
//  clip
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum UploadPreviewCarouselLayout {
    static let widthFraction: CGFloat = 0.52
    static let heightOverWidth: CGFloat = 16 / 9
    static let startWidthFraction: CGFloat = 0.38
    static let cornerRadius: CGFloat = 12
    static let layerCount = 5
    static let scalePerDepth: CGFloat = 0.8
    static let verticalStepFraction: CGFloat = 0.031
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
        let maximumDepth = CGFloat(UploadPreviewCarouselLayout.layerCount - 1)
        return cardHeight
            * maximumDepth
            * UploadPreviewCarouselLayout.verticalStepFraction
            * tier
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ForEach(0 ..< UploadPreviewCarouselLayout.layerCount, id: \.self) { layer in
                let depth = UploadPreviewCarouselLayout.layerCount - 1 - layer

                card(atDepth: depth)
                    .scaleEffect(
                        layerScale(depth: depth),
                        anchor: .top
                    )
                    .offset(
                        y: -CGFloat(depth)
                            * cardHeight
                            * UploadPreviewCarouselLayout.verticalStepFraction
                            * tier
                    )
                    .opacity(cardOpacity(depth: depth))
                    .zIndex(Double(layer))
            }
        }
        .frame(width: cardWidth, height: cardHeight + stackTopPadding, alignment: .bottom)
    }

    private func layerScale(depth: Int) -> CGFloat {
        let finalScale = pow(UploadPreviewCarouselLayout.scalePerDepth, CGFloat(depth))
        return 1 + (finalScale - 1) * tier
    }

    private func cardOpacity(depth: Int) -> Double {
        if depth == 0 { return 1 }
        let bases: [Double] = [0, 0.94, 0.90, 0.86, 0.82]
        let base = bases[min(depth, bases.count - 1)]
        return base * Double(tier)
    }

    @ViewBuilder
    private func card(atDepth depth: Int) -> some View {
        if depth == 0 {
            previewCard
        } else {
            placeholderCard(depth: depth)
        }
    }

    @ViewBuilder
    private func placeholderCard(depth: Int) -> some View {
        let gray = 0.62 - CGFloat(depth) * 0.06
        RoundedRectangle(cornerRadius: UploadPreviewCarouselLayout.cornerRadius, style: .continuous)
            .fill(Color(white: gray))
            .frame(width: cardWidth, height: cardHeight)
            .overlay {
                RoundedRectangle(cornerRadius: UploadPreviewCarouselLayout.cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
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
