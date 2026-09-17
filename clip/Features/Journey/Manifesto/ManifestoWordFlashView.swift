//
//  ManifestoWordFlashView.swift
//  clip
//

import SwiftUI

struct ManifestoWordFlashView: View {
    let word: String
    var isRedBackground: Bool = false
    var showsSilhouette: Bool = false
    var handVideoURL: URL?

    private var backgroundColor: Color {
        isRedBackground ? Color(red: 0.55, green: 0.02, blue: 0.04) : .black
    }

    var body: some View {
        ZStack {
            backgroundColor

            if let handVideoURL {
                LoopingVideoView(url: handVideoURL, previewLoopDuration: ManifestoTiming.handWordVideoDuration)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .allowsHitTesting(false)
            }

            if showsSilhouette {
                Image("CatSilhouette")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(0.8)
                    .opacity(0.92)
                    .allowsHitTesting(false)
            }

            if handVideoURL == nil {
                Text(word)
                    .font(.system(size: 68, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.35)
                    .lineLimit(1)
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ManifestoWordFlashView(word: "power", isRedBackground: false, showsSilhouette: true)
        .frame(width: 320, height: 480)
}
