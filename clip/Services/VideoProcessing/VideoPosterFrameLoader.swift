//
//  VideoPosterFrameLoader.swift
//  clip
//

import CoreGraphics
import Photos
import PhotosUI
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Lightweight poster extraction for uploads and library tiles — no full video import or transcode.
enum VideoPosterFrameLoader {
    static let maxPixelWidth: CGFloat = 480
    static let maxPixelHeight: CGFloat = 680

    /// Single bounded frame from the Photos library asset backing a picker item.
    static func loadPreview(from item: PhotosPickerItem) async -> CGImage? {
        #if !os(iOS)
        return nil
        #else
        guard let identifier = item.itemIdentifier else { return nil }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = assets.firstObject else { return nil }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            var resumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: maxPixelWidth, height: maxPixelHeight),
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(returning: nil)
                    #if DEBUG
                    print("Video poster frame failed:", error.localizedDescription)
                    #endif
                    return
                }
                if info?[PHImageCancelledKey] as? Bool == true {
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(returning: nil)
                    return
                }
                guard let image, let cgImage = image.cgImage else { return }
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: cgImage)
            }
        }
        #endif
    }
}
