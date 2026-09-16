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
    @State private var activeUploadPreviewImage: CGImage?
    @State private var pendingPersistSourceURL: URL?
    @State private var persistTaskStarted = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showVideoPicker = false
    @State private var isUploadSessionActive = false
    @State private var uploadSessionID = UUID()

    private var isVideoPickEnabled: Bool {
        !isUploadSessionActive
    }

    var body: some View {
        Group {
            if journeyPhase != .home {
                JourneyRootView(journeyPhase: $journeyPhase)
            } else if isUploadSessionActive {
                UploadPipelineView(
                    videoURL: activeUploadURL,
                    previewImage: activeUploadPreviewImage,
                    onEnterExporting: startDeferredPersistIfNeeded,
                    onContinueEditing: endUploadSession,
                    onSave: endUploadSession
                )
                .id(uploadSessionID)
            } else {
                HomeView(
                    libraryVideos: $libraryVideos,
                    isVideoPickEnabled: isVideoPickEnabled,
                    onRequestVideoPicker: requestVideoPicker
                )
            }
        }
        .photosPicker(isPresented: $showVideoPicker, selection: $pickerItem, matching: .videos)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            guard isVideoPickEnabled else {
                pickerItem = nil
                return
            }
            pickerItem = nil
            uploadSessionID = UUID()
            isUploadSessionActive = true
            persistTaskStarted = false
            pendingPersistSourceURL = nil
            activeUploadPreviewImage = nil
            activeUploadURL = nil
            Task {
                await importVideo(from: item)
            }
        }
    }

    private func endUploadSession() {
        activeUploadURL = nil
        activeUploadPreviewImage = nil
        pendingPersistSourceURL = nil
        persistTaskStarted = false
        isUploadSessionActive = false
    }

    private func requestVideoPicker() {
        guard isVideoPickEnabled else { return }

        #if os(iOS)
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    guard isVideoPickEnabled else { return }
                    if newStatus == .authorized || newStatus == .limited {
                        showVideoPicker = true
                    }
                }
            }
        case .authorized, .limited:
            showVideoPicker = true
        case .denied, .restricted:
            #if DEBUG
            print("Photo library access denied or restricted")
            #endif
        @unknown default:
            break
        }
        #else
        showVideoPicker = true
        #endif
    }

    private func startDeferredPersistIfNeeded() {
        guard !persistTaskStarted, let sourceURL = pendingPersistSourceURL else { return }
        persistTaskStarted = true
        pendingPersistSourceURL = nil

        Task.detached(priority: .utility) {
            do {
                let persisted = try VideoImportService.persistToTemporaryLibrary(from: sourceURL)
                await MainActor.run {
                    guard isUploadSessionActive else { return }
                    if let index = libraryVideos.firstIndex(of: sourceURL) {
                        libraryVideos[index] = persisted
                    }
                    if activeUploadURL == sourceURL {
                        activeUploadURL = persisted
                    }
                }
            } catch {
                #if DEBUG
                print("Deferred video persist failed:", error.localizedDescription)
                #endif
            }
        }
    }

    private func importVideo(from item: PhotosPickerItem) async {
        let thumbnailTask = Task {
            await UploadVideoThumbnailLoader.loadPreview(from: item)
        }

        Task { @MainActor in
            if let image = await thumbnailTask.value {
                activeUploadPreviewImage = image
            }
        }

        do {
            guard let picked = try await item.loadTransferable(type: PickedVideoFile.self) else {
                await MainActor.run {
                    endUploadSession()
                }
                return
            }

            let sessionURL = picked.url
            await MainActor.run {
                if activeUploadURL == nil {
                    activeUploadURL = sessionURL
                    pendingPersistSourceURL = sessionURL
                    libraryVideos.append(sessionURL)
                }
            }
        } catch {
            #if DEBUG
            print("Video import failed:", error.localizedDescription)
            #endif
            await MainActor.run {
                endUploadSession()
            }
        }
    }
}

#Preview {
    ContentView()
}
