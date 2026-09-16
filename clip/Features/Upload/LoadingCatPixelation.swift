//
//  LoadingCatPixelation.swift
//  clip
//

import SwiftUI

enum LoadingCatPixelation {
    /// Max sampling offset for the pixelation shader (half of coarsest block).
    static let maxSampleOffset = CGSize(width: 20, height: 20)

    static func shader(amount: Double) -> Shader {
        ShaderLibrary.loadingCatPixelation(.float(Float(amount)))
    }
}
