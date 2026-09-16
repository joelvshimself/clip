//
//  InstructionGlass.swift
//  clip
//

import SwiftUI

extension View {
    /// Liquid glass tuned for short instructional copy on dark backgrounds.
    func instructionGlassCapsule() -> some View {
        background {
            Capsule()
                .fill(.black.opacity(0.42))
        }
        .glassEffect(.regular, in: .capsule)
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.52), lineWidth: 1.35)
        }
        .shadow(color: .black.opacity(0.62), radius: 18, y: 7)
    }

    /// Liquid glass for full-width rectangular CTAs on dark backgrounds.
    func instructionGlassRoundedRect(cornerRadius: CGFloat = 4) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.black.opacity(0.42))
        }
        .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.52), lineWidth: 1.35)
        }
        .shadow(color: .black.opacity(0.62), radius: 18, y: 7)
    }
}
