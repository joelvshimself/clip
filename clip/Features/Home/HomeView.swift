//
//  HomeView.swift
//  clip
//

import CoreGraphics
import SwiftUI

struct HomeView: View {
    @Binding var libraryVideos: [URL]
    var isVideoPickEnabled: Bool = true
    var isVideoHandoffActive: Bool = false
    var handoffPreviewImage: CGImage?
    var handoffVideoURL: URL?
    var onHandoffPreviewResolved: (CGImage) -> Void = { _ in }
    var onVideoHandoffFinished: () -> Void = {}
    var onRequestVideoPicker: () -> Void = {}

    private let addTileMarker = URL(fileURLWithPath: "/add-video-tile")

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if libraryVideos.isEmpty || isVideoHandoffActive {
                emptyHome
            } else {
                filledHome
            }
        }
    }

    private var emptyHome: some View {
        VStack(spacing: 20) {
            Text("Let the magic begin")
                .font(MagicBeginningTypography.titleFont)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            Group {
                if isVideoHandoffActive {
                    MagicBeginningHandoffView(
                        previewImage: handoffPreviewImage,
                        videoURL: handoffVideoURL,
                        onPreviewResolved: onHandoffPreviewResolved,
                        onFinished: onVideoHandoffFinished
                    )
                } else {
                    MagicBeginningHeroView()
                }
            }
            .padding(.horizontal, 12)

            Spacer(minLength: 8)

            PrimaryGlassButton(
                title: "insert your video",
                shape: .roundedRect(cornerRadius: 14),
                isEnabled: isVideoPickEnabled,
                action: onRequestVideoPicker
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 36)
            .padding(.bottom, 48)
            .opacity(isVideoHandoffActive ? 0 : 1)
            .allowsHitTesting(!isVideoHandoffActive)
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
        Button(action: onRequestVideoPicker) {
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
        .disabled(!isVideoPickEnabled)
        .opacity(isVideoPickEnabled ? 1 : 0.45)
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
}

#Preview("Home Empty") {
    @Previewable @State var videos: [URL] = []
    HomeView(libraryVideos: $videos)
}

#Preview("Home Filled") {
    @Previewable @State var videos: [URL] = FallingClipCatalog.urls
    HomeView(libraryVideos: $videos)
}
