//
//  JourneyPhase.swift
//  clip
//

import Foundation

enum JourneyPhase: Equatable {
    case idle
    case blast
    case wait
    case rain
    case cta
    case home
}

enum JourneyLayout {
    static let ctaBottomReserve: CGFloat = 96
}

enum JourneyTiming {
    static let waitAfterExplosion: TimeInterval = 2
    static let waitAfterSettled: TimeInterval = 2
    static let catLaunchDuration: TimeInterval = 0.45
    static let ctaBackupDelay: TimeInterval = 7
}
