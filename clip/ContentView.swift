//
//  ContentView.swift
//  clip
//
//  Created by Joel on 15/09/26.
//

import SwiftUI

private enum RevealArt {
    static let arribaAspect: CGFloat = 1302 / 1608
    static let abajoAspect: CGFloat = 2200 / 1608
    static let scrollContentMultiplier: CGFloat = 1.6
    static let manualOpenCap: CGFloat = 0.5
    static let snapThreshold: CGFloat = 0.92
    static let snapReleaseThreshold: CGFloat = 0.75
    static let snapDuration: TimeInterval = 0.7
    static let travelPadding: CGFloat = 48
}

struct ContentView: View {
    @State private var scrollProgress: CGFloat = 0
    @State private var isFullyOpen = false
    @State private var hintBounce = false

    private var openAmount: CGFloat {
        isFullyOpen ? 1 : scrollProgress * RevealArt.manualOpenCap
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let arribaHeight = width * RevealArt.arribaAspect
            let abajoHeight = width * RevealArt.abajoAspect
            let scrollRange = height * (RevealArt.scrollContentMultiplier - 1)

            ZStack {
                Color.black
                    .ignoresSafeArea()

                Image("Cat")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: width * 0.88,
                        maxHeight: height * 0.78
                    )

                Image("Arriba")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .offset(y: -openAmount * (arribaHeight + RevealArt.travelPadding))
                    .ignoresSafeArea(edges: .top)

                Image("Abajo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .offset(y: openAmount * (abajoHeight + RevealArt.travelPadding))
                    .ignoresSafeArea(edges: .bottom)

                scrollHint
                    .opacity(hintOpacity)
                    .allowsHitTesting(false)

                ScrollView {
                    Color.clear
                        .frame(height: height * RevealArt.scrollContentMultiplier)
                }
                .scrollIndicators(.hidden)
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, offset in
                    handleScroll(offset: offset, scrollRange: scrollRange)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                hintBounce = true
            }
        }
    }

    private var scrollHint: some View {
        VStack(spacing: 10) {
            Image(systemName: "chevron.down")
                .font(.title2.weight(.semibold))
                .offset(y: hintBounce ? 6 : -4)

            Text("Desliza para continuar")
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.black.opacity(0.35), in: Capsule())
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 36)
    }

    private var hintOpacity: Double {
        Double(max(0, 1 - scrollProgress * 2.5))
    }

    private func handleScroll(offset: CGFloat, scrollRange: CGFloat) {
        guard scrollRange > 0 else { return }

        let rawProgress = min(max(offset / scrollRange, 0), 1)

        if rawProgress >= RevealArt.snapThreshold, !isFullyOpen {
            withAnimation(.easeIn(duration: RevealArt.snapDuration)) {
                isFullyOpen = true
            }
        } else if rawProgress < RevealArt.snapReleaseThreshold, isFullyOpen {
            isFullyOpen = false
        }

        scrollProgress = rawProgress
    }
}

#Preview {
    ContentView()
}
