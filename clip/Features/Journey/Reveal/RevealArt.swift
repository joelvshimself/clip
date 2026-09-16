//
//  RevealArt.swift
//  clip
//

import CoreGraphics
import Foundation

enum RevealArt {
    static let arribaAspect: CGFloat = 1302 / 1608
    static let abajoAspect: CGFloat = 2200 / 1608
    static let manualOpenCap: CGFloat = 0.5
    static let pinchBaseline: CGFloat = 1
    /// Pinch scale span (1 → 1+pinchFullSpan) maps to reveal progress 0 → 1.
    static let pinchFullSpan: CGFloat = 0.72
    static let snapThreshold: CGFloat = 0.92
    static let snapReleaseThreshold: CGFloat = 0.75
    static let snapDuration: TimeInterval = 0.75
    /// How slowly curtains follow the pinch (even if the gesture is fast).
    static let pinchFollowDuration: TimeInterval = 0.52
    static let travelPadding: CGFloat = 48

    /// `revealProgress` at which curtains are fully parted (`openAmount == 1`).
    static let revealProgressForFullOpen: CGFloat = 1 / manualOpenCap
}
