//
//  PrimaryGlassButton.swift
//  clip
//

import SwiftUI

enum PrimaryGlassButtonShape {
    case capsule
    case roundedRect(cornerRadius: CGFloat)
}

struct PrimaryGlassButton: View {
    let title: String
    var shape: PrimaryGlassButtonShape = .roundedRect(cornerRadius: 14)
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }

    @ViewBuilder
    private var label: some View {
        let text = Text(title)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.45), radius: 2, y: 1)

        switch shape {
        case .capsule:
            text
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .instructionGlassCapsule()
        case .roundedRect(let cornerRadius):
            text
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .instructionGlassRoundedRect(cornerRadius: cornerRadius)
        }
    }
}
