//
//  ManifestoStageView.swift
//  clip
//

import SwiftUI

/// Flash sequence sized for the TV display rect (used by ScreenStageView when re-enabled).
struct ManifestoStageView: View {
    let size: CGSize
    var onSettled: () -> Void

    var body: some View {
        ManifestoFlashFlowView(containerSize: size, onSettled: onSettled)
    }
}

#Preview {
    ManifestoStageView(size: CGSize(width: 300, height: 420), onSettled: {})
        .background(Color.gray)
}
