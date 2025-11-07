//
//  GameScene.swift
//  Orbitica Core - GRAVITY SHIELD
//
//  Created by Alessandro Grassi on 07/11/25.
//

import SpriteKit
import GameplayKit

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none: UInt32 = 0
    static let planet: UInt32 = 0b1        // 1
    static let atmosphere: UInt32 = 0b10   // 2
    static let player: UInt32 = 0b100      // 4
    static let asteroid: UInt32 = 0b1000   // 8
    static let projectile: UInt32 = 0b10000 // 16
}

// MARK: - Asteroid Size
enum AsteroidSize: Int {
    case large = 3
    case medium = 2
    case small = 1
    
    var radius: CGFloat {
        switch self {
        case .large: return 35
        case .medium: return 22
        case .small: return 12
        }
    }
    
    var mass: CGFloat {
        switch self {
        case .large: return 0.8
        case .medium: return 0.5
        case .small: return 0.3
        }
    }
}

// MARK: - Game Scene
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Player
    private var player: SKShapeNode!
    private var playerShield: SKShapeNode!  // Barriera circolare
    private var thrusterGlow: SKShapeNode!
    
    // Planet & Atmosphere
    private var planet: SKShapeNode!
    private var atmosphere: SKShapeNode!
    private var atmosphereRadius: CGFloat = 80
    private let maxAtmosphereRadius: CGFloat = 80
    private let minAtmosphereRadius: CGFloat = 40
    
    // Physics constants
    private let planetRadius: CGFloat = 40
    private let planetMass: CGFloat = 10000
    private let gravitationalConstant: CGFloat = 80
    
    // Camera & Layers
    private var gameCamera: SKCameraNode!
    private var worldLayer: SKNode!
    private var hudLayer: SKNode!
    
    // Controls
    private var joystick: JoystickNode!
    private var fireButton: FireButtonNode!
    private var joystickDirection = CGVector.zero
    private var isFiring = false
    private var lastFireTime: TimeInterval = 0
    private let fireRate: TimeInterval = 0.15
    
    // Projectiles
    private var projectiles: [SKShapeNode] = []
    
    // Asteroids
    private var asteroids: [SKShapeNode] = []
    private var lastAsteroidSpawnTime: TimeInterval = 0
    private let asteroidSpawnInterval: TimeInterval = 3.0  // Ogni 3 secondi
    
    // Wave system
    private var currentWave: Int = 0
    private var isWaveActive: Bool = false
    private var asteroidsToSpawnInWave: Int = 0
    private var asteroidsSpawnedInWave: Int = 0
    
    // Collision tracking
    private var lastCollisionTime: TimeInterval = 0
    private let collisionCooldown: TimeInterval = 0.5  // 500ms tra collisioni
    
    // Score
    private var score: Int = 0
    private var scoreLabel: SKLabelNode!
    
    // MARK: - Setup
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // FISICA: Configura la fisica della scena
        physicsWorld.gravity = .zero  // Niente gravità di default, la applichiamo manualmente
        physicsWorld.contactDelegate = self
        
        print("=== GRAVITY SHIELD ===")
        print("Scene size: \(size)")
        print("======================")
        
        setupLayers()
        setupCamera()
        setupPlanet()
        setupAtmosphere()
        setupPlayer()
        setupControls()
        setupScore()
        
        // Avvia Wave 1
        startWave(1)
    }
    
    private func setupLayers() {
        // World layer: contiene tutti gli oggetti di gioco (player, pianeta, asteroidi, etc)
        // Posizionato al centro della scena - le coordinate del world sono relative al centro
        worldLayer = SKNode()
        worldLayer.position = .zero  // Nessun offset, usiamo coordinate assolute
        addChild(worldLayer)
        
        // HUD layer: contiene UI (joystick, pulsanti) - sempre in primo piano
        hudLayer = SKNode()
        addChild(hudLayer)
        
        print("✅ Layers created: worldLayer, hudLayer")
    }
    
    private func setupCamera() {
        // Camera fissa al centro del mondo (dove sarà il pianeta)
        gameCamera = SKCameraNode()
        gameCamera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(gameCamera)  // Attacca alla scene, non al worldLayer
        camera = gameCamera
        
        print("✅ Camera created at center")
    }
    
    private func setupPlanet() {
        planet = SKShapeNode(circleOfRadius: planetRadius)
        planet.fillColor = .white
        planet.strokeColor = .clear
        planet.name = "planet"
        planet.zPosition = 1
        planet.position = CGPoint(x: size.width / 2, y: size.height / 2)  // Centro dello schermo
        
        // Physics body per il pianeta
        let planetBody = SKPhysicsBody(circleOfRadius: planetRadius)
        planetBody.isDynamic = false
        planetBody.categoryBitMask = PhysicsCategory.planet
        planetBody.contactTestBitMask = PhysicsCategory.asteroid
        planetBody.collisionBitMask = 0
        planet.physicsBody = planetBody
        
        worldLayer.addChild(planet)
        
        print("✅ Planet created at: \(planet.position)")
    }
    
    private func setupAtmosphere() {
        atmosphere = SKShapeNode(circleOfRadius: atmosphereRadius)
        atmosphere.fillColor = UIColor.cyan.withAlphaComponent(0.15)  // Leggera opacità
        atmosphere.strokeColor = UIColor.cyan.withAlphaComponent(0.6)
        atmosphere.lineWidth = 2
        atmosphere.name = "atmosphere"
        atmosphere.zPosition = 2
        atmosphere.position = CGPoint(x: size.width / 2, y: size.height / 2)  // Centro dello schermo
        
        // Physics body per l'atmosfera
        let atmosphereBody = SKPhysicsBody(circleOfRadius: atmosphereRadius)
        atmosphereBody.isDynamic = false
        atmosphereBody.categoryBitMask = PhysicsCategory.atmosphere
        atmosphereBody.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile | PhysicsCategory.asteroid
        atmosphereBody.collisionBitMask = 0
        atmosphere.physicsBody = atmosphereBody
        
        worldLayer.addChild(atmosphere)
        
        // Animazione pulsazione atmosfera
        let pulseUp = SKAction.scale(to: 1.05, duration: 1.5)
        let pulseDown = SKAction.scale(to: 1.0, duration: 1.5)
        let pulse = SKAction.sequence([pulseUp, pulseDown])
        atmosphere.run(SKAction.repeatForever(pulse))
        
        print("✅ Atmosphere created with radius: \(atmosphereRadius)")
    }

    
    private func setupPlayer() {
        // Nave triangolare - PIÙ PICCOLA
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 10))      // Era 20, ora 10
        path.addLine(to: CGPoint(x: -6, y: -6))  // Era -12, ora -6
        path.addLine(to: CGPoint(x: 6, y: -6))   // Era 12, ora 6
        path.closeSubpath()
        
        player = SKShapeNode(path: path)
        player.fillColor = .clear
        player.strokeColor = .white
        player.lineWidth = 2
        // Posizione assoluta: centro + offset
        player.position = CGPoint(x: size.width / 2 + 300, y: size.height / 2)
        player.zPosition = 10
        
        // FISICA: Aggiungi corpo fisico con inerzia RIDOTTA per più controllo
        player.physicsBody = SKPhysicsBody(circleOfRadius: 8)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.mass = 0.5
        player.physicsBody?.linearDamping = 0.3  // Aumentato da 0.1 per meno inerzia
        player.physicsBody?.angularDamping = 0.5
        player.physicsBody?.allowsRotation = false
        
        // Effetto reattori: semplice glow dietro la nave
        thrusterGlow = SKShapeNode(circleOfRadius: 3)
        thrusterGlow.fillColor = .cyan
        thrusterGlow.strokeColor = .clear
        thrusterGlow.position = CGPoint(x: 0, y: -8)
        thrusterGlow.zPosition = -1
        thrusterGlow.alpha = 0  // Inizialmente invisibile
        thrusterGlow.setScale(0.1)
        
        // Aggiungi un glow effect
        thrusterGlow.glowWidth = 4.0
        
        player.addChild(thrusterGlow)
        
        // Scudo - barriera circolare attorno alla nave
        playerShield = SKShapeNode(circleOfRadius: 20)
        playerShield.fillColor = .clear
        playerShield.strokeColor = UIColor.white.withAlphaComponent(0.3)
        playerShield.lineWidth = 1
        playerShield.zPosition = -1
        
        player.addChild(playerShield)
        
        // Physics category per il player
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.atmosphere | PhysicsCategory.asteroid
        player.physicsBody?.collisionBitMask = 0
        
        worldLayer.addChild(player)
        
        print("✅ Player created at: \(player.position)")
    }
    
    private func setupControls() {
        print("=== CONTROLS SETUP START ===")
        print("Scene size: \(size)")
        
        // Joystick - fisso in basso a sinistra (nell'HUD layer)
        joystick = JoystickNode(baseRadius: 70, thumbRadius: 30)
        joystick.position = CGPoint(x: 120, y: 120)
        joystick.zPosition = 1000
        joystick.onMove = { [weak self] direction in
            self?.joystickDirection = direction
        }
        joystick.onEnd = { [weak self] in
            self?.joystickDirection = .zero
        }
        hudLayer.addChild(joystick)
        
        // Fire button - fisso in basso a destra (nell'HUD layer)
        fireButton = FireButtonNode(radius: 60)
        fireButton.position = CGPoint(x: size.width - 120, y: 120)
        fireButton.zPosition = 1000
        fireButton.onPress = { [weak self] in
            self?.isFiring = true
        }
        fireButton.onRelease = { [weak self] in
            self?.isFiring = false
        }
        hudLayer.addChild(fireButton)
        
        print("✅ Controls in HUD layer (unaffected by camera zoom)")
        print("=== CONTROLS SETUP END ===")
    }
    
    private func setupScore() {
        // Score label in alto a destra - stile vettoriale
        scoreLabel = SKLabelNode(fontNamed: "Courier-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.text = "SCORE: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.position = CGPoint(x: size.width - 20, y: size.height - 20)
        scoreLabel.zPosition = 1000
        
        hudLayer.addChild(scoreLabel)
        
        print("✅ Score label created")
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            joystick.touchBegan(touch, in: self)
            fireButton.touchBegan(touch, in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            joystick.touchMoved(touch, in: self)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            joystick.touchEnded(touch)
            fireButton.touchEnded(touch)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            joystick.touchEnded(touch)
            fireButton.touchEnded(touch)
        }
    }
    
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        applyGravity()
        updatePlayerMovement()
        updatePlayerShooting(currentTime)
        spawnAsteroidsForWave(currentTime)
        wrapPlayerAroundScreen()
        wrapAsteroidsAroundScreen()
        cleanupProjectiles()
        cleanupAsteroids()
        checkWaveComplete()
    }
    
    private func wrapPlayerAroundScreen() {
        // Wrap orizzontale
        if player.position.x < 0 {
            player.position.x = size.width
        } else if player.position.x > size.width {
            player.position.x = 0
        }
        
        // Wrap verticale
        if player.position.y < 0 {
            player.position.y = size.height
        } else if player.position.y > size.height {
            player.position.y = 0
        }
    }
    
    private func updatePlayerMovement() {
        let magnitude = hypot(joystickDirection.dx, joystickDirection.dy)
        
        if magnitude > 0.1 {
            // FISICA: Applica forza proporzionale - PIÙ POTENTE
            let thrustPower: CGFloat = 50.0  // Aumentato da 30.0
            let forceX = joystickDirection.dx * thrustPower * magnitude
            let forceY = joystickDirection.dy * thrustPower * magnitude
            
            player.physicsBody?.applyForce(CGVector(dx: forceX, dy: forceY))
            
            // Orienta la nave nella direzione del movimento
            let angle = atan2(joystickDirection.dy, joystickDirection.dx) - .pi / 2
            player.zRotation = angle
            
            // EFFETTO REATTORI: Glow che pulsa con l'intensità
            thrusterGlow.alpha = 0.3 + (magnitude * 0.7)  // Da 0.3 a 1.0
            thrusterGlow.setScale(0.5 + (magnitude * 1.0))  // Da 0.5 a 1.5
            
            // Colore varia con intensità: da cyan a bianco
            let intensity = magnitude
            thrusterGlow.fillColor = SKColor(
                red: 0.0 + intensity * 0.8,
                green: 1.0,
                blue: 1.0,
                alpha: 1.0
            )
        } else {
            // Nessuna spinta: spegni reattori con fade out
            thrusterGlow.alpha = max(0, thrusterGlow.alpha - 0.05)
        }
    }
    
    private func updatePlayerShooting(_ currentTime: TimeInterval) {
        guard isFiring else { return }
        
        if currentTime - lastFireTime >= fireRate {
            fireProjectile()
            lastFireTime = currentTime
        }
    }
    
    private func fireProjectile() {
        // Proiettile a forma di linea spessa (rettangolo)
        let projectile = SKShapeNode(rectOf: CGSize(width: 3, height: 12), cornerRadius: 1)
        projectile.fillColor = .white
        projectile.strokeColor = .white
        projectile.lineWidth = 0
        
        // Physics body per il proiettile
        projectile.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 3, height: 12))
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.atmosphere | PhysicsCategory.asteroid
        projectile.physicsBody?.collisionBitMask = 0
        projectile.physicsBody?.mass = 0.01
        projectile.physicsBody?.linearDamping = 0
        projectile.physicsBody?.affectedByGravity = false
        
        // Posizione davanti alla nave - spara nella direzione in cui punta
        let angle = player.zRotation + .pi / 2
        let offset: CGFloat = 25
        projectile.position = CGPoint(
            x: player.position.x + cos(angle) * offset,
            y: player.position.y + sin(angle) * offset
        )
        projectile.zPosition = 8
        
        // Ruota il proiettile nella direzione di sparo
        projectile.zRotation = player.zRotation
        
        // Imposta velocità iniziale invece di usare SKAction
        let speed: CGFloat = 500
        let velocityX = cos(angle) * speed
        let velocityY = sin(angle) * speed
        projectile.physicsBody?.velocity = CGVector(dx: velocityX, dy: velocityY)
        
        worldLayer.addChild(projectile)
        projectiles.append(projectile)
        
        // Rimuovi dopo 3 secondi
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.removeFromParent()
        ])
        projectile.run(removeAction)
        
        print("💥 Fired projectile from: \(projectile.position)")
    }
    
    private func cleanupProjectiles() {
        projectiles.removeAll { $0.parent == nil }
    }
    
    // MARK: - Gravity System
    private func applyGravity() {
        // Applica gravità al player
        if let playerBody = player.physicsBody {
            applyGravityToNode(node: player, body: playerBody)
        }
        
        // Applica gravità agli asteroidi
        for asteroid in asteroids {
            if let asteroidBody = asteroid.physicsBody {
                applyGravityToNode(node: asteroid, body: asteroidBody)
            }
        }
    }
    
    private func applyGravityToNode(node: SKNode, body: SKPhysicsBody) {
        // Calcola distanza dal pianeta
        let dx = planet.position.x - node.position.x
        let dy = planet.position.y - node.position.y
        let distanceSquared = dx * dx + dy * dy
        let distance = sqrt(distanceSquared)
        
        // Evita divisione per zero e collisione col pianeta
        guard distance > planetRadius else { return }
        
        // Formula gravitazionale: F = G * m1 * m2 / r²
        let force = gravitationalConstant * planetMass * body.mass / distanceSquared
        
        // Direzione normalizzata verso il pianeta
        let forceX = (dx / distance) * force
        let forceY = (dy / distance) * force
        
        // Applica la forza
        body.applyForce(CGVector(dx: forceX, dy: forceY))
    }
    
    // MARK: - Wave System
    private func startWave(_ wave: Int) {
        currentWave = wave
        isWaveActive = false  // Disattiva il gioco durante il messaggio
        
        // Calcola numero di asteroidi per questa wave (aumenta del 20% ogni wave)
        let baseAsteroids = 5
        asteroidsToSpawnInWave = Int(CGFloat(baseAsteroids) * pow(1.2, CGFloat(wave - 1)))
        asteroidsSpawnedInWave = 0
        
        // Mostra messaggio WAVE
        let waveMessage = SKLabelNode(fontNamed: "Courier-Bold")
        waveMessage.fontSize = 60
        waveMessage.fontColor = .white
        waveMessage.text = "WAVE \(wave)"
        waveMessage.position = CGPoint(x: size.width / 2, y: size.height / 2)
        waveMessage.zPosition = 2000
        waveMessage.alpha = 0
        
        hudLayer.addChild(waveMessage)
        
        // Animazione: Fade in, attendi, fade out, poi avvia wave
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let activateWave = SKAction.run { [weak self] in
            self?.isWaveActive = true
            print("🌊 Wave \(wave) started - Asteroids to spawn: \(self?.asteroidsToSpawnInWave ?? 0)")
        }
        
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove, activateWave])
        waveMessage.run(sequence)
        
        print("🌊 Wave \(wave) message displayed")
    }
    
    private func spawnAsteroidsForWave(_ currentTime: TimeInterval) {
        // Non spawnare se la wave non è attiva
        guard isWaveActive else { return }
        
        // Non spawnare se abbiamo già spawnato tutti gli asteroidi della wave
        guard asteroidsSpawnedInWave < asteroidsToSpawnInWave else { return }
        
        // Spawna asteroidi periodicamente
        guard currentTime - lastAsteroidSpawnTime > asteroidSpawnInterval else { return }
        lastAsteroidSpawnTime = currentTime
        
        // Spawna asteroide grande
        spawnAsteroid(size: .large, at: nil)
        asteroidsSpawnedInWave += 1
        
        print("☄️ Spawned asteroid \(asteroidsSpawnedInWave)/\(asteroidsToSpawnInWave)")
    }
    
    private func checkWaveComplete() {
        // Controlla se la wave è completa
        guard isWaveActive else { return }
        guard asteroidsSpawnedInWave >= asteroidsToSpawnInWave else { return }
        guard asteroids.isEmpty else { return }
        
        // Wave completata! Avvia la prossima
        print("🎉 Wave \(currentWave) completed!")
        startWave(currentWave + 1)
    }
    
    // MARK: - Asteroid Management
    
    private func spawnAsteroid(size asteroidSize: AsteroidSize, at position: CGPoint?) {
        // Crea forma a linee spezzate (stile Asteroids)
        let path = createAsteroidPath(radius: asteroidSize.radius)
        let asteroid = SKShapeNode(path: path)
        asteroid.fillColor = .clear
        asteroid.strokeColor = .white
        asteroid.lineWidth = 2
        asteroid.zPosition = 5
        asteroid.name = "asteroid_\(asteroidSize.rawValue)"
        
        // Posizione
        if let pos = position {
            asteroid.position = pos
        } else {
            // Posizione casuale ai bordi dello schermo
            let edge = Int.random(in: 0...3)
            switch edge {
            case 0: // Top
                asteroid.position = CGPoint(x: CGFloat.random(in: 0...self.size.width), y: self.size.height + 50)
            case 1: // Right
                asteroid.position = CGPoint(x: self.size.width + 50, y: CGFloat.random(in: 0...self.size.height))
            case 2: // Bottom
                asteroid.position = CGPoint(x: CGFloat.random(in: 0...self.size.width), y: -50)
            default: // Left
                asteroid.position = CGPoint(x: -50, y: CGFloat.random(in: 0...self.size.height))
            }
        }
        
        // Physics body
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroidSize.radius)
        asteroid.physicsBody?.isDynamic = true
        asteroid.physicsBody?.mass = asteroidSize.mass
        asteroid.physicsBody?.linearDamping = 0
        asteroid.physicsBody?.angularDamping = 0
        asteroid.physicsBody?.categoryBitMask = PhysicsCategory.asteroid
        asteroid.physicsBody?.contactTestBitMask = PhysicsCategory.atmosphere | PhysicsCategory.planet | PhysicsCategory.projectile
        asteroid.physicsBody?.collisionBitMask = 0
        
        // Velocità iniziale casuale (se non ha posizione specificata)
        if position == nil {
            let randomVelocity = CGVector(
                dx: CGFloat.random(in: -80...80),
                dy: CGFloat.random(in: -80...80)
            )
            asteroid.physicsBody?.velocity = randomVelocity
        }
        
        // Rotazione lenta casuale
        let rotationSpeed = CGFloat.random(in: -0.3...0.3)  // Radianti per secondo
        asteroid.physicsBody?.angularVelocity = rotationSpeed
        
        worldLayer.addChild(asteroid)
        asteroids.append(asteroid)
        
        print("☄️ Asteroid (\(asteroidSize)) spawned at: \(asteroid.position)")
    }
    
    private func createAsteroidPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let sides = Int.random(in: 7...10)
        let angleStep = (2 * .pi) / CGFloat(sides)
        
        for i in 0..<sides {
            let angle = angleStep * CGFloat(i)
            let variation = CGFloat.random(in: 0.7...1.3)
            let r = radius * variation
            let x = cos(angle) * r
            let y = sin(angle) * r
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
    
    private func wrapAsteroidsAroundScreen() {
        for asteroid in asteroids {
            // Wrap orizzontale
            if asteroid.position.x < -50 {
                asteroid.position.x = size.width + 50
            } else if asteroid.position.x > size.width + 50 {
                asteroid.position.x = -50
            }
            
            // Wrap verticale
            if asteroid.position.y < -50 {
                asteroid.position.y = size.height + 50
            } else if asteroid.position.y > size.height + 50 {
                asteroid.position.y = -50
            }
        }
    }
    
    private func cleanupAsteroids() {
        asteroids.removeAll { $0.parent == nil }
    }
    
    // MARK: - Collision Handling
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let currentTime = Date().timeIntervalSince1970
        
        // Player + Atmosphere
        if collision == (PhysicsCategory.player | PhysicsCategory.atmosphere) {
            // Cooldown per evitare collisioni multiple consecutive
            guard currentTime - lastCollisionTime > collisionCooldown else { return }
            lastCollisionTime = currentTime
            
            handleAtmosphereBounce(contact: contact, isPlayer: true)
            rechargeAtmosphere(amount: 3)
            flashAtmosphere()
            flashPlayerShield()
            
            // Bonus per rimbalzo
            score += 5
            scoreLabel.text = "SCORE: \(score)"
            
            print("🌀 Player hit atmosphere - bounce + recharge + 5 points")
        }
        
        // Projectile + Atmosphere
        else if collision == (PhysicsCategory.projectile | PhysicsCategory.atmosphere) {
            handleAtmosphereBounce(contact: contact, isPlayer: false)
            rechargeAtmosphere(amount: 3)
            flashAtmosphere()
            
            // Rimuovi il proiettile
            if contact.bodyA.categoryBitMask == PhysicsCategory.projectile {
                contact.bodyA.node?.removeFromParent()
            } else {
                contact.bodyB.node?.removeFromParent()
            }
            print("💥 Projectile hit atmosphere - bounce + recharge")
        }
        
        // Asteroid + Atmosphere
        else if collision == (PhysicsCategory.asteroid | PhysicsCategory.atmosphere) {
            handleAsteroidAtmosphereBounce(contact: contact)
            damageAtmosphere(amount: 2)
            flashAtmosphere()
            print("☄️ Asteroid hit atmosphere - bounce + damage")
        }
        
        // Asteroid + Planet
        else if collision == (PhysicsCategory.asteroid | PhysicsCategory.planet) {
            // Rimuovi l'asteroide
            if contact.bodyA.categoryBitMask == PhysicsCategory.asteroid {
                contact.bodyA.node?.removeFromParent()
            } else {
                contact.bodyB.node?.removeFromParent()
            }
            print("💥 Asteroid hit planet - destroyed")
        }
        
        // Player + Asteroid
        else if collision == (PhysicsCategory.player | PhysicsCategory.asteroid) {
            // Identifica l'asteroide
            let asteroid = contact.bodyA.categoryBitMask == PhysicsCategory.asteroid ? contact.bodyA.node as? SKShapeNode : contact.bodyB.node as? SKShapeNode
            
            if let asteroid = asteroid {
                // L'astronave danneggia l'asteroide (meno di un proiettile)
                damageAsteroid(asteroid)
                flashPlayerShield()
                print("💥 Player hit asteroid - damage")
            }
        }
        
        // Projectile + Asteroid
        else if collision == (PhysicsCategory.projectile | PhysicsCategory.asteroid) {
            // Identifica proiettile e asteroide
            let projectile = contact.bodyA.categoryBitMask == PhysicsCategory.projectile ? contact.bodyA.node : contact.bodyB.node
            let asteroid = contact.bodyA.categoryBitMask == PhysicsCategory.asteroid ? contact.bodyA.node as? SKShapeNode : contact.bodyB.node as? SKShapeNode
            
            // Rimuovi il proiettile
            projectile?.removeFromParent()
            
            // Frammenta l'asteroide
            if let asteroid = asteroid {
                fragmentAsteroid(asteroid)
            }
            
            print("💥 Projectile destroyed asteroid")
        }
    }
    
    private func handleAtmosphereBounce(contact: SKPhysicsContact, isPlayer: Bool) {
        // Determina quale body è quello che rimbalza
        let bouncingBody = isPlayer ? 
            (contact.bodyA.categoryBitMask == PhysicsCategory.player ? contact.bodyA : contact.bodyB) :
            (contact.bodyA.categoryBitMask == PhysicsCategory.projectile ? contact.bodyA : contact.bodyB)
        
        guard let node = bouncingBody.node else { return }
        
        // Calcola direzione dal centro del pianeta al nodo
        let dx = node.position.x - planet.position.x
        let dy = node.position.y - planet.position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 0 else { return }
        
        // Direzione normalizzata (allontana dal centro)
        let normalX = dx / distance
        let normalY = dy / distance
        
        // Rifletti la velocità rispetto alla normale
        let velocity = bouncingBody.velocity
        let dotProduct = velocity.dx * normalX + velocity.dy * normalY
        
        // Se l'oggetto sta già andando via dall'atmosfera, non fare nulla
        guard dotProduct < 0 else { return }
        
        let reflectedVelocityX = velocity.dx - 2 * dotProduct * normalX
        let reflectedVelocityY = velocity.dy - 2 * dotProduct * normalY
        
        // Applica la velocità riflessa con boost per il rimbalzo
        let bounceFactor: CGFloat = 1.3  // 30% più veloce dopo il rimbalzo
        bouncingBody.velocity = CGVector(
            dx: reflectedVelocityX * bounceFactor,
            dy: reflectedVelocityY * bounceFactor
        )
        
        // Sposta il nodo FUORI dall'atmosfera per evitare collisioni multiple
        let pushDistance: CGFloat = 10
        node.position.x += normalX * pushDistance
        node.position.y += normalY * pushDistance
    }
    
    private func handleAsteroidAtmosphereBounce(contact: SKPhysicsContact) {
        // Determina quale body è l'asteroide
        let asteroidBody = contact.bodyA.categoryBitMask == PhysicsCategory.asteroid ? contact.bodyA : contact.bodyB
        
        guard let asteroid = asteroidBody.node else { return }
        
        // Calcola direzione dal centro del pianeta all'asteroide
        let dx = asteroid.position.x - planet.position.x
        let dy = asteroid.position.y - planet.position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 0 else { return }
        
        // Direzione normalizzata (allontana dal centro)
        let normalX = dx / distance
        let normalY = dy / distance
        
        // Rifletti la velocità
        let velocity = asteroidBody.velocity
        let dotProduct = velocity.dx * normalX + velocity.dy * normalY
        
        // Se l'asteroide sta già andando via, non fare nulla
        guard dotProduct < 0 else { return }
        
        let reflectedVelocityX = velocity.dx - 2 * dotProduct * normalX
        let reflectedVelocityY = velocity.dy - 2 * dotProduct * normalY
        
        // Rimbalzo più forte per gli asteroidi
        let bounceFactor: CGFloat = 1.5
        asteroidBody.velocity = CGVector(
            dx: reflectedVelocityX * bounceFactor,
            dy: reflectedVelocityY * bounceFactor
        )
        
        // Sposta l'asteroide fuori dall'atmosfera
        let pushDistance: CGFloat = 10
        asteroid.position.x += normalX * pushDistance
        asteroid.position.y += normalY * pushDistance
    }
    
    private func fragmentAsteroid(_ asteroid: SKShapeNode) {
        guard let sizeString = asteroid.name?.split(separator: "_").last,
              let sizeRaw = Int(String(sizeString)),
              let size = AsteroidSize(rawValue: sizeRaw) else { return }
        
        // Aggiungi punti in base alla dimensione
        let points: Int
        switch size {
        case .large: points = 20
        case .medium: points = 15
        case .small: points = 10
        }
        score += points
        scoreLabel.text = "SCORE: \(score)"
        
        let position = asteroid.position
        let velocity = asteroid.physicsBody?.velocity ?? .zero
        
        // Rimuovi l'asteroide originale
        asteroid.removeFromParent()
        asteroids.removeAll { $0 == asteroid }
        
        // Crea frammenti se non è small
        if size != .small {
            let nextSize: AsteroidSize = size == .large ? .medium : .small
            let fragmentCount = Int.random(in: 2...3)
            
            for i in 0..<fragmentCount {
                let angle = (CGFloat(i) / CGFloat(fragmentCount)) * 2 * .pi + CGFloat.random(in: -0.3...0.3)
                
                // Posizione offset dal centro
                let offset = CGPoint(
                    x: cos(angle) * size.radius * 0.5,
                    y: sin(angle) * size.radius * 0.5
                )
                
                let fragmentPosition = CGPoint(
                    x: position.x + offset.x,
                    y: position.y + offset.y
                )
                
                // Spawna il frammento
                spawnAsteroid(size: nextSize, at: fragmentPosition)
                
                // Applica velocità ereditata + esplosione RIDOTTA
                if let fragment = asteroids.last {
                    let explosionForce: CGFloat = 60  // Ridotto da 120 a 60
                    fragment.physicsBody?.velocity = CGVector(
                        dx: velocity.dx * 0.7 + cos(angle) * explosionForce,  // Eredita 70% velocità
                        dy: velocity.dy * 0.7 + sin(angle) * explosionForce
                    )
                }
            }
            
            print("💥 Asteroid fragmented into \(fragmentCount) x \(nextSize)")
        } else {
            print("💥 Small asteroid destroyed")
        }
    }
    
    private func damageAsteroid(_ asteroid: SKShapeNode) {
        guard let sizeString = asteroid.name?.split(separator: "_").last,
              let sizeRaw = Int(String(sizeString)),
              let size = AsteroidSize(rawValue: sizeRaw) else { return }
        
        // Aggiungi punti (metà rispetto al proiettile)
        let points: Int
        switch size {
        case .large: points = 10  // Metà di 20
        case .medium: points = 7   // Circa metà di 15
        case .small: points = 5    // Metà di 10
        }
        score += points
        scoreLabel.text = "SCORE: \(score)"
        
        // L'astronave danneggia ma non distrugge completamente
        // Large diventa medium, medium diventa small, small viene distrutto
        if size == .small {
            // Small viene distrutto dall'impatto
            asteroid.removeFromParent()
            asteroids.removeAll { $0 == asteroid }
            print("💥 Small asteroid destroyed by player")
        } else {
            // Large e medium si frammentano (ma con meno energia)
            let position = asteroid.position
            let velocity = asteroid.physicsBody?.velocity ?? .zero
            
            asteroid.removeFromParent()
            asteroids.removeAll { $0 == asteroid }
            
            let nextSize: AsteroidSize = size == .large ? .medium : .small
            let fragmentCount = 2  // Sempre 2 frammenti per l'impatto del player
            
            for i in 0..<fragmentCount {
                let angle = (CGFloat(i) / CGFloat(fragmentCount)) * 2 * .pi + CGFloat.random(in: -0.5...0.5)
                
                let offset = CGPoint(
                    x: cos(angle) * size.radius * 0.4,
                    y: sin(angle) * size.radius * 0.4
                )
                
                let fragmentPosition = CGPoint(
                    x: position.x + offset.x,
                    y: position.y + offset.y
                )
                
                spawnAsteroid(size: nextSize, at: fragmentPosition)
                
                // Velocità più bassa rispetto all'esplosione del proiettile
                if let fragment = asteroids.last {
                    let pushForce: CGFloat = 40  // Molto più basso di 60 (proiettile)
                    fragment.physicsBody?.velocity = CGVector(
                        dx: velocity.dx * 0.5 + cos(angle) * pushForce,
                        dy: velocity.dy * 0.5 + sin(angle) * pushForce
                    )
                }
            }
            
            print("💥 Asteroid damaged by player - fragmented into \(fragmentCount) x \(nextSize)")
        }
    }
    
    private func rechargeAtmosphere(amount: CGFloat) {
        // Aumenta il raggio dell'atmosfera (max 80)
        atmosphereRadius = min(atmosphereRadius + amount, maxAtmosphereRadius)
        
        updateAtmosphereVisuals()
        print("🔋 Atmosphere recharged: \(atmosphereRadius)")
    }
    
    private func damageAtmosphere(amount: CGFloat) {
        // Riduci il raggio dell'atmosfera (min 40)
        atmosphereRadius = max(atmosphereRadius - amount, minAtmosphereRadius)
        
        updateAtmosphereVisuals()
        print("⚠️ Atmosphere damaged: \(atmosphereRadius)")
    }
    
    private func updateAtmosphereVisuals() {
        // Aggiorna il path dell'atmosfera
        let newPath = CGPath(ellipseIn: CGRect(
            x: -atmosphereRadius,
            y: -atmosphereRadius,
            width: atmosphereRadius * 2,
            height: atmosphereRadius * 2
        ), transform: nil)
        
        atmosphere.path = newPath
        
        // Aggiorna anche il physics body
        atmosphere.physicsBody = SKPhysicsBody(circleOfRadius: atmosphereRadius)
        atmosphere.physicsBody?.isDynamic = false
        atmosphere.physicsBody?.categoryBitMask = PhysicsCategory.atmosphere
        atmosphere.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile | PhysicsCategory.asteroid
        atmosphere.physicsBody?.collisionBitMask = 0
    }
    
    // MARK: - Visual Feedback
    private func flashAtmosphere() {
        // Flash bianco brillante sulla collisione
        let originalColor = atmosphere.strokeColor
        
        let flashAction = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.atmosphere.strokeColor = .white
                self?.atmosphere.lineWidth = 4
            },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in
                self?.atmosphere.strokeColor = originalColor
                self?.atmosphere.lineWidth = 2
            }
        ])
        
        atmosphere.run(flashAction)
    }
    
    private func flashPlayerShield() {
        // Flash dello scudo del player
        let originalAlpha = playerShield.alpha
        
        let flashAction = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.playerShield.strokeColor = .cyan
                self?.playerShield.alpha = 1.0
                self?.playerShield.lineWidth = 3
            },
            SKAction.wait(forDuration: 0.15),
            SKAction.run { [weak self] in
                self?.playerShield.strokeColor = UIColor.white.withAlphaComponent(0.3)
                self?.playerShield.alpha = originalAlpha
                self?.playerShield.lineWidth = 1
            }
        ])
        
        playerShield.run(flashAction)
    }
}
