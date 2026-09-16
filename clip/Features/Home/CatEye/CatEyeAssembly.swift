//
//  CatEyeAssembly.swift
//  clip
//

import SwiftUI

struct CatEyeAssembly: View {
    let side: CatEyeSide
    let gaze: CGFloat
    let eyeSize: CGSize
    var blinkAmount: CGFloat = 0

    var body: some View {
        let pupilOffset = CatEyeMotion.offset(gaze: gaze, side: side, eyeSize: eyeSize, factor: 1)
        let irisOffset = CatEyeMotion.offset(
            gaze: gaze,
            side: side,
            eyeSize: eyeSize,
            factor: side.irisGazeFactor
        )

        ZStack {
            Image(side.irisImageName)
                .resizable()
                .scaledToFit()
                .frame(width: eyeSize.width, height: eyeSize.height)
                .offset(x: irisOffset.width, y: irisOffset.height)

            Image(side.pupilImageName)
                .resizable()
                .scaledToFit()
                .frame(width: eyeSize.width, height: eyeSize.height)
                .offset(x: pupilOffset.width, y: pupilOffset.height)
                .mask {
                    Image(side.irisImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: eyeSize.width, height: eyeSize.height)
                        .offset(x: irisOffset.width, y: irisOffset.height)
                }
        }
        .frame(width: eyeSize.width, height: eyeSize.height)
        .scaleEffect(y: 1 - blinkAmount * 0.92, anchor: .center)
    }
}

#Preview("Left Eye") {
    CatEyeAssembly(
        side: .left,
        gaze: 0.6,
        eyeSize: CGSize(width: 72, height: 42)
    )
    .padding()
    .background(Color.black)
}

#Preview("Right Eye") {
    CatEyeAssembly(
        side: .right,
        gaze: -0.5,
        eyeSize: CGSize(width: 72, height: 42)
    )
    .padding()
    .background(Color.black)
}
