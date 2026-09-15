//
//  PickedVideoFile.swift
//  clip
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct PickedVideoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).mp4")
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedVideoFile(url: destination)
        }
    }
}
