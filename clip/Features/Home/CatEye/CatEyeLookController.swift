//
//  CatEyeLookController.swift
//  clip
//

import SwiftUI

@MainActor
@Observable
final class CatEyeLookController {
    var gaze: CGFloat = 0
    var blinkAmount: CGFloat = 0

    private var idleTask: Task<Void, Never>?

    private let maxGaze: CGFloat = 0.55
    private let gazeDuration: TimeInterval = 0.14
    private let holdDuration: TimeInterval = 0.9
    private let blinkCloseDuration: TimeInterval = 0.1
    private let blinkOpenDuration: TimeInterval = 0.08

    func startIdleLook() {
        guard idleTask == nil else { return }
        idleTask = Task {
            gaze = -maxGaze
            while !Task.isCancelled {
                await moveGaze(to: maxGaze)
                await blink()
                try? await Task.sleep(for: .seconds(holdDuration))
                await moveGaze(to: -maxGaze)
                await blink()
                try? await Task.sleep(for: .seconds(holdDuration))
            }
        }
    }

    func stopIdleLook() {
        idleTask?.cancel()
        idleTask = nil
        blinkAmount = 0
    }

    private func moveGaze(to target: CGFloat) async {
        withAnimation(.easeOut(duration: gazeDuration)) {
            gaze = target
        }
        try? await Task.sleep(for: .seconds(gazeDuration))
    }

    private func blink() async {
        withAnimation(.easeIn(duration: blinkCloseDuration)) {
            blinkAmount = 1
        }
        try? await Task.sleep(for: .seconds(blinkCloseDuration))
        withAnimation(.easeOut(duration: blinkOpenDuration)) {
            blinkAmount = 0
        }
        try? await Task.sleep(for: .seconds(blinkOpenDuration))
    }
}
