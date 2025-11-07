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
        case .large: return 28   // Era 35
        case .medium: return 18  // Era 22
        case .small: return 10   // Era 12
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
    
    // Planet health system
    private var planetHealth: Int = 3
    private let maxPlanetHealth: Int = 3
    private var planetHealthLabel: SKLabelNode!
    
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
    private let fireRate: TimeInterval = 0.45  // Triplicato da 0.15 a 0.45 (1/3 della frequenza)
    
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
    
    // Pause system
    private var isGamePaused: Bool = false
    private var pauseButton: SKShapeNode!
    private var pauseOverlay: SKNode?
    
    // Particle texture cache
    private var particleTexture: SKTexture?
    
    // MARK: - Setup
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // FISICA: Configura la fisica della scena
        physicsWorld.gravity = .zero  // Niente gravità di default, la applichiamo manualmente
        physicsWorld.contactDelegate = self
        
        print("=== GRAVITY SHIELD ===")
        print("Scene size: \(size)")
        print("======================")
        
        // Crea texture per particelle
        createParticleTexture()
        
        setupLayers()
        setupCamera()
        setupPlanet()
        setupAtmosphere()
        setupPlayer()
        setupControls()
        setupScore()
        setupPauseButton()
        
        // Avvia Wave 1
        startWave(1)
    }
    
    private func createParticleTexture() {
        // Crea una texture bianca circolare 8x8 pixels
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        particleTexture = SKTexture(image: image)
        print("✅ Particle texture created")
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
        
        // Label della salute del pianeta al centro
        planetHealthLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        planetHealthLabel.text = "\(planetHealth)/\(maxPlanetHealth)"
        planetHealthLabel.fontSize = 20
        planetHealthLabel.fontColor = .black
        planetHealthLabel.horizontalAlignmentMode = .center
        planetHealthLabel.verticalAlignmentMode = .center
        planetHealthLabel.position = CGPoint.zero  // Centro del pianeta
        planetHealthLabel.zPosition = 2
        planet.addChild(planetHealthLabel)
        
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
        // Score label in alto a destra - prova Orbitron con fallback
        let possibleFontNames = ["Orbitron", "Orbitron-Bold", "Orbitron-Regular", "OrbitronVariable", "AvenirNext-Bold"]
        var fontName = "AvenirNext-Bold"
        
        for name in possibleFontNames {
            if UIFont(name: name, size: 12) != nil {
                fontName = name
                break
            }
        }
        
        scoreLabel = SKLabelNode(fontNamed: fontName)
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = .white
        scoreLabel.text = "0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.position = CGPoint(x: size.width - 20, y: size.height - 20)
        scoreLabel.zPosition = 1000
        
        hudLayer.addChild(scoreLabel)
        
        print("✅ Score label created with font: \(fontName)")
    }
    
    private func setupPauseButton() {
        // Pulsante pause in alto a sinistra
        let buttonSize: CGFloat = 50
        
        pauseButton = SKShapeNode(rectOf: CGSize(width: buttonSize, height: buttonSize), cornerRadius: 8)
        pauseButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        pauseButton.strokeColor = .white
        pauseButton.lineWidth = 2
        pauseButton.position = CGPoint(x: 80, y: size.height - 30)  // Spostato più a destra
        pauseButton.zPosition = 1000
        pauseButton.name = "pauseButton"
        
        // Icona pause (due barre verticali)
        let barWidth: CGFloat = 6
        let barHeight: CGFloat = 20
        let barSpacing: CGFloat = 8
        
        let leftBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight))
        leftBar.fillColor = .white
        leftBar.strokeColor = .clear
        leftBar.position = CGPoint(x: -barSpacing/2, y: 0)
        
        let rightBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight))
        rightBar.fillColor = .white
        rightBar.strokeColor = .clear
        rightBar.position = CGPoint(x: barSpacing/2, y: 0)
        
        pauseButton.addChild(leftBar)
        pauseButton.addChild(rightBar)
        
        hudLayer.addChild(pauseButton)
        
        print("✅ Pause button created")
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let nodesAtPoint = nodes(at: location)
            
            // Check se è stato toccato il pulsante pause o i bottoni del menu pause/game over
            for node in nodesAtPoint {
                if node.name == "pauseButton" {
                    togglePause()
                    return
                }
                if node.name == "resumeButton" {
                    resumeGame()
                    return
                }
                if node.name == "quitButton" {
                    quitToMenu()
                    return
                }
                if node.name == "retryButton" {
                    retryGame()
                    return
                }
                if node.name == "menuButton" {
                    quitToMenu()
                    return
                }
            }
            
            // Se non siamo in pausa, gestisci i controlli normali
            if !isGamePaused {
                joystick.touchBegan(touch, in: self)
                fireButton.touchBegan(touch, in: self)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGamePaused { return }
        for touch in touches {
            joystick.touchMoved(touch, in: self)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGamePaused { return }
        for touch in touches {
            joystick.touchEnded(touch)
            fireButton.touchEnded(touch)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGamePaused { return }
        for touch in touches {
            joystick.touchEnded(touch)
            fireButton.touchEnded(touch)
        }
    }
    
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        if isGamePaused { return }
        
        applyGravity()
        limitAsteroidSpeed()  // Limita velocità asteroidi
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
        
        // EFFETTO SCIA: Particelle che seguono il proiettile
        let trail = SKEmitterNode()
        trail.particleTexture = particleTexture
        trail.particleBirthRate = 80
        trail.numParticlesToEmit = 0  // Continua finché esiste
        trail.particleLifetime = 0.4
        trail.emissionAngle = angle - .pi  // Direzione opposta al movimento
        trail.emissionAngleRange = 0.2
        trail.particleSpeed = 30
        trail.particleSpeedRange = 15
        trail.particleScale = 0.2
        trail.particleScaleRange = 0.1
        trail.particleScaleSpeed = -0.5
        trail.particleAlpha = 0.8
        trail.particleAlphaSpeed = -2.0
        trail.particleColor = .white
        trail.particleBlendMode = .add
        trail.particleZPosition = -1
        trail.targetNode = worldLayer  // Le particelle rimangono nel world
        projectile.addChild(trail)
        
        print("☄️ Projectile fired with trail")
        
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
    
    private func limitAsteroidSpeed() {
        let maxSpeed: CGFloat = 150  // Velocità massima per gli asteroidi (ridotta da 200)
        
        for asteroid in asteroids {
            guard let body = asteroid.physicsBody else { continue }
            
            let velocity = body.velocity
            let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
            
            if speed > maxSpeed {
                // Normalizza e limita alla velocità massima
                let factor = maxSpeed / speed
                body.velocity = CGVector(
                    dx: velocity.dx * factor,
                    dy: velocity.dy * factor
                )
            }
        }
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
        let possibleFontNames = ["Orbitron", "Orbitron-Bold", "Orbitron-Regular", "OrbitronVariable", "AvenirNext-Bold"]
        var fontName = "AvenirNext-Bold"
        
        for name in possibleFontNames {
            if UIFont(name: name, size: 12) != nil {
                fontName = name
                break
            }
        }
        
        // Background opaco dietro il messaggio
        let waveBackground = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.6), size: size)
        waveBackground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        waveBackground.zPosition = 1999
        waveBackground.alpha = 0
        
        hudLayer.addChild(waveBackground)
        
        let waveMessage = SKLabelNode(fontNamed: fontName)
        waveMessage.fontSize = 64
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
        waveBackground.run(sequence)  // Stesso effetto anche per il background
        
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
        
        // Velocità iniziale casuale (se non ha posizione specificata) - RIDOTTA
        if position == nil {
            let randomVelocity = CGVector(
                dx: CGFloat.random(in: -50...50),  // Era -80...80
                dy: CGFloat.random(in: -50...50)   // Era -80...80
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
            rechargeAtmosphere(amount: 1.5)  // Ridotto da 3 a 1.5
            flashAtmosphere()
            flashPlayerShield()
            
            // Bonus per rimbalzo
            score += 5
            scoreLabel.text = "\(score)"
            
            print("🌀 Player hit atmosphere - bounce + recharge + 5 points")
        }
        
        // Projectile + Atmosphere
        else if collision == (PhysicsCategory.projectile | PhysicsCategory.atmosphere) {
            handleAtmosphereBounce(contact: contact, isPlayer: false)
            rechargeAtmosphere(amount: 1.5)  // Ridotto da 3 a 1.5
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
            
            // Effetto particellare al punto di contatto
            createCollisionParticles(at: contact.contactPoint, color: .cyan)
            
            print("☄️ Asteroid hit atmosphere - bounce + damage")
        }
        
        // Asteroid + Planet
        else if collision == (PhysicsCategory.asteroid | PhysicsCategory.planet) {
            // Identifica l'asteroide
            let asteroid = contact.bodyA.categoryBitMask == PhysicsCategory.asteroid ? 
                          contact.bodyA.node as? SKShapeNode : 
                          contact.bodyB.node as? SKShapeNode
            
            // Danno al pianeta SOLO se l'atmosfera è al minimo (raggio = raggio pianeta)
            if atmosphereRadius <= planetRadius {
                // Riduci salute del pianeta
                planetHealth -= 1
                updatePlanetHealthLabel()
                
                // Effetto visivo rosso sul pianeta
                flashPlanet()
                
                if planetHealth <= 0 {
                    // Game Over
                    gameOver()
                    return
                } else {
                    print("💔 Planet damaged! Health: \(planetHealth)/\(maxPlanetHealth)")
                }
            }
            
            // Rimbalza l'asteroide e danneggialo (invece di distruggerlo)
            if let asteroid = asteroid {
                // Effetto rimbalzo (stesso codice dell'atmosfera ma con il pianeta)
                handlePlanetBounce(contact: contact, asteroid: asteroid)
                
                // Flash rosso sull'asteroide
                flashAsteroid(asteroid)
                
                // Danneggia l'asteroide (frammenta se non è small)
                if let sizeValue = asteroid.userData?["size"] as? Int,
                   let size = AsteroidSize(rawValue: sizeValue) {
                    if size == .small {
                        // Small viene distrutto
                        let position = asteroid.position
                        createExplosionParticles(at: position, color: randomExplosionColor())
                        asteroid.removeFromParent()
                        asteroids.removeAll { $0 == asteroid }
                        print("💥 Small asteroid destroyed by planet impact")
                    } else {
                        // Large e medium si frammentano
                        fragmentAsteroid(asteroid)
                        print("💥 Asteroid fragmented by planet impact")
                    }
                }
            }
        }
        
        // Player + Asteroid
        else if collision == (PhysicsCategory.player | PhysicsCategory.asteroid) {
            // Identifica player e asteroide
            let playerBody = contact.bodyA.categoryBitMask == PhysicsCategory.player ? contact.bodyA : contact.bodyB
            let asteroidBody = contact.bodyA.categoryBitMask == PhysicsCategory.asteroid ? contact.bodyA : contact.bodyB
            let asteroid = asteroidBody.node as? SKShapeNode
            
            if let asteroid = asteroid, let asteroidPhysics = asteroid.physicsBody {
                // Calcola rimbalzo reciproco basato su massa e velocità
                handlePlayerAsteroidCollision(playerBody: playerBody, asteroidBody: asteroidBody, asteroid: asteroid)
                
                // L'astronave danneggia l'asteroide (meno di un proiettile)
                damageAsteroid(asteroid)
                flashPlayerShield()
                
                // Effetto particellare
                createCollisionParticles(at: contact.contactPoint, color: .white)
                
                print("💥 Player hit asteroid - bounce + damage")
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
                // Effetto particellare con colore random
                createExplosionParticles(at: asteroid.position, color: randomExplosionColor())
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
    
    private func handlePlanetBounce(contact: SKPhysicsContact, asteroid: SKShapeNode) {
        // Calcola direzione dal centro del pianeta all'asteroide
        let dx = asteroid.position.x - planet.position.x
        let dy = asteroid.position.y - planet.position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 0, let asteroidBody = asteroid.physicsBody else { return }
        
        // Direzione normalizzata (allontana dal centro)
        let normalX = dx / distance
        let normalY = dy / distance
        
        // Rifletti la velocità rispetto alla normale
        let velocity = asteroidBody.velocity
        let dotProduct = velocity.dx * normalX + velocity.dy * normalY
        
        // Se l'asteroide sta già andando via, non fare nulla
        guard dotProduct < 0 else { return }
        
        let reflectedVelocityX = velocity.dx - 2 * dotProduct * normalX
        let reflectedVelocityY = velocity.dy - 2 * dotProduct * normalY
        
        // Applica la velocità riflessa con boost per il rimbalzo
        let bounceFactor: CGFloat = 1.5  // 50% più veloce dopo il rimbalzo dal pianeta
        asteroidBody.velocity = CGVector(
            dx: reflectedVelocityX * bounceFactor,
            dy: reflectedVelocityY * bounceFactor
        )
        
        // Sposta l'asteroide FUORI dal pianeta per evitare collisioni multiple
        let pushDistance: CGFloat = 15
        asteroid.position.x += normalX * pushDistance
        asteroid.position.y += normalY * pushDistance
        
        // Effetto particellare al punto di contatto
        createCollisionParticles(at: contact.contactPoint, color: .red)
        
        print("💥 Asteroid bounced off planet")
    }
    
    private func flashAsteroid(_ asteroid: SKShapeNode) {
        // Effetto flash rosso sull'asteroide
        let originalColor = asteroid.fillColor
        asteroid.fillColor = .red
        
        let wait = SKAction.wait(forDuration: 0.1)
        let restore = SKAction.run {
            asteroid.fillColor = originalColor
        }
        asteroid.run(SKAction.sequence([wait, restore]))
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
        scoreLabel.text = "\(score)"
        
        let position = asteroid.position
        let velocity = asteroid.physicsBody?.velocity ?? .zero
        
        // Effetto particellare per la frammentazione con colore random
        createExplosionParticles(at: position, color: randomExplosionColor())
        
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
        scoreLabel.text = "\(score)"
        
        // L'astronave danneggia ma non distrugge completamente
        // Large diventa medium, medium diventa small, small viene distrutto
        if size == .small {
            // Small viene distrutto dall'impatto
            let position = asteroid.position
            createExplosionParticles(at: position, color: randomExplosionColor())
            asteroid.removeFromParent()
            asteroids.removeAll { $0 == asteroid }
            print("💥 Small asteroid destroyed by player")
        } else {
            // Large e medium si frammentano (ma con meno energia)
            let position = asteroid.position
            let velocity = asteroid.physicsBody?.velocity ?? .zero
            
            // Effetto particellare per il danneggiamento
            createCollisionParticles(at: position, color: .white)
            
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
        // Non ricaricare se l'atmosfera è al minimo (raggio = raggio pianeta)
        if atmosphereRadius <= planetRadius {
            print("🚫 Atmosphere at critical level - cannot recharge!")
            return
        }
        
        // Aumenta il raggio dell'atmosfera (max 80)
        atmosphereRadius = min(atmosphereRadius + amount, maxAtmosphereRadius)
        
        updateAtmosphereVisuals()
        print("🔋 Atmosphere recharged: \(atmosphereRadius)")
    }
    
    private func damageAtmosphere(amount: CGFloat) {
        // Riduci il raggio dell'atmosfera (min = raggio pianeta)
        atmosphereRadius = max(atmosphereRadius - amount, planetRadius)
        
        // Se raggiunge il raggio del pianeta, nascondi l'atmosfera
        if atmosphereRadius <= planetRadius {
            atmosphere.alpha = 0  // Invisibile
            print("💀 Atmosphere DESTROYED - planet vulnerable!")
        }
        
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
    
    // MARK: - Collision Physics
    
    private func handlePlayerAsteroidCollision(playerBody: SKPhysicsBody, asteroidBody: SKPhysicsBody, asteroid: SKShapeNode) {
        // Calcola il vettore normale della collisione (dall'asteroide al player)
        guard let playerPos = playerBody.node?.position,
              let asteroidPos = asteroidBody.node?.position else { return }
        
        let dx = playerPos.x - asteroidPos.x
        let dy = playerPos.y - asteroidPos.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // Evita divisione per zero
        guard distance > 0 else { return }
        
        let normalX = dx / distance
        let normalY = dy / distance
        
        // Velocità relative
        let playerVel = playerBody.velocity
        let asteroidVel = asteroidBody.velocity
        let relVelX = playerVel.dx - asteroidVel.dx
        let relVelY = playerVel.dy - asteroidVel.dy
        
        // Velocità lungo la normale
        let velAlongNormal = relVelX * normalX + relVelY * normalY
        
        // Non risolvere se gli oggetti si stanno già separando
        guard velAlongNormal < 0 else { return }
        
        // Coefficiente di restituzione (bounciness) - dipende dalla dimensione dell'asteroide
        var restitution: CGFloat = 0.7
        
        // Asteroidi più grandi hanno un rimbalzo più forte
        if let asteroidName = asteroid.name {
            if asteroidName.contains("large") {
                restitution = 0.8
            } else if asteroidName.contains("medium") {
                restitution = 0.7
            } else if asteroidName.contains("small") {
                restitution = 0.6
            }
        }
        
        // Masse
        let playerMass = playerBody.mass
        let asteroidMass = asteroidBody.mass
        
        // Calcola l'impulso scalare
        let j = -(1 + restitution) * velAlongNormal / (1/playerMass + 1/asteroidMass)
        
        // Applica l'impulso
        let impulseX = j * normalX
        let impulseY = j * normalY
        
        // Applica l'impulso a entrambi i corpi
        let playerImpulse = CGVector(dx: impulseX / playerMass, dy: impulseY / playerMass)
        let asteroidImpulse = CGVector(dx: -impulseX / asteroidMass, dy: -impulseY / asteroidMass)
        
        playerBody.velocity = CGVector(
            dx: playerVel.dx + playerImpulse.dx,
            dy: playerVel.dy + playerImpulse.dy
        )
        
        asteroidBody.velocity = CGVector(
            dx: asteroidVel.dx + asteroidImpulse.dx,
            dy: asteroidVel.dy + asteroidImpulse.dy
        )
        
        print("⚡ Player-Asteroid bounce: restitution=\(restitution), impulse=\(j)")
    }
    
    // MARK: - Particle Effects
    
    private func createCollisionParticles(at position: CGPoint, color: UIColor) {
        let emitter = SKEmitterNode()
        emitter.position = position
        
        // Configurazione particelle di collisione
        emitter.particleTexture = particleTexture
        emitter.particleBirthRate = 200
        emitter.numParticlesToEmit = 20
        emitter.particleLifetime = 0.5
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = CGFloat.pi * 2
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 80
        emitter.particleScale = 0.3
        emitter.particleScaleRange = 0.15
        emitter.particleScaleSpeed = -0.5
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -2.0
        emitter.particleColor = color
        emitter.particleBlendMode = .add
        emitter.zPosition = 100
        
        worldLayer.addChild(emitter)
        
        print("✨ Collision particles created at \(position)")
        
        // Rimuovi dopo il completamento
        let waitAction = SKAction.wait(forDuration: 0.6)
        let removeAction = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([waitAction, removeAction]))
    }
    
    private func randomExplosionColor() -> UIColor {
        // Sceglie casualmente tra verde acido, rosso e bianco
        let colors: [UIColor] = [
            UIColor(red: 0.5, green: 1.0, blue: 0.0, alpha: 1.0),  // Verde acido
            UIColor.red,                                            // Rosso
            UIColor.white                                           // Bianco
        ]
        return colors.randomElement() ?? .white
    }
    
    private func createExplosionParticles(at position: CGPoint, color: UIColor) {
        let emitter = SKEmitterNode()
        emitter.position = position
        
        // Configurazione particelle di esplosione (più grandi e durature)
        emitter.particleTexture = particleTexture
        emitter.particleBirthRate = 300
        emitter.numParticlesToEmit = 40
        emitter.particleLifetime = 0.8
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = CGFloat.pi * 2
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 100
        emitter.particleScale = 0.4
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.4
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.2
        emitter.particleColor = color
        emitter.particleBlendMode = .add
        emitter.zPosition = 100
        
        worldLayer.addChild(emitter)
        
        print("💥 Explosion particles created at \(position)")
        
        // Rimuovi dopo il completamento
        let waitAction = SKAction.wait(forDuration: 1.0)
        let removeAction = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([waitAction, removeAction]))
    }
    
    // MARK: - Pause System
    private func togglePause() {
        if isGamePaused {
            resumeGame()
        } else {
            pauseGame()
        }
    }
    
    private func pauseGame() {
        isGamePaused = true
        
        // Pausa la fisica
        physicsWorld.speed = 0
        
        // Crea overlay scuro
        let overlay = SKNode()
        overlay.name = "pauseOverlay"
        overlay.zPosition = 2000
        
        // Background semi-trasparente
        let background = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.7), size: size)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(background)
        
        // Titolo PAUSED
        let fontName = "AvenirNext-Bold"
        let titleLabel = SKLabelNode(fontNamed: fontName)
        titleLabel.text = "PAUSED"
        titleLabel.fontSize = 64
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        overlay.addChild(titleLabel)
        
        // Pulsante RESUME
        let resumeButton = SKShapeNode(rectOf: CGSize(width: 250, height: 70), cornerRadius: 10)
        resumeButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        resumeButton.strokeColor = .white
        resumeButton.lineWidth = 3
        resumeButton.position = CGPoint(x: size.width / 2, y: size.height / 2)
        resumeButton.name = "resumeButton"
        
        let resumeLabel = SKLabelNode(fontNamed: fontName)
        resumeLabel.text = "RESUME"
        resumeLabel.fontSize = 28
        resumeLabel.fontColor = .white
        resumeLabel.verticalAlignmentMode = .center
        resumeButton.addChild(resumeLabel)
        
        overlay.addChild(resumeButton)
        
        // Pulsante QUIT
        let quitButton = SKShapeNode(rectOf: CGSize(width: 250, height: 70), cornerRadius: 10)
        quitButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        quitButton.strokeColor = UIColor.red.withAlphaComponent(0.8)
        quitButton.lineWidth = 3
        quitButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 100)
        quitButton.name = "quitButton"
        
        let quitLabel = SKLabelNode(fontNamed: fontName)
        quitLabel.text = "QUIT"
        quitLabel.fontSize = 28
        quitLabel.fontColor = UIColor.red.withAlphaComponent(0.8)
        quitLabel.verticalAlignmentMode = .center
        quitButton.addChild(quitLabel)
        
        overlay.addChild(quitButton)
        
        // Animazione fade in
        overlay.alpha = 0
        hudLayer.addChild(overlay)
        overlay.run(SKAction.fadeIn(withDuration: 0.2))
        
        pauseOverlay = overlay
        
        print("⏸️ Game paused")
    }
    
    private func resumeGame() {
        isGamePaused = false
        
        // Ripristina la fisica
        physicsWorld.speed = 1
        
        // Rimuovi overlay con animazione
        if let overlay = pauseOverlay {
            overlay.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))
            pauseOverlay = nil
        }
        
        print("▶️ Game resumed")
    }
    
    private func quitToMenu() {
        // Transizione al menu principale
        let transition = SKTransition.fade(withDuration: 0.5)
        let menuScene = MainMenuScene(size: size)
        menuScene.scaleMode = scaleMode
        view?.presentScene(menuScene, transition: transition)
        
        print("🏠 Returning to main menu")
    }
    
    private func retryGame() {
        // Riavvia il gioco
        let newGame = GameScene(size: size)
        newGame.scaleMode = scaleMode
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(newGame, transition: transition)
        
        print("🔄 Restarting game")
    }
    
    // MARK: - Planet Health System
    private func updatePlanetHealthLabel() {
        planetHealthLabel.text = "\(planetHealth)/\(maxPlanetHealth)"
    }
    
    private func flashPlanet() {
        // Effetto flash rosso sul pianeta quando viene colpito
        let originalColor = planet.fillColor
        planet.fillColor = .red
        
        let wait = SKAction.wait(forDuration: 0.1)
        let restore = SKAction.run { [weak self] in
            self?.planet.fillColor = originalColor
        }
        planet.run(SKAction.sequence([wait, restore]))
    }
    
    private func gameOver() {
        isGamePaused = true
        physicsWorld.speed = 0
        
        // Esplosione finale del pianeta
        createExplosionParticles(at: planet.position, color: .red)
        planet.alpha = 0
        
        // Overlay scuro
        let overlay = SKNode()
        overlay.name = "gameOverOverlay"
        overlay.zPosition = 3000
        
        let background = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.8), size: size)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(background)
        
        // Testo GAME OVER
        let fontName = "AvenirNext-Bold"
        let gameOverLabel = SKLabelNode(fontNamed: fontName)
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 72
        gameOverLabel.fontColor = .red
        gameOverLabel.horizontalAlignmentMode = .center
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        overlay.addChild(gameOverLabel)
        
        // Score finale
        let finalScoreLabel = SKLabelNode(fontNamed: fontName)
        finalScoreLabel.text = "FINAL SCORE: \(score)"
        finalScoreLabel.fontSize = 32
        finalScoreLabel.fontColor = .white
        finalScoreLabel.horizontalAlignmentMode = .center
        finalScoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 30)
        overlay.addChild(finalScoreLabel)
        
        // Wave raggiunta
        let waveLabel = SKLabelNode(fontNamed: fontName)
        waveLabel.text = "WAVE \(currentWave)"
        waveLabel.fontSize = 24
        waveLabel.fontColor = UIColor.white.withAlphaComponent(0.7)
        waveLabel.horizontalAlignmentMode = .center
        waveLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 70)
        overlay.addChild(waveLabel)
        
        // Pulsante RETRY
        let retryButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        retryButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        retryButton.strokeColor = .white
        retryButton.lineWidth = 3
        retryButton.position = CGPoint(x: size.width / 2 - 110, y: size.height / 2 - 140)
        retryButton.name = "retryButton"
        
        let retryLabel = SKLabelNode(fontNamed: fontName)
        retryLabel.text = "RETRY"
        retryLabel.fontSize = 24
        retryLabel.fontColor = .white
        retryLabel.verticalAlignmentMode = .center
        retryButton.addChild(retryLabel)
        overlay.addChild(retryButton)
        
        // Pulsante MENU
        let menuButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        menuButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        menuButton.strokeColor = .white
        menuButton.lineWidth = 3
        menuButton.position = CGPoint(x: size.width / 2 + 110, y: size.height / 2 - 140)
        menuButton.name = "menuButton"
        
        let menuLabel = SKLabelNode(fontNamed: fontName)
        menuLabel.text = "MENU"
        menuLabel.fontSize = 24
        menuLabel.fontColor = .white
        menuLabel.verticalAlignmentMode = .center
        menuButton.addChild(menuLabel)
        overlay.addChild(menuButton)
        
        // Fade in dell'overlay
        overlay.alpha = 0
        hudLayer.addChild(overlay)
        overlay.run(SKAction.fadeIn(withDuration: 0.5))
        
        print("💀 GAME OVER - Final Score: \(score), Wave: \(currentWave)")
    }
}
