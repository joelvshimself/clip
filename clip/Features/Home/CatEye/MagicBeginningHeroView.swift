//
//  MagicBeginningHeroView.swift
//  clip
//

import SwiftUI

struct MagicBeginningHeroView: View {
    var body: some View {
        Image("CatOcaja1")
            .resizable()
            .scaledToFit()
            .scaleEffect(0.7)
            .frame(maxWidth: .infinity)
            .offset(y: 28)
    }
}

#Preview("Magic Beginning — Caja 1") {
    MagicBeginningHeroView()
        .padding()
        .background(Color.black)
}
