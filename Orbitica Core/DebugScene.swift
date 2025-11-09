//
//  DebugScene.swift
//  Orbitica Core
//
//  Debug scene per selezionare la wave di partenza
//

import SpriteKit

class DebugScene: SKScene {
    
    // Wave selector
    private var selectedWave: Int = 1
    private var waveLabel: SKLabelNode!
    private var playButton: SKShapeNode!
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // Titolo
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "WAVE SELECTOR"
        title.fontSize = 32
        title.fontColor = .cyan
        title.position = CGPoint(x: size.width / 2, y: size.height - 100)
        title.zPosition = 100
        addChild(title)
        
        // Istruzioni
        let instructions = SKLabelNode(fontNamed: "Courier")
        instructions.text = "Select starting wave"
        instructions.fontSize = 18
        instructions.fontColor = .white
        instructions.alpha = 0.7
        instructions.position = CGPoint(x: size.width / 2, y: size.height - 150)
        instructions.zPosition = 100
        addChild(instructions)
        
        // Wave selector UI
        createWaveSelector()
        
        // Play button
        createPlayButton()
        
        // Close button
        createCloseButton()
    }
    
    private func createWaveSelector() {
        // Pulsante decrement (-) 
        let decrementButton = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 10)
        decrementButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        decrementButton.strokeColor = .white
        decrementButton.lineWidth = 2
        decrementButton.position = CGPoint(x: size.width / 2 - 120, y: size.height / 2)
        decrementButton.name = "decrement"
        decrementButton.zPosition = 100
        addChild(decrementButton)
        
        let minusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        minusLabel.text = "-"
        minusLabel.fontSize = 36
        minusLabel.fontColor = .white
        minusLabel.verticalAlignmentMode = .center
        decrementButton.addChild(minusLabel)
        
        // Wave number display
        waveLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        waveLabel.text = "\(selectedWave)"
        waveLabel.fontSize = 72
        waveLabel.fontColor = .cyan
        waveLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        waveLabel.verticalAlignmentMode = .center
        waveLabel.zPosition = 100
        addChild(waveLabel)
        
        // Pulsante increment (+)
        let incrementButton = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 10)
        incrementButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        incrementButton.strokeColor = .white
        incrementButton.lineWidth = 2
        incrementButton.position = CGPoint(x: size.width / 2 + 120, y: size.height / 2)
        incrementButton.name = "increment"
        incrementButton.zPosition = 100
        addChild(incrementButton)
        
        let plusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        plusLabel.text = "+"
        plusLabel.fontSize = 36
        plusLabel.fontColor = .white
        plusLabel.verticalAlignmentMode = .center
        incrementButton.addChild(plusLabel)
    }
    
    private func createPlayButton() {
        playButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 15)
        playButton.fillColor = UIColor.green.withAlphaComponent(0.3)
        playButton.strokeColor = .green
        playButton.lineWidth = 3
        playButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 150)
        playButton.name = "play"
        playButton.zPosition = 100
        addChild(playButton)
        
        let playLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        playLabel.text = "PLAY"
        playLabel.fontSize = 28
        playLabel.fontColor = .green
        playLabel.verticalAlignmentMode = .center
        playButton.addChild(playLabel)
        
        // Animazione pulse
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.6),
            SKAction.scale(to: 1.0, duration: 0.6)
        ])
        playButton.run(SKAction.repeatForever(pulse))
    }
    
    // MARK: - Close Button
    
    enum SquareAsteroidSize: Int {
        case large = 2
        case medium = 1
        case small = 0
        
        var sideLength: CGFloat {
            switch self {
            case .large: return 60
            case .medium: return 40
            case .small: return 20
            }
        }
    }
    
    private func createSquareAsteroid(at position: CGPoint, size: SquareAsteroidSize) {
        let sideLength = size.sideLength
        let asteroid = SKShapeNode(rectOf: CGSize(width: sideLength, height: sideLength))
        asteroid.fillColor = UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0)  // Arancione PIENO
        asteroid.strokeColor = UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)  // Bordo più chiaro
        asteroid.lineWidth = 2
        asteroid.position = position
        asteroid.zPosition = 50
        asteroid.name = "square_asteroid_\(size.rawValue)"
        
        // Physics body
        asteroid.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: sideLength, height: sideLength))
        asteroid.physicsBody?.isDynamic = true
        asteroid.physicsBody?.mass = CGFloat(size.rawValue + 1) * 2.0
        asteroid.physicsBody?.linearDamping = 0
        asteroid.physicsBody?.angularDamping = 0.5
        asteroid.physicsBody?.restitution = 0.8
        asteroid.physicsBody?.categoryBitMask = 2
        asteroid.physicsBody?.collisionBitMask = 1 | 2
        asteroid.physicsBody?.contactTestBitMask = 1
        
        // Velocità iniziale casuale
        let angle = CGFloat.random(in: CGFloat(0)...(.pi * 2))
        let speed: CGFloat = 50
        asteroid.physicsBody?.velocity = CGVector(
            dx: cos(angle) * speed,
            dy: sin(angle) * speed
        )
        
        worldLayer.addChild(asteroid)
        squareAsteroids.append(asteroid)
        
        // Programma cambi di direzione randomici ogni ~10 secondi
        scheduleDirectionChange(for: asteroid)
        
        // Effetto metallico shine
        addMetallicShineEffect(to: asteroid, size: size)
    }
    
    private func scheduleDirectionChange(for asteroid: SKShapeNode) {
        let randomDelay = TimeInterval.random(in: Double(8)...Double(12))
        
        print("⏰ Next jet scheduled in \(String(format: "%.1f", randomDelay))s for asteroid at \(asteroid.position)")
        
        let wait = SKAction.wait(forDuration: randomDelay)
        let change = SKAction.run { [weak self, weak asteroid] in
            guard let self = self, let asteroid = asteroid else { return }
            self.applyRandomJet(to: asteroid)
            
            // Riprogramma il prossimo cambio
            self.scheduleDirectionChange(for: asteroid)
        }
        
        let sequence = SKAction.sequence([wait, change])
        asteroid.run(sequence, withKey: "directionChange")
    }
    
    private func applyRandomJet(to asteroid: SKShapeNode) {
        guard let body = asteroid.physicsBody else { return }
        
        // Direzione casuale
        let angle = CGFloat.random(in: CGFloat(0)...(.pi * 2))
        
        // MODIFICA GRADUALE DELLA VELOCITÀ invece di impulso
        let jetSpeed: CGFloat = 80  // Velocità aggiunta
        
        let currentVelocity = body.velocity
        let addedVelocity = CGVector(
            dx: cos(angle) * jetSpeed,
            dy: sin(angle) * jetSpeed
        )
        
        // Nuova velocità = corrente + aggiunta
        let newVelocity = CGVector(
            dx: currentVelocity.dx + addedVelocity.dx,
            dy: currentVelocity.dy + addedVelocity.dy
        )
        
        body.velocity = newVelocity
        
        // Effetto visivo: particelle nella direzione opposta (come freno)
        createJetParticles(at: asteroid.position, direction: angle + .pi, parent: asteroid)
        
        // DEBUG LOG PIÙ VISIBILE
        print("💨💨💨 JET APPLIED! Square asteroid at position \(asteroid.position), angle \(Int(angle * 180 / .pi))°, new velocity: \(newVelocity)")
    }
    
    private func createJetParticles(at position: CGPoint, direction: CGFloat, parent: SKNode) {
        guard let texture = particleTexture else { return }
        
        let emitter = SKEmitterNode()
        emitter.particleTexture = texture
        emitter.particleSize = CGSize(width: 4, height: 4)
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 30
        emitter.particleLifetime = 0.5
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -1.5
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 50
        emitter.emissionAngle = direction
        emitter.emissionAngleRange = .pi / 6
        emitter.particleColor = UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.position = .zero  // Relativo al parent
        emitter.zPosition = -1
        emitter.targetNode = worldLayer  // Particelle rimangono nel world
        
        parent.addChild(emitter)
        
        // Rimuovi emitter dopo l'emissione
        let wait = SKAction.wait(forDuration: 1.0)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }
    
    private func createParticleTexture() -> SKTexture {
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }
    
    // MARK: - Metallic Shine Effect
    
    private func addMetallicShineEffect(to asteroid: SKShapeNode, size: SquareAsteroidSize) {
        // Solo effetto shimmer sottile, niente glow pulse brutto
        scheduleMetallicShine(for: asteroid, size: size)
    }
    
    private func scheduleMetallicShine(for asteroid: SKShapeNode, size: SquareAsteroidSize) {
        let randomDelay = TimeInterval.random(in: 2.0...3.5)
        
        let wait = SKAction.wait(forDuration: randomDelay)
        let shine = SKAction.run { [weak self, weak asteroid] in
            guard let self = self, let asteroid = asteroid else { return }
            self.createShineEffect(on: asteroid, size: size)
            
            // Riprogramma il prossimo shine
            self.scheduleMetallicShine(for: asteroid, size: size)
        }
        
        let sequence = SKAction.sequence([wait, shine])
        asteroid.run(sequence, withKey: "metallicShine")
    }
    
    private func createShineEffect(on asteroid: SKShapeNode, size: SquareAsteroidSize) {
        let sideLength = CGFloat(size.rawValue)
        
        // Edge highlighting progressivo
        let effectContainer = SKNode()
        effectContainer.zPosition = 2
        asteroid.addChild(effectContainer)
        
        let edgeWidth: CGFloat = 3.0
        let edgeColor = UIColor.white
        
        let leftEdge = SKShapeNode(rectOf: CGSize(width: edgeWidth, height: sideLength))
        leftEdge.fillColor = edgeColor
        leftEdge.strokeColor = .clear
        leftEdge.position = CGPoint(x: -sideLength / 2, y: 0)
        leftEdge.alpha = 0
        leftEdge.blendMode = .add
        effectContainer.addChild(leftEdge)
        
        let topEdge = SKShapeNode(rectOf: CGSize(width: sideLength, height: edgeWidth))
        topEdge.fillColor = edgeColor
        topEdge.strokeColor = .clear
        topEdge.position = CGPoint(x: 0, y: sideLength / 2)
        topEdge.alpha = 0
        topEdge.blendMode = .add
        effectContainer.addChild(topEdge)
        
        let rightEdge = SKShapeNode(rectOf: CGSize(width: edgeWidth, height: sideLength))
        rightEdge.fillColor = edgeColor
        rightEdge.strokeColor = .clear
        rightEdge.position = CGPoint(x: sideLength / 2, y: 0)
        rightEdge.alpha = 0
        rightEdge.blendMode = .add
        effectContainer.addChild(rightEdge)
        
        let bottomEdge = SKShapeNode(rectOf: CGSize(width: sideLength, height: edgeWidth))
        bottomEdge.fillColor = edgeColor
        bottomEdge.strokeColor = .clear
        bottomEdge.position = CGPoint(x: 0, y: -sideLength / 2)
        bottomEdge.alpha = 0
        bottomEdge.blendMode = .add
        effectContainer.addChild(bottomEdge)
        
        let duration: TimeInterval = 0.7
        let edgeDelay: TimeInterval = 0.12
        
        let illuminateLeft = SKAction.fadeAlpha(to: 0.9, duration: 0.15)
        leftEdge.run(SKAction.sequence([SKAction.wait(forDuration: 0), illuminateLeft]))
        topEdge.run(SKAction.sequence([SKAction.wait(forDuration: edgeDelay), illuminateLeft]))
        rightEdge.run(SKAction.sequence([SKAction.wait(forDuration: edgeDelay * 2), illuminateLeft]))
        bottomEdge.run(SKAction.sequence([SKAction.wait(forDuration: edgeDelay * 3), illuminateLeft]))
        
        let fadeOutDelay = edgeDelay * 3 + 0.3
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: fadeOutDelay),
            SKAction.fadeOut(withDuration: 0.2)
        ])
        leftEdge.run(fadeOut)
        topEdge.run(fadeOut)
        rightEdge.run(fadeOut)
        bottomEdge.run(fadeOut)
        
        let originalColor = asteroid.fillColor
        let brighten1 = SKAction.run { [weak asteroid] in
            asteroid?.fillColor = UIColor(red: 1.0, green: 0.75, blue: 0.35, alpha: 1.0)
        }
        let brighten2 = SKAction.run { [weak asteroid] in
            asteroid?.fillColor = UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
        }
        let restore = SKAction.run { [weak asteroid] in
            asteroid?.fillColor = originalColor
        }
        
        let pulseSequence = SKAction.sequence([
            SKAction.wait(forDuration: edgeDelay * 2),
            brighten1,
            SKAction.wait(forDuration: 0.15),
            brighten2,
            SKAction.wait(forDuration: 0.15),
            restore
        ])
        asteroid.run(pulseSequence)
        
        let cleanup = SKAction.sequence([
            SKAction.wait(forDuration: duration + 0.3),
            SKAction.removeFromParent()
        ])
        effectContainer.run(cleanup)
    }
    
    // MARK: - Update
    
    override func update(_ currentTime: TimeInterval) {
        // Applica gravità
        for asteroid in squareAsteroids {
            if let body = asteroid.physicsBody {
                applyGravity(to: asteroid, body: body)
            }
        }
        
        // Limita velocità
        for asteroid in squareAsteroids {
            limitSpeed(of: asteroid)
        }
        
        // WRAP AROUND - se escono dai bordi, riappaiono dall'altra parte
        for asteroid in squareAsteroids {
            wrapAround(asteroid)
        }
    }
    
    private func wrapAround(_ asteroid: SKShapeNode) {
        // Considera lo zoom della camera (2x = area visibile 2x più grande)
        let visibleWidth = size.width * 2.0  // Con zoom 2.0
        let visibleHeight = size.height * 2.0
        
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        let minX = centerX - visibleWidth / 2
        let maxX = centerX + visibleWidth / 2
        let minY = centerY - visibleHeight / 2
        let maxY = centerY + visibleHeight / 2
        
        // Wrap orizzontale
        if asteroid.position.x < minX {
            asteroid.position.x = maxX
        } else if asteroid.position.x > maxX {
            asteroid.position.x = minX
        }
        
        // Wrap verticale
        if asteroid.position.y < minY {
            asteroid.position.y = maxY
        } else if asteroid.position.y > maxY {
            asteroid.position.y = minY
        }
    }
    
    private func applyGravity(to node: SKNode, body: SKPhysicsBody) {
        let dx = planet.position.x - node.position.x
        let dy = planet.position.y - node.position.y
        let distanceSquared = dx * dx + dy * dy
        let distance = sqrt(distanceSquared)
        
        guard distance > planetRadius else { return }
        
        let force = gravitationalConstant * planetMass * body.mass / distanceSquared
        let forceX = (dx / distance) * force
        let forceY = (dy / distance) * force
        
        body.applyForce(CGVector(dx: forceX, dy: forceY))
    }
    
    private func limitSpeed(of asteroid: SKShapeNode) {
        guard let body = asteroid.physicsBody else { return }
        
        let maxSpeed: CGFloat = 200
        let velocity = body.velocity
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        
        if speed > maxSpeed {
            let factor = maxSpeed / speed
            body.velocity = CGVector(
                dx: velocity.dx * factor,
                dy: velocity.dy * factor
            )
        }
    }
    
    // MARK: - Physics Contact
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA.node
        let bodyB = contact.bodyB.node
        
        // Collisione con pianeta
        if (bodyA == planet && bodyB?.name?.hasPrefix("square_asteroid") == true) ||
           (bodyB == planet && bodyA?.name?.hasPrefix("square_asteroid") == true) {
            let asteroid = (bodyA == planet) ? bodyB : bodyA
            if let squareAsteroid = asteroid as? SKShapeNode {
                fragmentSquareAsteroid(squareAsteroid)
            }
        }
    }
    
    private func fragmentSquareAsteroid(_ asteroid: SKShapeNode) {
        guard let sizeString = asteroid.name?.split(separator: "_").last,
              let sizeRaw = Int(String(sizeString)),
              let size = SquareAsteroidSize(rawValue: sizeRaw) else { return }
        
        let position = asteroid.position
        let velocity = asteroid.physicsBody?.velocity ?? .zero
        
        // Rimuovi asteroide originale
        asteroid.removeAllActions()
        asteroid.removeFromParent()
        squareAsteroids.removeAll { $0 == asteroid }
        
        // Se non è small, crea frammenti
        if size != .small {
            let nextSize: SquareAsteroidSize = (size == .large) ? .medium : .small
            let fragmentCount = 4  // 4 frammenti quadrati
            
            for i in 0..<fragmentCount {
                let angle = (CGFloat(i) / CGFloat(fragmentCount)) * 2 * .pi
                
                let offset = CGPoint(
                    x: cos(angle) * size.sideLength * 0.4,
                    y: sin(angle) * size.sideLength * 0.4
                )
                
                let fragmentPosition = CGPoint(
                    x: position.x + offset.x,
                    y: position.y + offset.y
                )
                
                createSquareAsteroid(at: fragmentPosition, size: nextSize)
                
                // Applica velocità ereditata + velocità di esplosione
                if let fragment = squareAsteroids.last {
                    let explosionSpeed: CGFloat = 60
                    let inheritedVelocity = CGVector(
                        dx: velocity.dx * 0.5 + cos(angle) * explosionSpeed,
                        dy: velocity.dy * 0.5 + sin(angle) * explosionSpeed
                    )
                    fragment.physicsBody?.velocity = inheritedVelocity
                }
            }
        }
    }
    
    // MARK: - Close Button
    
    private func createCloseButton() {
        let closeButton = SKShapeNode(circleOfRadius: 20)
        closeButton.fillColor = UIColor.red.withAlphaComponent(0.3)
        closeButton.strokeColor = .red
        closeButton.lineWidth = 2
        // Posizione relativa alla camera (angolo alto-destra)
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        closeButton.position = CGPoint(x: halfWidth - 40, y: halfHeight - 40)
        closeButton.name = "closeButton"
        closeButton.zPosition = 1000
        
        let xLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        xLabel.text = "X"
        xLabel.fontSize = 20
        xLabel.fontColor = .red
        xLabel.verticalAlignmentMode = .center
        xLabel.horizontalAlignmentMode = .center
        closeButton.addChild(xLabel)
        
        // Aggiungi al HUD layer (immune allo zoom)
        hudLayer.addChild(closeButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "closeButton" {
                // Torna al menu principale
                let transition = SKTransition.fade(withDuration: 0.5)
                let menuScene = MainMenuScene(size: size)
                menuScene.scaleMode = .aspectFill
                view?.presentScene(menuScene, transition: transition)
                return
            }
        }
    }
}
