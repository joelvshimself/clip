//
//  LoadingCatPlacementPreview.swift
//  clip
//

import SwiftUI

struct LoadingCatPlacementContent: View {
    var containerWidth: CGFloat
    var previewImage: CGImage?
    var anchor: LoadingCatAnchor
    var topVariantIndex: Int
    var catOpacity: Double = 1
    var catPixelAmount: Double = 0
    var showTuningLabel: Bool = false
    var tuning: LoadingCatFineTune? = nil

    var body: some View {
        let videoWidth = containerWidth * LoadingCatPose.videoWidthFraction
        let videoHeight = videoWidth / LoadingCatPose.videoAspect
        let videoSize = CGSize(width: videoWidth, height: videoHeight)
        let catSize = LoadingCatPose.catSize(for: anchor, videoSize: videoSize)
        let tune = tuning ?? LoadingCatFineTune.fromStatic()
        let catOffset = LoadingCatPose.offset(
            for: anchor,
            videoSize: videoSize,
            catSize: catSize,
            topVariantIndex: topVariantIndex,
            tuning: tune
        )
        let assetName = LoadingCatPose.assetName(anchor: anchor, topVariantIndex: topVariantIndex)

        ZStack {
            Color.black.ignoresSafeArea()

            ZStack {
                videoPreview(
                    previewImage: previewImage,
                    width: videoWidth,
                    height: videoHeight
                )

                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: catSize.width, height: catSize.height)
                    .offset(x: catOffset.width, y: catOffset.height)
                    .opacity(catOpacity)
                    .layerEffect(
                        LoadingCatPixelation.shader(amount: catPixelAmount),
                        maxSampleOffset: LoadingCatPixelation.maxSampleOffset
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !showTuningLabel {
                Text("loading your clips, Darling")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 20)
            }

            if showTuningLabel {
                VStack(alignment: .leading, spacing: 4) {
                    Text(assetName)
                        .font(.caption.weight(.semibold))
                    Text(tune.label(anchor: anchor, topVariantIndex: topVariantIndex))
                        .font(.caption2.monospaced())
                        .foregroundStyle(.white.opacity(0.75))
                }
                .foregroundStyle(.white)
                .padding(10)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 6))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(12)
            }
        }
    }

    @ViewBuilder
    private func videoPreview(previewImage: CGImage?, width: CGFloat, height: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        UploadVideoLoadingPreviewView(previewImage: previewImage)
            .frame(width: width, height: height)
            .clipShape(shape)
            .overlay {
                shape.stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
    }
}

struct LoadingCatPlacementView: View {
    var anchor: LoadingCatAnchor
    var topVariantIndex: Int = 0
    var previewImage: CGImage? = nil

    @State private var tuning = LoadingCatFineTune.fromStatic()
    @State private var previewDown: Double = 0
    @State private var previewHorizontal: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                LoadingCatPlacementContent(
                    containerWidth: geometry.size.width,
                    previewImage: previewImage,
                    anchor: anchor,
                    topVariantIndex: topVariantIndex,
                    showTuningLabel: true,
                    tuning: liveTuning
                )
            }

            tuningSliderPanel
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(white: 0.12))
        }
        .onAppear {
            syncSlidersFromTuning()
        }
    }

    private var liveTuning: LoadingCatFineTune {
        var copy = tuning
        switch anchor {
        case .top:
            let i = topVariantIndex % LoadingCatPose.topVariantCount
            if copy.topDown.indices.contains(i) {
                copy.topDown[i] = CGFloat(previewDown)
            }
        case .left:
            copy.leftHorizontal = CGFloat(previewHorizontal)
        case .right:
            copy.rightHorizontal = CGFloat(previewHorizontal)
        }
        return copy
    }

    @ViewBuilder
    private var tuningSliderPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch anchor {
            case .top:
                sliderRow(
                    title: "Abajo (pt)",
                    value: $previewDown,
                    range: -40...120
                )
            case .left:
                sliderRow(
                    title: "Izquierda (pt)",
                    value: $previewHorizontal,
                    range: 0...120
                )
            case .right:
                sliderRow(
                    title: "Derecha (pt)",
                    value: $previewHorizontal,
                    range: 0...120
                )
            }
            Text(liveTuning.label(anchor: anchor, topVariantIndex: topVariantIndex))
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 100, alignment: .leading)
            Slider(value: value, in: range, step: 1)
            Text("\(Int(value.wrappedValue))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 36, alignment: .trailing)
        }
    }

    private func syncSlidersFromTuning() {
        switch anchor {
        case .top:
            let i = topVariantIndex % LoadingCatPose.topVariantCount
            previewDown = Double(tuning.topDown.indices.contains(i) ? tuning.topDown[i] : 0)
        case .left:
            previewHorizontal = Double(tuning.leftHorizontal)
        case .right:
            previewHorizontal = Double(tuning.rightHorizontal)
        }
    }
}

// MARK: - Tuning lab (all assets + copy snippet)

struct LoadingCatTuningLabView: View {
    var previewImage: CGImage? = nil

    @State private var tuning = LoadingCatFineTune.fromStatic()
    @State private var previewAnchor: LoadingCatAnchor = .top
    @State private var previewTopIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                LoadingCatPlacementContent(
                    containerWidth: geometry.size.width,
                    previewImage: previewImage,
                    anchor: previewAnchor,
                    topVariantIndex: previewTopIndex,
                    showTuningLabel: true,
                    tuning: tuning
                )
            }
            .frame(height: 340)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Ajusta cada asset — anota los valores y pégalos en el chat")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    ForEach(0..<LoadingCatPose.topVariantCount, id: \.self) { index in
                        topSliderRow(index: index)
                    }

                    sideSliderRow(
                        title: "LoadingCatLeft",
                        subtitle: "izquierda (pt)",
                        value: bindingLeftHorizontal,
                        range: 0...120,
                        onEditing: { previewAnchor = .left }
                    )

                    sideSliderRow(
                        title: "LoadingCatRight",
                        subtitle: "derecha (pt)",
                        value: bindingRightHorizontal,
                        range: 0...120,
                        onEditing: { previewAnchor = .right }
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Copiar a LoadingCatTuning")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                        Text(tuning.swiftSnippet)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.green.opacity(0.95))
                            .textSelection(.enabled)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(16)
            }
            .background(Color(white: 0.1))
        }
        .background(Color.black)
    }

    private func topSliderRow(index: Int) -> some View {
        HStack {
            Button {
                previewAnchor = .top
                previewTopIndex = index
            } label: {
                Text("LoadingCatTop\(index + 1)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(
                        previewAnchor == .top && previewTopIndex == index ? .yellow : .white
                    )
                    .frame(width: 118, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text("abajo")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 44, alignment: .leading)

            Slider(value: bindingTopDown(index), in: -40...120, step: 1)
            Text("\(Int(tuning.topDown[index]))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 32, alignment: .trailing)
        }
    }

    private func sideSliderRow(
        title: String,
        subtitle: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        onEditing: @escaping () -> Void
    ) -> some View {
        HStack {
            Button(action: onEditing) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 118, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 44, alignment: .leading)

            Slider(value: value, in: range, step: 1)
            Text("\(Int(value.wrappedValue))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 32, alignment: .trailing)
        }
    }

    private func bindingTopDown(_ index: Int) -> Binding<Double> {
        Binding(
            get: {
                guard tuning.topDown.indices.contains(index) else { return 0 }
                return Double(tuning.topDown[index])
            },
            set: { newValue in
                guard tuning.topDown.indices.contains(index) else { return }
                tuning.topDown[index] = CGFloat(newValue)
                previewAnchor = .top
                previewTopIndex = index
            }
        )
    }

    private var bindingLeftHorizontal: Binding<Double> {
        Binding(
            get: { Double(tuning.leftHorizontal) },
            set: { tuning.leftHorizontal = CGFloat($0) }
        )
    }

    private var bindingRightHorizontal: Binding<Double> {
        Binding(
            get: { Double(tuning.rightHorizontal) },
            set: { tuning.rightHorizontal = CGFloat($0) }
        )
    }
}

#Preview("LoadingCat Tuning Lab") {
    LoadingCatTuningLabView()
}

#Preview("LoadingCatTop1") {
    LoadingCatPlacementView(anchor: .top, topVariantIndex: 0)
}

#Preview("LoadingCatTop2") {
    LoadingCatPlacementView(anchor: .top, topVariantIndex: 1)
}

#Preview("LoadingCatTop3") {
    LoadingCatPlacementView(anchor: .top, topVariantIndex: 2)
}

#Preview("LoadingCatTop4") {
    LoadingCatPlacementView(anchor: .top, topVariantIndex: 3)
}

#Preview("LoadingCatTop5") {
    LoadingCatPlacementView(anchor: .top, topVariantIndex: 4)
}

#Preview("LoadingCatTop6") {
    LoadingCatPlacementView(anchor: .top, topVariantIndex: 5)
}

#Preview("LoadingCatTop7") {
    LoadingCatPlacementView(anchor: .top, topVariantIndex: 6)
}

#Preview("LoadingCatTop8") {
    LoadingCatPlacementView(anchor: .top, topVariantIndex: 7)
}

#Preview("LoadingCatLeft") {
    LoadingCatPlacementView(anchor: .left)
}

#Preview("LoadingCatRight") {
    LoadingCatPlacementView(anchor: .right)
}
