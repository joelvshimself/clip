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
        sessionFileRepresentation(contentType: .movie, preferredExtension: "mp4")
        sessionFileRepresentation(contentType: .mpeg4Movie, preferredExtension: "mp4")
        sessionFileRepresentation(contentType: .quickTimeMovie, preferredExtension: "mov")
        sessionFileRepresentation(contentType: .video, preferredExtension: "mp4")
    }

    private static func sessionFileRepresentation(
        contentType: UTType,
        preferredExtension: String
    ) -> some TransferRepresentation {
        FileRepresentation(contentType: contentType) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            PickedVideoFile(url: received.file)
        }
    }
}

enum VideoImportService {
    static func persistToTemporaryLibrary(from sourceURL: URL) throws -> URL {
        let ext = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).\(ext)")

        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return destination
    }
}
