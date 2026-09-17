//
//  UploadVideoFirstFrameLoader.swift
//  clip
//

import AVFoundation
import CoreGraphics

enum UploadVideoFirstFrameLoader {
    static func load(from url: URL) async -> CGImage? {
        await Task.detached(priority: .userInitiated) {
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 720, height: 1280)
            let time = CMTime(seconds: 0, preferredTimescale: 600)
            return try? generator.copyCGImage(at: time, actualTime: nil)
        }.value
    }
}
