//
//  ContentView.swift
//  clip
//

import CoreGraphics
import Photos
import PhotosUI
import SwiftUI

struct ContentView: View {
    @State private var journeyPhase: JourneyPhase = .idle
    @State private var libraryVideos: [LibraryVideoItem] = []
    @State private var activeUploadPreviewImage: CGImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showVideoPicker = false
    @State private var isUploadSessionActive = false
    @State private var isVideoHandoffActive = false
    @State private var uploadSessionID = UUID()

    private var isVideoPickEnabled: Bool {
        !isUploadSessionActive && !isVideoHandoffActive
    }

    var body: some View {
        rootScene
            .onChange(of: journeyPhase) { _, phase in
                if phase == .home {
                    JourneyAudio.stopAll()
                }
            }
            .photosPicker(
                isPresented: $showVideoPicker,
                selection: $pickerItem,
                matching: .videos,
                photoLibrary: .shared()
            )
            .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            guard isVideoPickEnabled else {
                pickerItem = nil
                return
            }
            pickerItem = nil
            uploadSessionID = UUID()
            isUploadSessionActive = false
            isVideoHandoffActive = true
            activeUploadPreviewImage = nil
            Task {
                await importVideoPoster(from: item)
            }
        }
    }

    @ViewBuilder
    private var rootScene: some View {
        if journeyPhase != .home {
            JourneyRootView(journeyPhase: $journeyPhase)
        } else if isUploadSessionActive {
            UploadPipelineView(
                previewImage: activeUploadPreviewImage,
                onContinueEditing: endUploadSession,
                onSave: endUploadSession
            )
            .id(uploadSessionID)
        } else {
            HomeView(
                libraryVideos: $libraryVideos,
                isVideoPickEnabled: isVideoPickEnabled,
                isVideoHandoffActive: isVideoHandoffActive,
                handoffPreviewImage: activeUploadPreviewImage,
                onHandoffPreviewResolved: handleHandoffPreviewResolved,
                onVideoHandoffFinished: completeVideoHandoff,
                onRequestVideoPicker: requestVideoPicker
            )
        }
    }

    private func handleHandoffPreviewResolved(_ image: CGImage) {
        if activeUploadPreviewImage == nil {
            activeUploadPreviewImage = image
        }
    }

    private func completeVideoHandoff() {
        guard isVideoHandoffActive else { return }
        if let image = activeUploadPreviewImage {
            libraryVideos.append(LibraryVideoItem(posterImage: image))
        }
        isVideoHandoffActive = false
        isUploadSessionActive = true
    }

    private func endUploadSession() {
        activeUploadPreviewImage = nil
        isUploadSessionActive = false
        isVideoHandoffActive = false
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

    private func importVideoPoster(from item: PhotosPickerItem) async {
        guard let image = await VideoPosterFrameLoader.loadPreview(from: item) else {
            await MainActor.run {
                cancelVideoHandoff()
            }
            return
        }

        await MainActor.run {
            activeUploadPreviewImage = image
        }
    }

    private func cancelVideoHandoff() {
        isVideoHandoffActive = false
        activeUploadPreviewImage = nil
        isUploadSessionActive = false
    }
}

#Preview {
    ContentView()
}
