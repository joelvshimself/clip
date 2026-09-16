//
//  LoadingCatPose.swift
//  clip
//

import SwiftUI

enum LoadingCatAnchor: CaseIterable {
    case top
    case left
    case right

    func next() -> LoadingCatAnchor {
        switch self {
        case .top: return .left
        case .left: return .right
        case .right: return .top
        }
    }
}

/// Edit these values to nudge each loading cat asset (points). Use placement previews in Xcode.
enum LoadingCatTuning {
    /// Per variant LoadingCatTop1…8 — extra downward shift in points (+Y).
    static var topDown: [CGFloat] = [24, 30, 40, 16, 13, 43, 46, 32]

    /// LoadingCatLeft — push further left (+value subtracts from X offset).
    static var leftHorizontal: CGFloat = -15

    /// LoadingCatRight — push further right (+value adds to X offset).
    static var rightHorizontal: CGFloat = -36

    static func label(anchor: LoadingCatAnchor, topVariantIndex: Int) -> String {
        let tune = LoadingCatFineTune.fromStatic()
        return tune.label(anchor: anchor, topVariantIndex: topVariantIndex)
    }
}

struct LoadingCatFineTune: Equatable {
    var topDown: [CGFloat]
    var leftHorizontal: CGFloat
    var rightHorizontal: CGFloat

    static func fromStatic() -> LoadingCatFineTune {
        LoadingCatFineTune(
            topDown: LoadingCatTuning.topDown,
            leftHorizontal: LoadingCatTuning.leftHorizontal,
            rightHorizontal: LoadingCatTuning.rightHorizontal
        )
    }

    func label(anchor: LoadingCatAnchor, topVariantIndex: Int) -> String {
        switch anchor {
        case .top:
            let i = topVariantIndex % LoadingCatPose.topVariantCount
            let value = topDown.indices.contains(i) ? topDown[i] : 0
            return "topDown[\(i)] = \(format(value))"
        case .left:
            return "leftHorizontal = \(format(leftHorizontal))"
        case .right:
            return "rightHorizontal = \(format(rightHorizontal))"
        }
    }

    func offsetAdjustment(anchor: LoadingCatAnchor, topVariantIndex: Int) -> CGSize {
        switch anchor {
        case .top:
            let i = topVariantIndex % LoadingCatPose.topVariantCount
            let down = topDown.indices.contains(i) ? topDown[i] : 0
            return CGSize(width: 0, height: down)
        case .left:
            return CGSize(width: -leftHorizontal, height: 0)
        case .right:
            return CGSize(width: rightHorizontal, height: 0)
        }
    }

    var swiftSnippet: String {
        let values = topDown.prefix(LoadingCatPose.topVariantCount).map { format($0) }.joined(separator: ", ")
        return """
        static var topDown: [CGFloat] = [\(values)]
        static var leftHorizontal: CGFloat = \(format(leftHorizontal))
        static var rightHorizontal: CGFloat = \(format(rightHorizontal))
        """
    }

    private func format(_ value: CGFloat) -> String {
        if abs(value.rounded() - value) < 0.001 {
            return "\(Int(value.rounded()))"
        }
        return String(format: "%.1f", value)
    }
}

enum LoadingCatPose {
    static let topVariantCount = 8
    static let videoWidthFraction: CGFloat = 0.58
    static let videoAspect: CGFloat = 0.72

    static func assetName(anchor: LoadingCatAnchor, topVariantIndex: Int) -> String {
        switch anchor {
        case .top:
            let index = (topVariantIndex % topVariantCount) + 1
            return "LoadingCatTop\(index)"
        case .left:
            return "LoadingCatLeft"
        case .right:
            return "LoadingCatRight"
        }
    }

    /// Offset from the center of the video rect so the cat image sits flush on the chosen edge.
    static func offset(
        for anchor: LoadingCatAnchor,
        videoSize: CGSize,
        catSize: CGSize,
        topVariantIndex: Int = 0,
        tuning: LoadingCatFineTune? = nil
    ) -> CGSize {
        let tune = tuning ?? LoadingCatFineTune.fromStatic()
        let halfVideoW = videoSize.width / 2
        let halfVideoH = videoSize.height / 2
        let halfCatW = catSize.width / 2
        let halfCatH = catSize.height / 2

        let base: CGSize
        switch anchor {
        case .top:
            base = CGSize(
                width: 0,
                height: -(halfVideoH + halfCatH)
            )
        case .left:
            base = CGSize(
                width: -(halfVideoW + halfCatW),
                height: halfVideoH - halfCatH
            )
        case .right:
            base = CGSize(
                width: halfVideoW + halfCatW,
                height: halfVideoH - halfCatH
            )
        }

        let fineTune = tune.offsetAdjustment(anchor: anchor, topVariantIndex: topVariantIndex)
        return CGSize(
            width: base.width + fineTune.width,
            height: base.height + fineTune.height
        )
    }

    static func catSize(for anchor: LoadingCatAnchor, videoSize: CGSize) -> CGSize {
        switch anchor {
        case .top:
            let width = videoSize.width * 0.5
            return CGSize(width: width, height: width * 1.05)
        case .left, .right:
            let height = videoSize.height * 0.6
            return CGSize(width: height * 0.72, height: height)
        }
    }
}
