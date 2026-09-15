//
//  ContentView.swift
//  clip
//

import SwiftUI

struct ContentView: View {
    @State private var journeyPhase: JourneyPhase = .idle
    @State private var libraryVideos: [URL] = []
    @State private var uploadPipelineVideoURL: URL?

    var body: some View {
        Group {
            if let uploadPipelineVideoURL {
                UploadPipelineView(
                    videoURL: uploadPipelineVideoURL,
                    onContinueEditing: { uploadPipelineVideoURL = nil },
                    onSave: { uploadPipelineVideoURL = nil }
                )
            } else if journeyPhase == .home {
                HomeView(
                    libraryVideos: $libraryVideos,
                    onVideoUploaded: { url in uploadPipelineVideoURL = url }
                )
            } else {
                JourneyRootView(journeyPhase: $journeyPhase)
            }
        }
    }
}

#Preview {
    ContentView()
}
