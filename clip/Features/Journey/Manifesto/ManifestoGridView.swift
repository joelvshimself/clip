//
//  ManifestoGridView.swift
//  clip
//

import SwiftUI

struct ManifestoGridView: View {
    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 8
            let spacing: CGFloat = 6
            let columnCount: CGFloat = 4
            let tileWidth = (geometry.size.width - horizontalPadding * 2 - spacing * (columnCount - 1)) / columnCount
            let tileHeight = tileWidth / 0.42

            VStack(spacing: spacing) {
                HorrorBoldWord(
                    text: "ALL THIS UNDER YOUR CONTROL",
                    fontSize: 11,
                    minimumScale: 0.2,
                    grainStrength: 0.95
                )
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 8)

                HStack(spacing: spacing) {
                    manifestoTile("All", width: tileWidth, height: tileHeight)
                    manifestoTile("This", width: tileWidth, height: tileHeight)
                    manifestoTile("under", width: tileWidth, height: tileHeight)
                    manifestoTile("Your", width: tileWidth, height: tileHeight)
                }
                .padding(.horizontal, horizontalPadding)

                HStack(spacing: spacing) {
                    controlTile(width: tileWidth, height: tileHeight)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, horizontalPadding)

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private func manifestoTile(_ word: String, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color(white: 0.12))
            .overlay {
                HorrorBoldWord(
                    text: word,
                    fontSize: 22,
                    minimumScale: 0.35,
                    grainStrength: 0.9
                )
                .padding(4)
            }
            .frame(width: width, height: height)
    }

    private func controlTile(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color(white: 0.12))
            .overlay {
                ZStack {
                    Image(HorrorFilmText.silhouetteName)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                        .opacity(0.85)

                    HorrorBoldWord(
                        text: "Control",
                        fontSize: 22,
                        minimumScale: 0.35,
                        grainStrength: 1.05
                    )
                    .padding(4)
                }
            }
            .frame(width: width, height: height)
    }
}

#Preview {
    ManifestoGridView()
        .frame(width: 300, height: 420)
}
