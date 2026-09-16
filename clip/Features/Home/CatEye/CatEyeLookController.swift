//
//  CatEyeLookController.swift
//  clip
//

import SwiftUI

@MainActor
@Observable
final class CatEyeLookController {
    var gaze: CGFloat = 0

    private var idleTask: Task<Void, Never>?

    func startIdleLook() {
        guard idleTask == nil else { return }
        idleTask = Task {
            gaze = -0.85
            while !Task.isCancelled {
                await dart(to: CGFloat.random(in: 0.75...1))
                try? await Task.sleep(for: .seconds(Double.random(in: 1.1...2.4)))
                await dart(to: CGFloat.random(in: -1 ... -0.75))
                try? await Task.sleep(for: .seconds(Double.random(in: 0.9...2.1)))
                if Bool.random() {
                    await dart(to: CGFloat.random(in: -0.2...0.2))
                    try? await Task.sleep(for: .seconds(Double.random(in: 0.35...0.7)))
                }
            }
        }
    }

    func stopIdleLook() {
        idleTask?.cancel()
        idleTask = nil
    }

    private func dart(to target: CGFloat) async {
        withAnimation(.easeOut(duration: 0.12)) {
            gaze = target
        }
    }
}
