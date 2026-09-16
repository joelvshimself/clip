//
//  FallingClipsScene.swift
//  clip
//

import AVFoundation
import SpriteKit

final class FallingClipsScene: SKScene {
    var onSettled: (() -> Void)?

    private var clipNodes: [SKNode] = []
    private var spawnIndex = 0
    private var spawnTimer: TimeInterval = 0
    private let spawnInterval: TimeInterval = 0.15
    private let clipURLs: [URL]
    private var playfield: PlayfieldPadding
    private var settledNotified = false
    private var stableTime: TimeInterval = 0
    private let stableThreshold: TimeInterval = 1.5
    private let velocityEpsilon: CGFloat = 10
    private var sceneElapsed: TimeInterval = 0
    private let maxSceneDuration: TimeInterval = 8
    private var loopObservers: [NSObjectProtocol] = []
    private let gravityForceScale: CGFloat = 0.28
    private let gravityDeltaWakeThreshold: CGFloat = 0.03

    private var draggedClip: SKNode?
    private var dragOffset = CGPoint.zero
    private var isUserDragging = false
    private var lastDragLocation: CGPoint?
    private var lastDragTime: TimeInterval?
    private let maxThrowSpeed: CGFloat = 400

    init(size: CGSize, clipURLs: [URL], playfield: PlayfieldPadding) {
        self.clipURLs = clipURLs
        self.playfield = playfield
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
            playfield = ScreenMockup.playfieldPadding(for: size)
        }
        physicsWorld.gravity = DeviceTiltMonitor.shared.sceneGravity
        installBoundaries()

        if clipURLs.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self, !settledNotified else { return }
                settledNotified = true
                onSettled?()
            }
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        playfield = ScreenMockup.playfieldPadding(for: size)
        installBoundaries()
    }

    private func installBoundaries() {
        children.filter { $0.name == "boundary" }.forEach { $0.removeFromParent() }

        let minX = playfield.left
        let maxX = size.width - playfield.right
        let minY = playfield.bottom
        let maxY = size.height - playfield.top

        let floor = SKNode()
        floor.name = "boundary"
        floor.physicsBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: minX - 20, y: minY),
            to: CGPoint(x: maxX + 20, y: minY)
        )
        floor.physicsBody?.isDynamic = false
        floor.physicsBody?.friction = 0.42
        floor.physicsBody?.restitution = 0.08
        addChild(floor)

        let ceiling = SKNode()
        ceiling.name = "boundary"
        ceiling.physicsBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: minX - 20, y: maxY),
            to: CGPoint(x: maxX + 20, y: maxY)
        )
        ceiling.physicsBody?.isDynamic = false
        ceiling.physicsBody?.restitution = 0.05
        addChild(ceiling)

        let leftWall = SKNode()
        leftWall.name = "boundary"
        leftWall.physicsBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: minX, y: minY - 20),
            to: CGPoint(x: minX, y: maxY + 20)
        )
        leftWall.physicsBody?.isDynamic = false
        addChild(leftWall)

        let rightWall = SKNode()
        rightWall.name = "boundary"
        rightWall.physicsBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: maxX, y: minY - 20),
            to: CGPoint(x: maxX, y: maxY + 20)
        )
        rightWall.physicsBody?.isDynamic = false
        addChild(rightWall)
    }

    override func update(_ currentTime: TimeInterval) {
        let delta = 1.0 / 60.0
        sceneElapsed += delta

        let monitor = DeviceTiltMonitor.shared
        let gravity = monitor.sceneGravity
        physicsWorld.gravity = gravity
        applyDeviceGravityToClips(gravity: gravity, gravityDelta: monitor.gravityDelta)
        clampClipsToPlayfield()

        if spawnIndex < clipURLs.count {
            spawnTimer += delta
            if spawnTimer >= spawnInterval {
                spawnTimer = 0
                spawnClip(url: clipURLs[spawnIndex])
                spawnIndex += 1
            }
        }

        guard !settledNotified, spawnIndex >= clipURLs.count else { return }

        if isUserDragging {
            stableTime = 0
            return
        }

        if clipNodes.isEmpty {
            if sceneElapsed >= 2 {
                settledNotified = true
                onSettled?()
            }
            return
        }

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

    private func playfieldBounds() -> (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) {
        (
            playfield.left,
            size.width - playfield.right,
            playfield.bottom,
            size.height - playfield.top
        )
    }

    private func clampClipsToPlayfield() {
        let bounds = playfieldBounds()
        for node in clipNodes {
            if node === draggedClip { continue }
            guard let body = node.physicsBody else { continue }
            let halfW = node.calculateAccumulatedFrame().width / 2
            let halfH = node.calculateAccumulatedFrame().height / 2
            var pos = node.position
            let clampedX = min(max(pos.x, bounds.minX + halfW), bounds.maxX - halfW)
            let clampedY = min(max(pos.y, bounds.minY + halfH), bounds.maxY - halfH)
            if clampedX != pos.x || clampedY != pos.y {
                pos.x = clampedX
                pos.y = clampedY
                node.position = pos
                body.velocity = CGVector(
                    dx: body.velocity.dx * 0.35,
                    dy: body.velocity.dy * 0.35
                )
            }
        }
    }

    private func applyDeviceGravityToClips(gravity: CGVector, gravityDelta: CGFloat) {
        guard !clipNodes.isEmpty else { return }

        let gLength = hypot(gravity.dx, gravity.dy)
        guard gLength > 0.001 else { return }

        let dir = CGVector(dx: gravity.dx / gLength, dy: gravity.dy / gLength)
        let shouldWake = gravityDelta > gravityDeltaWakeThreshold

        for node in clipNodes {
            if node === draggedClip { continue }
            guard let body = node.physicsBody, body.isDynamic else { continue }

            let needsTiltAssist = body.isResting || shouldWake
            guard needsTiltAssist else { continue }

            if body.isResting, shouldWake {
                body.applyImpulse(CGVector(dx: dir.dx * 0.4, dy: dir.dy * 0.4))
            }

            let mass = body.mass
            body.applyForce(CGVector(
                dx: gravity.dx * mass * gravityForceScale,
                dy: gravity.dy * mass * gravityForceScale
            ))
        }
    }

    private func spawnClip(url: URL) {
        let clipSize = randomClipSize()
        let bounds = playfieldBounds()
        let minX = bounds.minX + clipSize.width / 2 + 4
        let maxX = bounds.maxX - clipSize.width / 2 - 4
        let x = CGFloat.random(in: minX...(max(minX, maxX)))
        let spawnY = bounds.maxY + clipSize.height * 0.55 + CGFloat(spawnIndex) * 10

        let container = SKNode()
        container.name = "fallingClip"
        container.position = CGPoint(x: x, y: spawnY)

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
        body.friction = 0.34
        body.restitution = 0.08
        body.linearDamping = 0.04
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

    // MARK: - Touch drag

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard draggedClip == nil, let touch = touches.first else { return }
        let location = touch.location(in: self)

        for node in nodes(at: location) {
            guard let container = clipContainer(for: node) else { continue }
            draggedClip = container
            dragOffset = CGPoint(x: container.position.x - location.x, y: container.position.y - location.y)
            isUserDragging = true
            stableTime = 0
            container.zPosition = 10

            if let body = container.physicsBody {
                body.isDynamic = false
                body.velocity = .zero
                body.angularVelocity = 0
            }

            lastDragLocation = location
            lastDragTime = touch.timestamp
            return
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let container = draggedClip else { return }
        let location = touch.location(in: self)
        let target = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
        container.position = clampedPosition(for: container, proposed: target)

        lastDragLocation = location
        lastDragTime = touch.timestamp
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endDrag(with: touches.first)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endDrag(with: touches.first)
    }

    private func endDrag(with touch: UITouch?) {
        guard let container = draggedClip else { return }

        var throwVelocity = CGVector.zero
        if let touch, let lastLocation = lastDragLocation, let lastTime = lastDragTime {
            let dt = max(0.016, touch.timestamp - lastTime)
            let current = touch.location(in: self)
            let vx = (current.x - lastLocation.x) / CGFloat(dt)
            let vy = (current.y - lastLocation.y) / CGFloat(dt)
            let speed = hypot(vx, vy)
            if speed > 8 {
                let cap = min(speed, maxThrowSpeed)
                let scale = cap / speed
                throwVelocity = CGVector(dx: vx * scale, dy: vy * scale)
            }
        }

        container.zPosition = 0
        if let body = container.physicsBody {
            body.isDynamic = true
            body.velocity = throwVelocity
        }

        draggedClip = nil
        isUserDragging = false
        lastDragLocation = nil
        lastDragTime = nil
        stableTime = 0
    }

    private func clipContainer(for node: SKNode) -> SKNode? {
        var current: SKNode? = node
        while let candidate = current {
            if candidate.name == "fallingClip", clipNodes.contains(where: { $0 === candidate }) {
                return candidate
            }
            current = candidate.parent
        }
        return nil
    }

    private func clampedPosition(for node: SKNode, proposed: CGPoint) -> CGPoint {
        let bounds = playfieldBounds()
        let halfW = node.calculateAccumulatedFrame().width / 2
        let halfH = node.calculateAccumulatedFrame().height / 2
        return CGPoint(
            x: min(max(proposed.x, bounds.minX + halfW), bounds.maxX - halfW),
            y: min(max(proposed.y, bounds.minY + halfH), bounds.maxY - halfH)
        )
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
