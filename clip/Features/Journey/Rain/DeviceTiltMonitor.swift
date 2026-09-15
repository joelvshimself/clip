//
//  DeviceTiltMonitor.swift
//  clip
//

import CoreMotion
import CoreGraphics

final class DeviceTiltMonitor {
    static let shared = DeviceTiltMonitor()

    /// Gravity in SpriteKit scene coordinates (portrait, Y up).
    private(set) var sceneGravity = CGVector(dx: 0, dy: -48)
    /// Change in gravity direction/magnitude since last motion sample (g-units, smoothed).
    private(set) var gravityDelta: CGFloat = 0

    private let manager = CMMotionManager()
    private var smoothedScene = CGVector(dx: 0, dy: -1)
    private var previousSmoothed = CGVector(dx: 0, dy: -1)
    private let smoothingBlend: CGFloat = 0.32
    private let gravityStrength: CGFloat = 48
    private var isRunning = false

    func start() {
        #if os(iOS)
        guard !isRunning else { return }
        isRunning = true

        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: .main) { [weak self] motion, _ in
            self?.processMotion(motion)
        }
        #endif
    }

    #if os(iOS)
    private func processMotion(_ motion: CMDeviceMotion?) {
        guard let motion else { return }
        let g = motion.gravity
        let rawScene = mapGravityToScene(dx: g.x, dy: g.y)

        previousSmoothed = smoothedScene
        smoothedScene = CGVector(
            dx: smoothedScene.dx * (1 - smoothingBlend) + rawScene.dx * smoothingBlend,
            dy: smoothedScene.dy * (1 - smoothingBlend) + rawScene.dy * smoothingBlend
        )

        let deltaDx = smoothedScene.dx - previousSmoothed.dx
        let deltaDy = smoothedScene.dy - previousSmoothed.dy
        gravityDelta = hypot(deltaDx, deltaDy)

        let length = hypot(smoothedScene.dx, smoothedScene.dy)
        if length > 0.001 {
            let scale = gravityStrength / length
            sceneGravity = CGVector(dx: smoothedScene.dx * scale, dy: smoothedScene.dy * scale)
        } else {
            sceneGravity = CGVector(dx: 0, dy: -gravityStrength)
        }
    }

    /// Device gravity (g) → scene vector; portrait with SpriteKit Y up.
    private func mapGravityToScene(dx: Double, dy: Double) -> CGVector {
        CGVector(dx: CGFloat(dx), dy: CGFloat(dy))
    }
    #endif

    func stop() {
        #if os(iOS)
        manager.stopDeviceMotionUpdates()
        #endif
        isRunning = false
        sceneGravity = CGVector(dx: 0, dy: -gravityStrength)
        gravityDelta = 0
        smoothedScene = CGVector(dx: 0, dy: -1)
        previousSmoothed = CGVector(dx: 0, dy: -1)
    }
}
