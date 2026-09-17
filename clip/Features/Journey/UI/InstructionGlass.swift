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
                .fill(.black.opacity(0.58))
        }
        .glassEffect(.regular, in: .capsule)
        .overlay {
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.72), .white.opacity(0.38)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .shadow(color: .black.opacity(0.72), radius: 22, y: 9)
    }

    /// Liquid glass for full-width rectangular CTAs on dark backgrounds.
    func instructionGlassRoundedRect(cornerRadius: CGFloat = 4) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.black.opacity(0.58))
        }
        .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.72), .white.opacity(0.38)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .shadow(color: .black.opacity(0.72), radius: 22, y: 9)
    }

    /// Outlined glass for secondary actions on dark backgrounds.
    func instructionGlassOutlineRoundedRect(cornerRadius: CGFloat = 6) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.black.opacity(0.35))
        }
        .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.78), lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.55), radius: 16, y: 6)
    }
}
