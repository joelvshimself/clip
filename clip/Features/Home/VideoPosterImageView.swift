//
//  VideoPosterImageView.swift
//  clip
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct VideoPosterImageView: View {
    let posterImage: CGImage
    var cornerRadius: CGFloat = 4

    var body: some View {
        #if canImport(UIKit)
        Image(uiImage: UIImage(cgImage: posterImage))
            .resizable()
            .scaledToFill()
        #else
        Color(white: 0.4)
        #endif
    }
}
