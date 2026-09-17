//
//  UploadVideoThumbnailLoader.swift
//  clip
//

import Photos
import PhotosUI
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum UploadVideoThumbnailLoader {
    /// Small preview from the Photos library without reading the full video file.
    static func loadPreview(from item: PhotosPickerItem) async -> CGImage? {
        #if !os(iOS)
        return nil
        #else
        guard let identifier = item.itemIdentifier else { return nil }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = assets.firstObject else { return nil }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            var resumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 480, height: 680),
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(returning: nil)
                    #if DEBUG
                    print("Upload preview thumbnail failed:", error.localizedDescription)
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
