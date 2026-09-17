//
//  HorrorFilmText.swift
//  clip
//

import SwiftUI

enum HorrorFilmText {
    static let silhouetteName = "CatSilhouette"

    static func shader(time: Double, grainStrength: Double = 1.0) -> Shader {
        ShaderLibrary.horrorFilmText(
            .float(Float(time)),
            .float(Float(grainStrength)),
            .image(Image(silhouetteName))
        )
    }
}

struct HorrorFilmTextModifier: ViewModifier {
    let time: Double
    var grainStrength: Double = 1.0

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            content
                .colorEffect(
                    HorrorFilmText.shader(
                        time: context.date.timeIntervalSinceReferenceDate,
                        grainStrength: grainStrength
                    )
                )
        }
    }
}

extension View {
    func horrorFilmTextStyle(grainStrength: Double = 1.0) -> some View {
        modifier(HorrorFilmTextModifier(time: 0, grainStrength: grainStrength))
    }
}

struct HorrorBoldWord: View {
    let text: String
    var fontSize: CGFloat = 72
    var minimumScale: CGFloat = 0.25
    var grainStrength: Double = 1.0

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .black, design: .default))
            .tracking(-1.5)
            .foregroundStyle(.white)
            .shadow(color: .white.opacity(0.35), radius: 0, x: 0, y: 0)
            .shadow(color: .white.opacity(0.2), radius: 1, x: 0, y: 0)
            .horrorFilmTextStyle(grainStrength: grainStrength)
            .minimumScaleFactor(minimumScale)
            .lineLimit(1)
    }
}
