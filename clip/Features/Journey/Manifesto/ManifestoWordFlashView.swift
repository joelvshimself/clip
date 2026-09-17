//
//  ManifestoWordFlashView.swift
//  clip
//

import SwiftUI

struct ManifestoWordFlashView: View {
    let word: String
    var isRedBackground: Bool = false
    var showsSilhouette: Bool = false

    private var backgroundColor: Color {
        isRedBackground ? Color(red: 0.55, green: 0.02, blue: 0.04) : .black
    }

    var body: some View {
        ZStack {
            backgroundColor

            if showsSilhouette {
                Image("CatSilhouette")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(0.92)
                    .allowsHitTesting(false)
            }

            Text(word)
                .font(.system(size: 68, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.35)
                .lineLimit(1)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ManifestoWordFlashView(word: "power", isRedBackground: false, showsSilhouette: true)
        .frame(width: 320, height: 480)
}
