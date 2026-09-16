//
//  JourneyCTAButton.swift
//  clip
//

import SwiftUI

struct JourneyCTAButton: View {
    var action: () -> Void = {}

    @State private var appeared = false

    var body: some View {
        Button(action: action) {
            Text("enter to the journey")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
        }
        .buttonStyle(.glass)
        .shadow(color: .black.opacity(0.45), radius: 12, y: 4)
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
