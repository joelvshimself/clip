//
//  RevealArt.swift
//  clip
//

import CoreGraphics
import Foundation

enum RevealArt {
    static let arribaAspect: CGFloat = 1302 / 1608
    static let abajoAspect: CGFloat = 2200 / 1608
    static let scrollContentMultiplier: CGFloat = 1.6
    static let manualOpenCap: CGFloat = 0.5
    static let snapThreshold: CGFloat = 0.92
    static let snapReleaseThreshold: CGFloat = 0.75
    static let snapDuration: TimeInterval = 0.7
    static let travelPadding: CGFloat = 48
}
