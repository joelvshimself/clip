//
//  HomeView.swift
//  clip
//

import Photos
import PhotosUI
import SwiftUI

struct HomeView: View {
    @Binding var libraryVideos: [URL]
    var onVideoUploaded: (URL) -> Void = { _ in }
    @State private var pickerItem: PhotosPickerItem?
    @State private var showVideoPicker = false

    private let addTileMarker = URL(fileURLWithPath: "/add-video-tile")

    var body: some View {
        ZStack {
            Color(white: 0.92)
                .ignoresSafeArea()

            if libraryVideos.isEmpty {
                emptyHome
            } else {
                filledHome
            }
        }
        .photosPicker(isPresented: $showVideoPicker, selection: $pickerItem, matching: .videos)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await importVideo(from: item) }
        }
    }

    private var emptyHome: some View {
        VStack(spacing: 28) {
            Text("Let the magic begin")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.top, 48)

            Spacer()

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(white: 0.55))
                .aspectRatio(0.72, contentMode: .fit)
                .overlay {
                    Text("{video}")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.black.opacity(0.85))
                }
                .padding(.horizontal, 36)

            Button(action: openVideoPicker) {
                Text("insert your video")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(white: 0.55), in: RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 48)
        }
    }

    private var filledHome: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                masonryGrid
                    .padding(.horizontal, 10)
                    .padding(.bottom, 24)
            }
        }
    }

    private var headerSection: some View {
        ZStack(alignment: .top) {
            if let first = libraryVideos.first {
                LoopingVideoView(url: first)
                    .frame(height: 220)
                    .clipped()
            } else {
                Color(white: 0.35)
                    .frame(height: 220)
            }

            Color.black.opacity(0.45)
                .frame(height: 220)

            VStack(alignment: .leading, spacing: 8) {
                Text("{Background}")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, 12)

                Spacer()

                HStack {
                    Text("Let the magic begin")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("V Filter")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.bottom, 12)
            }
            .frame(height: 220)
            .padding(.horizontal, 16)
        }
    }

    private var masonryGrid: some View {
        let columns = masonryColumns()
        return HStack(alignment: .top, spacing: 8) {
            ForEach(0..<3, id: \.self) { columnIndex in
                VStack(spacing: 8) {
                    ForEach(columns[columnIndex], id: \.self) { url in
                        if url == addTileMarker {
                            addVideoTile
                        } else {
                            videoTile(url: url)
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    private var addVideoTile: some View {
        Button(action: openVideoPicker) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(white: 0.78))
                .frame(height: 140)
                .overlay {
                    Text("+add a video")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .padding(8)
                }
        }
        .buttonStyle(.plain)
    }

    private func videoTile(url: URL) -> some View {
        LoopingVideoView(url: url)
            .frame(height: tileHeight(for: url))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            }
    }

    private func tileHeight(for url: URL) -> CGFloat {
        let hash = abs(url.absoluteString.hashValue)
        let options: [CGFloat] = [120, 150, 180, 210]
        return options[hash % options.count]
    }

    private func masonryColumns() -> [[URL]] {
        var columns: [[URL]] = [[], [], []]
        let items = libraryVideos + [addTileMarker]
        for (index, url) in items.enumerated() {
            columns[index % 3].append(url)
        }
        return columns
    }

    private func openVideoPicker() {
        #if os(iOS)
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
                DispatchQueue.main.async { showVideoPicker = true }
            }
        } else {
            showVideoPicker = true
        }
        #else
        showVideoPicker = true
        #endif
    }

    private func importVideo(from item: PhotosPickerItem) async {
        guard let picked = try? await item.loadTransferable(type: PickedVideoFile.self) else { return }
        await MainActor.run {
            libraryVideos.append(picked.url)
            pickerItem = nil
            onVideoUploaded(picked.url)
        }
    }
}
