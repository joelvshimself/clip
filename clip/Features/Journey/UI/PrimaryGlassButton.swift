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
    var leadingImageName: String? = nil
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
        switch shape {
        case .capsule:
            labelContent
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .instructionGlassCapsule()
        case .roundedRect(let cornerRadius):
            labelContent
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .instructionGlassRoundedRect(cornerRadius: cornerRadius)
        }
    }

    private var labelContent: some View {
        HStack(spacing: 7) {
            if let leadingImageName {
                Image(leadingImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 47.4, height: 47.4)
            }

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
        }
        .frame(height: 22)
    }
}
