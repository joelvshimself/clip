//
//  ContentView.swift
//  clip
//
//  Created by Joel on 15/09/26.
//

import AVFoundation
import CoreMotion
import SpriteKit
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Journey

private enum JourneyPhase: Equatable {
    case idle
    case blast
    case wait
    case rain
    case cta
}

private enum JourneyTiming {
    static let waitAfterExplosion: TimeInterval = 2
    static let waitAfterSettled: TimeInterval = 2
    static let catLaunchDuration: TimeInterval = 0.45
}

private enum FallingClipCatalog {
    static let resourceNames: [String] = [
        "clip01", "clip02", "clip03", "clip04", "clip05",
        "clip06", "clip07", "clip08", "clip09", "clip10",
    ]

    static func url(for resourceName: String) -> URL? {
        Bundle.main.url(forResource: resourceName, withExtension: "mp4", subdirectory: "Media/Clips")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "mp4")
    }

    static var urls: [URL] {
        resourceNames.compactMap { url(for: $0) }
    }

    static var explosionURL: URL? {
        Bundle.main.url(forResource: "explosion", withExtension: "mov", subdirectory: "Media")
            ?? Bundle.main.url(forResource: "explosion", withExtension: "mov")
    }
}

// MARK: - Reveal

private enum RevealArt {
    static let arribaAspect: CGFloat = 1302 / 1608
    static let abajoAspect: CGFloat = 2200 / 1608
    static let scrollContentMultiplier: CGFloat = 1.6
    static let manualOpenCap: CGFloat = 0.5
    static let snapThreshold: CGFloat = 0.92
    static let snapReleaseThreshold: CGFloat = 0.75
    static let snapDuration: TimeInterval = 0.7
    static let travelPadding: CGFloat = 48
}

struct ContentView: View {
    @State private var scrollProgress: CGFloat = 0
    @State private var isFullyOpen = false
    @State private var hintBounce = false
    @State private var journeyPhase: JourneyPhase = .idle
    @State private var catLaunched = false
    @State private var journeyStarted = false
    @State private var showFallingClips = false
    @State private var clipsSettled = false

    private var openAmount: CGFloat {
        isFullyOpen ? 1 : scrollProgress * RevealArt.manualOpenCap
    }

    private var journeyActive: Bool {
        journeyPhase != .idle
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let arribaHeight = width * RevealArt.arribaAspect
            let abajoHeight = width * RevealArt.abajoAspect
            let scrollRange = height * (RevealArt.scrollContentMultiplier - 1)

            ZStack {
                Color.black
                    .ignoresSafeArea()

                if journeyPhase == .blast, let explosionURL = FallingClipCatalog.explosionURL {
                    AlphaVideoPlayer(url: explosionURL) {
                        journeyPhase = .wait
                        scheduleRain(after: JourneyTiming.waitAfterExplosion)
                    }
                    .frame(width: width, height: height)
                    .clipped()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }

                if showFallingClips {
                    ScreenStageView(containerSize: CGSize(width: width, height: height)) {
                        handleClipsSettled()
                    }
                    .zIndex(0)
                    .transition(.opacity)
                }

                if journeyPhase == .idle || journeyPhase == .blast {
                    catView(width: width, height: height)
                }

                if !journeyActive {
                    Image("Arriba")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .offset(y: -openAmount * (arribaHeight + RevealArt.travelPadding))
                        .ignoresSafeArea(edges: .top)

                    Image("Abajo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .offset(y: openAmount * (abajoHeight + RevealArt.travelPadding))
                        .ignoresSafeArea(edges: .bottom)

                    scrollHint
                        .opacity(hintOpacity)
                        .allowsHitTesting(false)
                }

                if journeyPhase == .cta {
                    VStack {
                        Spacer()
                        JourneyCTAButton()
                            .padding(.bottom, 28)
                    }
                    .zIndex(10)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if !journeyActive {
                    ScrollView {
                        Color.clear
                            .frame(height: height * RevealArt.scrollContentMultiplier)
                    }
                    .scrollIndicators(.hidden)
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y + geometry.contentInsets.top
                    } action: { _, offset in
                        handleScroll(offset: offset, scrollRange: scrollRange)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: journeyPhase)
        .onChange(of: isFullyOpen) { _, open in
            if open, !journeyStarted {
                startJourney()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                hintBounce = true
            }
        }
    }

    @ViewBuilder
    private func catView(width: CGFloat, height: CGFloat) -> some View {
        Image("Cat")
            .resizable()
            .scaledToFit()
            .frame(
                maxWidth: width * 0.88,
                maxHeight: height * 0.78
            )
            .offset(y: catLaunched ? -height * 1.35 : 0)
            .scaleEffect(catLaunched ? 0.72 : 1)
            .opacity(catLaunched ? 0 : 1)
            .allowsHitTesting(false)
    }

    private var scrollHint: some View {
        VStack(spacing: 10) {
            Image(systemName: "chevron.down")
                .font(.title2.weight(.semibold))
                .offset(y: hintBounce ? 6 : -4)

            Text("Desliza para continuar")
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.black.opacity(0.35), in: Capsule())
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 36)
    }

    private var hintOpacity: Double {
        Double(max(0, 1 - scrollProgress * 2.5))
    }

    private func handleScroll(offset: CGFloat, scrollRange: CGFloat) {
        guard scrollRange > 0, !journeyStarted else { return }

        let rawProgress = min(max(offset / scrollRange, 0), 1)

        if rawProgress >= RevealArt.snapThreshold, !isFullyOpen {
            withAnimation(.easeIn(duration: RevealArt.snapDuration)) {
                isFullyOpen = true
            }
        } else if rawProgress < RevealArt.snapReleaseThreshold, isFullyOpen {
            isFullyOpen = false
        }

        scrollProgress = rawProgress
    }

    private func startJourney() {
        journeyStarted = true
        journeyPhase = .blast
        withAnimation(.easeOut(duration: JourneyTiming.catLaunchDuration)) {
            catLaunched = true
        }
    }

    private func scheduleRain(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard journeyPhase == .wait else { return }
            showFallingClips = true
            journeyPhase = .rain
        }
    }

    private func handleClipsSettled() {
        guard !clipsSettled else { return }
        clipsSettled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + JourneyTiming.waitAfterSettled) {
            guard journeyPhase == .rain else { return }
            journeyPhase = .cta
        }
    }
}

// MARK: - Alpha video

#if os(iOS)
private struct AlphaVideoPlayer: UIViewRepresentable {
    let url: URL
    var onFinished: (() -> Void)?

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.configure(url: url, coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    final class Coordinator: NSObject {
        var onFinished: (() -> Void)?
        private var endObserver: NSObjectProtocol?

        init(onFinished: (() -> Void)?) {
            self.onFinished = onFinished
        }

        func observeEnd(of item: AVPlayerItem, player: AVPlayer) {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.onFinished?()
            }
            player.play()
        }

        deinit {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }
    }

    final class PlayerUIView: UIView {
        private let playerLayer = AVPlayerLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.backgroundColor = UIColor.clear.cgColor
            layer.addSublayer(playerLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }

        func configure(url: URL, coordinator: Coordinator) {
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            player.actionAtItemEnd = .pause
            playerLayer.player = player
            coordinator.observeEnd(of: item, player: player)
        }
    }
}
#else
private struct AlphaVideoPlayer: View {
    let url: URL
    var onFinished: (() -> Void)?

    var body: some View {
        Color.clear
            .onAppear {
                onFinished?()
            }
    }
}
#endif

// MARK: - Screen mockup stage

private enum ScreenMockup {
    static let assetAspect: CGFloat = 1608.0 / 3496.0
    static let displayInsetTop: CGFloat = 0.128
    static let displayInsetBottom: CGFloat = 0.148
    static let displayInsetHorizontal: CGFloat = 0.09

    static func frameSize(in container: CGSize) -> CGSize {
        let heightFromWidth = container.width / assetAspect
        if heightFromWidth <= container.height {
            return CGSize(width: container.width, height: heightFromWidth)
        }
        return CGSize(width: container.height * assetAspect, height: container.height)
    }

    static func displaySize(for frame: CGSize) -> CGSize {
        let width = frame.width * (1 - displayInsetHorizontal * 2)
        let height = frame.height * (1 - displayInsetTop - displayInsetBottom)
        return CGSize(width: width, height: height)
    }

    static func displayCenter(in frame: CGSize) -> CGPoint {
        let display = displaySize(for: frame)
        let x = frame.width / 2
        let y = frame.height * displayInsetTop + display.height / 2
        return CGPoint(x: x, y: y)
    }
}

private struct ScreenStageView: View {
    let containerSize: CGSize
    var onSettled: () -> Void

    @State private var screenZoom: CGFloat = 1.22

    var body: some View {
        let frame = ScreenMockup.frameSize(in: containerSize)
        let display = ScreenMockup.displaySize(for: frame)
        let displayOffsetY = frame.height * (ScreenMockup.displayInsetTop - 0.5) + display.height / 2

        ZStack {
            FallingClipsView(size: display, floorPadding: 4) {
                onSettled()
            }
            .frame(width: display.width, height: display.height)
            .offset(y: displayOffsetY)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Image("Screen")
                .resizable()
                .frame(width: frame.width, height: frame.height)
                .allowsHitTesting(false)
        }
        .frame(width: frame.width, height: frame.height)
        .scaleEffect(screenZoom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                screenZoom = 1.0
            }
        }
    }
}

// MARK: - Device tilt

private final class DeviceTiltMonitor {
    static let shared = DeviceTiltMonitor()

    private let manager = CMMotionManager()
    private(set) var tilt = CGVector(dx: 0, dy: 0)
    private var smoothed = CGVector(dx: 0, dy: 0)

    func start() {
        #if os(iOS)
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let gravity = motion?.gravity else { return }
            let raw = CGVector(dx: CGFloat(gravity.x), dy: CGFloat(gravity.y))
            let blend: CGFloat = 0.18
            smoothed = CGVector(
                dx: smoothed.dx * (1 - blend) + raw.dx * blend,
                dy: smoothed.dy * (1 - blend) + raw.dy * blend
            )
            tilt = smoothed
        }
        #endif
    }

    func stop() {
        #if os(iOS)
        manager.stopDeviceMotionUpdates()
        #endif
    }
}

// MARK: - Falling clips

private struct FallingClipsView: View {
    let size: CGSize
    var floorPadding: CGFloat = 4
    var onSettled: () -> Void

    @State private var scene: FallingClipsScene?

    var body: some View {
        Group {
            if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .frame(width: size.width, height: size.height)
                    .allowsHitTesting(false)
            } else {
                Color.clear
                    .frame(width: size.width, height: size.height)
            }
        }
        .onAppear {
            guard scene == nil else { return }
            DeviceTiltMonitor.shared.start()
            let created = FallingClipsScene(
                size: size,
                clipURLs: FallingClipCatalog.urls,
                floorPadding: floorPadding
            )
            created.onSettled = onSettled
            scene = created
        }
        .onDisappear {
            DeviceTiltMonitor.shared.stop()
        }
    }
}

private final class FallingClipsScene: SKScene {
    var onSettled: (() -> Void)?

    private var clipNodes: [SKNode] = []
    private var spawnIndex = 0
    private var spawnTimer: TimeInterval = 0
    private let spawnInterval: TimeInterval = 0.15
    private let clipURLs: [URL]
    private let floorPadding: CGFloat
    private var settledNotified = false
    private var stableTime: TimeInterval = 0
    private let stableThreshold: TimeInterval = 1.5
    private let velocityEpsilon: CGFloat = 10
    private var sceneElapsed: TimeInterval = 0
    private let maxSceneDuration: TimeInterval = 8
    private var loopObservers: [NSObjectProtocol] = []
    private let baseGravity = CGVector(dx: 0, dy: -32)

    init(size: CGSize, clipURLs: [URL], floorPadding: CGFloat) {
        self.clipURLs = clipURLs
        self.floorPadding = floorPadding
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loopObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        if view.bounds.size.width > 0, view.bounds.size.height > 0 {
            size = view.bounds.size
        }
        physicsWorld.gravity = baseGravity
        installBoundaries()
    }

    override func willMove(from view: SKView) {
        DeviceTiltMonitor.shared.stop()
    }

    private func installBoundaries() {
        children.filter { $0.name == "boundary" }.forEach { $0.removeFromParent() }

        let floorY = floorPadding
        let floor = SKNode()
        floor.name = "boundary"
        floor.physicsBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: -40, y: floorY),
            to: CGPoint(x: size.width + 40, y: floorY)
        )
        floor.physicsBody?.isDynamic = false
        floor.physicsBody?.friction = 0.5
        floor.physicsBody?.restitution = 0.08
        addChild(floor)

        let leftWall = SKNode()
        leftWall.name = "boundary"
        leftWall.physicsBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: 3, y: 0),
            to: CGPoint(x: 3, y: size.height)
        )
        leftWall.physicsBody?.isDynamic = false
        addChild(leftWall)

        let rightWall = SKNode()
        rightWall.name = "boundary"
        rightWall.physicsBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: size.width - 3, y: 0),
            to: CGPoint(x: size.width - 3, y: size.height)
        )
        rightWall.physicsBody?.isDynamic = false
        addChild(rightWall)
    }

    override func update(_ currentTime: TimeInterval) {
        let delta = 1.0 / 60.0
        sceneElapsed += delta

        let tilt = DeviceTiltMonitor.shared.tilt
        physicsWorld.gravity = CGVector(
            dx: baseGravity.dx + tilt.dx * 14,
            dy: baseGravity.dy + tilt.dy * 10
        )

        if spawnIndex < clipURLs.count {
            spawnTimer += delta
            if spawnTimer >= spawnInterval {
                spawnTimer = 0
                spawnClip(url: clipURLs[spawnIndex])
                spawnIndex += 1
            }
        }

        guard !settledNotified, spawnIndex >= clipURLs.count else { return }

        let resting = clipNodes.filter { node in
            guard let body = node.physicsBody else { return true }
            return hypot(body.velocity.dx, body.velocity.dy) < velocityEpsilon
        }.count

        let majorityResting = resting >= max(1, clipNodes.count - 1)

        if majorityResting {
            stableTime += delta
            if stableTime >= stableThreshold || sceneElapsed >= maxSceneDuration {
                settledNotified = true
                onSettled?()
            }
        } else {
            stableTime = 0
        }
    }

    private func spawnClip(url: URL) {
        let clipSize = randomClipSize()
        let margin = clipSize.width / 2 + 10
        let x = CGFloat.random(in: margin...(max(margin, size.width - margin)))
        let y = size.height + clipSize.height * 0.6 + CGFloat(spawnIndex) * 14

        let container = SKNode()
        container.position = CGPoint(x: x, y: y)

        let player = AVPlayer(url: url)
        player.actionAtItemEnd = .pause
        let video = SKVideoNode(avPlayer: player)
        video.size = clipSize
        video.position = CGPoint.zero

        let crop = SKCropNode()
        let mask = SKShapeNode(rectOf: clipSize, cornerRadius: 14)
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask
        crop.addChild(video)
        container.addChild(crop)

        let body = SKPhysicsBody(rectangleOf: clipSize)
        body.isDynamic = true
        body.allowsRotation = true
        body.friction = 0.38
        body.restitution = 0.08
        body.linearDamping = 0.06
        body.angularDamping = 0.12
        body.mass = CGFloat.random(in: 0.85...1.35)
        body.usesPreciseCollisionDetection = true
        container.physicsBody = body

        addChild(container)
        player.play()
        attachLoopObserver(player: player)
        clipNodes.append(container)

        body.applyImpulse(CGVector(
            dx: CGFloat.random(in: -35...35),
            dy: CGFloat.random(in: -120 ... -80)
        ))
    }

    private func randomClipSize() -> CGSize {
        let width = CGFloat.random(in: 100...128)
        let height = width * 0.72
        return CGSize(width: width, height: height)
    }

    private func attachLoopObserver(player: AVPlayer) {
        guard let item = player.currentItem else { return }
        let observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
        loopObservers.append(observer)
    }
}

// MARK: - CTA

private struct JourneyCTAButton: View {
    var action: () -> Void = {}

    @State private var appeared = false

    var body: some View {
        Button(action: action) {
            Text("enter to the journey")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
        }
        .buttonStyle(.glass)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                appeared = true
            }
        }
    }
}

#Preview {
    ContentView()
}
