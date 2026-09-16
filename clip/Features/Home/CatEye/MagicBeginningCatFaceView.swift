//
//  MagicBeginningCatFaceView.swift
//  clip
//

import SwiftUI

struct MagicBeginningCatFaceView: View {
    var width: CGFloat
    var animateEyes: Bool = true
    var lookController: CatEyeLookController?

    @State private var internalLookController = CatEyeLookController()

    private var activeController: CatEyeLookController {
        lookController ?? internalLookController
    }

    var body: some View {
        let height = width / MagicBeginningLayout.aspect
        let size = CGSize(width: width, height: height)
        let eyeSize = MagicBeginningLayout.eyeSize(for: width)

        ZStack(alignment: .topLeading) {
            Image("MagicBeginning")
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)

            CatEyeAssembly(
                side: .left,
                gaze: activeController.gaze,
                eyeSize: eyeSize,
                blinkAmount: activeController.blinkAmount
            )
            .position(MagicBeginningLayout.eyeCenter(for: .left, in: size))

            CatEyeAssembly(
                side: .right,
                gaze: activeController.gaze,
                eyeSize: eyeSize,
                blinkAmount: activeController.blinkAmount
            )
            .position(MagicBeginningLayout.eyeCenter(for: .right, in: size))
        }
        .frame(width: width, height: height)
        .onAppear {
            guard animateEyes, lookController == nil else { return }
            internalLookController.startIdleLook()
        }
        .onDisappear {
            guard lookController == nil else { return }
            internalLookController.stopIdleLook()
        }
    }
}

#Preview {
    MagicBeginningCatFaceView(width: 280)
        .background(Color.black)
}
