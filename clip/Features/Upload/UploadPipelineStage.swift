//
//  UploadPipelineStage.swift
//  clip
//

import Foundation

enum UploadPipelineStage: Int, CaseIterable {
    case loading
    case exporting
    case complete
}

enum UploadPipelineTiming {
    static let loadingDuration: TimeInterval = 2.8
    static let exportingDuration: TimeInterval = 4.2
}
