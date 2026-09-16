//
//  CricketBallView.swift
//  clip
//

import SwiftUI

struct CricketBallView: View {
    var body: some View {
        Circle()
            .fill(Color.white)
            .overlay {
                Capsule()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 6, height: 44)
                    .rotationEffect(.degrees(32))
                Capsule()
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [3, 4]))
                    .foregroundStyle(Color.black.opacity(0.5))
                    .frame(width: 28, height: 52)
                    .rotationEffect(.degrees(32))
            }
    }
}

#Preview("Cricket Ball") {
    CricketBallView()
        .frame(width: 64, height: 64)
        .padding()
        .background(Color.black)
}
