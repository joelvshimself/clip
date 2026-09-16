//
//  ContentView.swift
//  clip
//

import Photos
import PhotosUI
import SwiftUI

struct ContentView: View {
    @State private var journeyPhase: JourneyPhase = .idle
    @State private var libraryVideos: [URL] = []
    @State private var activeUploadURL: URL?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showVideoPicker = false

    var body: some View {
        Group {
            if journeyPhase != .home {
                JourneyRootView(journeyPhase: $journeyPhase)
            } else if let videoURL = activeUploadURL {
                UploadPipelineView(
                    videoURL: videoURL,
                    onContinueEditing: { activeUploadURL = nil },
                    onSave: { activeUploadURL = nil }
                )
                .id(videoURL)
            } else {
                HomeView(
                    libraryVideos: $libraryVideos,
                    onRequestVideoPicker: requestVideoPicker
                )
            }
        }
        .photosPicker(isPresented: $showVideoPicker, selection: $pickerItem, matching: .videos)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                await importVideo(from: item)
            }
        }
    }

    private func requestVideoPicker() {
        #if os(iOS)
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
                DispatchQueue.main.async {
                    showVideoPicker = true
                }
            }
        } else {
            showVideoPicker = true
        }
        #else
        showVideoPicker = true
        #endif
    }

    private func importVideo(from item: PhotosPickerItem) async {
        do {
            guard let picked = try await item.loadTransferable(type: PickedVideoFile.self) else {
                return
            }
            await MainActor.run {
                libraryVideos.append(picked.url)
                activeUploadURL = picked.url
            }
            await MainActor.run {
                pickerItem = nil
            }
        } catch {
            #if DEBUG
            print("Video import failed:", error.localizedDescription)
            #endif
            await MainActor.run {
                pickerItem = nil
            }
        }
    }
}

#Preview {
    ContentView()
}
