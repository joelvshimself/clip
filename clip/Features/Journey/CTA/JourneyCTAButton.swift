//
//  JourneyCTAButton.swift
//  clip
//

import SwiftUI

struct JourneyCTAButton: View {
    var action: () -> Void = {}

    @State private var appeared = false

    var body: some View {
        PrimaryGlassButton(title: "enter to the journey", shape: .capsule, action: action)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .onAppear {
                withAnimation(.easeOut(duration: 0.55)) {
                    appeared = true
                }
            }
            .onDisappear {
                appeared = false
            }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        JourneyCTAButton()
    }
}
