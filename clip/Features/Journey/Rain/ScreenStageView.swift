//
//  ScreenStageView.swift
//  clip
//

import SwiftUI

struct ScreenStageView: View {
    let containerSize: CGSize
    var showCTA: Bool = false
    var onCTA: () -> Void = {}
    var onSettled: () -> Void

    @State private var screenZoom: CGFloat = 1.22

    var body: some View {
        let frame = ScreenMockup.frameSize(in: containerSize)
        let display = ScreenMockup.displaySize(for: frame)
        let displayOffsetY = ScreenMockup.displayCenterOffsetY(in: frame)
        let ctaBottomInset = frame.height * ScreenMockup.displayInsetBottom + 10

        ZStack {
            FallingClipsView(size: display, onSettled: onSettled)
            .frame(width: display.width, height: display.height)
            .offset(y: displayOffsetY)
            .clipShape(
                RoundedRectangle(cornerRadius: ScreenMockup.displayCornerRadius, style: .continuous)
            )

            Image("Screen")
                .resizable()
                .frame(width: frame.width, height: frame.height)
                .allowsHitTesting(false)

            if showCTA {
                VStack {
                    Spacer(minLength: 0)
                    JourneyCTAButton(action: onCTA)
                        .padding(.horizontal, frame.width * ScreenMockup.displayInsetHorizontal + 8)
                        .padding(.bottom, ctaBottomInset)
                }
                .frame(width: frame.width, height: frame.height)
                .zIndex(30)
            }
        }
        .frame(width: frame.width, height: frame.height)
        .scaleEffect(screenZoom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                screenZoom = 1.0
            }
        }
    }
}
