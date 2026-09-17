//
//  LibraryVideoItem.swift
//  clip
//

import CoreGraphics
import Foundation

/// In-memory library entry: one poster frame per picked video (no stored video file).
struct LibraryVideoItem: Identifiable, Equatable {
    let id: UUID
    let posterImage: CGImage

    init(id: UUID = UUID(), posterImage: CGImage) {
        self.id = id
        self.posterImage = posterImage
    }

    static func == (lhs: LibraryVideoItem, rhs: LibraryVideoItem) -> Bool {
        lhs.id == rhs.id
    }
}
