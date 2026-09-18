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
            .scaleEffect(0.82)
            .frame(maxWidth: .infinity)
            .offset(y: 44)
    }
}

#Preview("Magic Beginning — Caja 1") {
    MagicBeginningHeroView()
        .padding()
        .background(Color.black)
}
