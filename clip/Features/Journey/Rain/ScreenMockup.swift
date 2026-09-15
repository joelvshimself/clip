//
//  ScreenMockup.swift
//  clip
//

import CoreGraphics

enum ScreenMockup {
    /// `screen.png` full asset (1608×3496).
    static let assetAspect: CGFloat = 1608.0 / 3496.0
    /// Inner display vs full frame (tuned to `Screen.imageset/screen.png`).
    static let displayInsetTop: CGFloat = 0.042
    static let displayInsetBottom: CGFloat = 0.145
    static let displayInsetHorizontal: CGFloat = 0.088
    static let displayCornerRadius: CGFloat = 8

    /// Extra inset inside the display rect for SpriteKit walls (keeps clips off rounded edges).
    static func playfieldPadding(for display: CGSize) -> PlayfieldPadding {
        PlayfieldPadding(
            left: max(6, display.width * 0.02),
            right: max(6, display.width * 0.02),
            bottom: max(8, display.height * 0.02),
            top: max(6, display.height * 0.015)
        )
    }

    static func frameSize(in container: CGSize) -> CGSize {
        let heightFromWidth = container.width / assetAspect
        if heightFromWidth <= container.height {
            return CGSize(width: container.width, height: heightFromWidth)
        }
        return CGSize(width: container.height * assetAspect, height: container.height)
    }

    static func displaySize(for frame: CGSize) -> CGSize {
        let width = frame.width * (1 - displayInsetHorizontal * 2)
        let height = frame.height * (1 - displayInsetTop - displayInsetBottom)
        return CGSize(width: width, height: height)
    }

    /// Vertical offset to center the display rect inside the frame (frame space, Y down).
    static func displayCenterOffsetY(in frame: CGSize) -> CGFloat {
        frame.height * (ScreenMockup.displayInsetTop - 0.5) + displaySize(for: frame).height / 2
    }
}

struct PlayfieldPadding: Equatable {
    var left: CGFloat
    var right: CGFloat
    var bottom: CGFloat
    var top: CGFloat
}
