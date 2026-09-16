//
//  UploadExportingStageView.swift
//  clip
//

import SwiftUI

struct UploadExportingStageView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                HStack(alignment: .center, spacing: 0) {
                    Image("Cat")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(200, geometry.size.width * 0.42))
                        .scaleEffect(x: -1, y: 1)
                        .padding(.leading, 8)

                    Spacer(minLength: 0)

                    ZStack {
                        ForEach(0..<3, id: \.self) { index in
                            CricketBallView()
                                .frame(width: ballSize(for: index), height: ballSize(for: index))
                                .offset(ballOffset(for: index, active: animate))
                                .opacity(animate ? 1 : 0.35)
                        }
                    }
                    .frame(width: 160, height: 220)
                    .padding(.trailing, 24)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }

    private func ballSize(for index: Int) -> CGFloat {
        [44, 62, 82][index]
    }

    private func ballOffset(for index: Int, active: Bool) -> CGSize {
        let baseY = CGFloat(index) * 52 + 20
        let travel: CGFloat = active ? 28 : 0
        return CGSize(width: CGFloat(index) * 18 + travel, height: baseY + travel * 0.6)
    }
}

#Preview("Stage Exporting") {
    UploadExportingStageView()
}
