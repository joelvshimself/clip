//
//  CatEyeLayout.swift
//  clip
//

import CoreGraphics

enum CatEyeSide {
    case left
    case right

    var irisImageName: String {
        switch self {
        case .left: "CatIrisLeft"
        case .right: "CatIrisRight"
        }
    }

    var pupilImageName: String {
        switch self {
        case .left: "CatPupilLeft"
        case .right: "CatPupilRight"
        }
    }

    /// Gaze axis in degrees (iris tilt on asset).
    var axisAngleDegrees: CGFloat {
        switch self {
        case .left: -22
        case .right: 22
        }
    }

    var irisGazeFactor: CGFloat { 0.58 }
}

enum MagicBeginningLayout {
    static let referenceWidth: CGFloat = 1024
    static let referenceHeight: CGFloat = 881
    static let aspect: CGFloat = referenceWidth / referenceHeight

    static let screenInsetTop: CGFloat = 0.095
    static let screenInsetBottom: CGFloat = 0.215
    static let screenInsetHorizontal: CGFloat = 0.088
    static let screenCornerRadius: CGFloat = 5

    static let leftEyeCenter = CGPoint(x: 0.360, y: 0.390)
    static let rightEyeCenter = CGPoint(x: 0.609, y: 0.379)
    static let eyeWidthFraction: CGFloat = 0.2

    static func screenRect(in size: CGSize) -> CGRect {
        let width = size.width * (1 - screenInsetHorizontal * 2)
        let height = size.height * (1 - screenInsetTop - screenInsetBottom)
        let x = size.width * screenInsetHorizontal
        let y = size.height * screenInsetTop
        return CGRect(x: x, y: y, width: width, height: height)
    }

    static func eyeCenter(for side: CatEyeSide, in size: CGSize) -> CGPoint {
        let point = side == .left ? leftEyeCenter : rightEyeCenter
        return CGPoint(x: point.x * size.width, y: point.y * size.height)
    }

    static func eyeSize(for containerWidth: CGFloat) -> CGSize {
        let w = containerWidth * eyeWidthFraction
        let h = w * (167.0 / 289.0)
        return CGSize(width: w, height: h)
    }
}

enum CatEyeMotion {
    static func offset(gaze: CGFloat, side: CatEyeSide, eyeSize: CGSize, factor: CGFloat = 1) -> CGSize {
        let radians = side.axisAngleDegrees * .pi / 180
        let travel = eyeSize.width * 0.14 * factor
        let arcY = -abs(gaze) * eyeSize.height * 0.04 * factor
        return CGSize(
            width: cos(radians) * gaze * travel,
            height: sin(radians) * gaze * travel + arcY
        )
    }
}
