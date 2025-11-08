//
//  GameScene.swift
//  Orbitica Core - GRAVITY SHIELD
//
//  Created by Alessandro Grassi on 07/11/25.
//

import SpriteKit
import GameplayKit
import AVFoundation

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none: UInt32 = 0
    static let planet: UInt32 = 0b1        // 1
    static let atmosphere: UInt32 = 0b10   // 2
    static let player: UInt32 = 0b100      // 4
    static let asteroid: UInt32 = 0b1000   // 8
    static let projectile: UInt32 = 0b10000 // 16
    static let powerup: UInt32 = 0b100000 // 32
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

// MARK: - Asteroid Type
enum AsteroidType {
    case normal(AsteroidSize)    // Asteroide normale (comportamento attuale)
    case fast(AsteroidSize)      // Asteroide veloce (2x velocità)
    case armored(AsteroidSize)   // Asteroide corazzato (2x vita, colore grigio)
    case explosive(AsteroidSize) // Asteroide esplosivo (esplode in più frammenti)
    case heavy(AsteroidSize)     // Asteroide pesante (verde acido, 2x vita, 2x danno atmosfera, linea spessa)
    
    var size: AsteroidSize {
        switch self {
        case .normal(let size), .fast(let size), .armored(let size), .explosive(let size), .heavy(let size):
            return size
        }
    }
    
    var color: UIColor {
        switch self {
        case .normal: return .white
        case .fast: return .cyan
        case .armored: return .gray
        case .explosive: return .red
        case .heavy: return UIColor(red: 0.5, green: 1.0, blue: 0.0, alpha: 1.0)  // Verde acido
        }
    }
    
    var lineWidth: CGFloat {
        switch self {
        case .heavy: return 6.0  // Triplo spessore per distinguerlo chiaramente
        default: return 2.0
        }
    }
    
    var speedMultiplier: CGFloat {
        switch self {
        case .fast: return 2.4  // +20% velocità rispetto a prima (era 2.0)
        default: return 1.0
        }
    }
    
    var healthMultiplier: Int {
        switch self {
        case .armored: return 2  // Armored richiede 2 colpi
        case .heavy: return 4     // Heavy molto resistente - richiede 4 colpi
        default: return 1
        }
    }
    
    var atmosphereDamageMultiplier: CGFloat {
        switch self {
        case .heavy: return 4.0  // Quadruplo danno all'atmosfera (raddoppiato da 2.0)
        default: return 1.0
        }
    }
}

// MARK: - Wave Configuration
struct WaveConfig {
    let waveNumber: Int
    let asteroidSpawns: [(type: AsteroidType, count: Int)]
    let spawnInterval: TimeInterval
    
    var totalAsteroids: Int {
        return asteroidSpawns.reduce(0) { $0 + $1.count }
    }
}

// MARK: - Game Scene
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Debug flag - imposta su true per abilitare i log
    private let debugMode: Bool = false
    
    // Helper per log condizionali
    private func debugLog(_ message: String) {
        if debugMode {
            print(message)
        }
    }
    
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
    
    // Orbital Ring (grapple system) - 3 anelli concentrici
    private var orbitalRing1: SKShapeNode!  // Anello interno
    private var orbitalRing2: SKShapeNode!  // Anello medio
    private var orbitalRing3: SKShapeNode!  // Anello esterno
    private let orbitalRing1Radius: CGFloat = 200
    private let orbitalRing2Radius: CGFloat = 280  // +80px dal precedente
    private let orbitalRing3Radius: CGFloat = 360  // +80px dal precedente
    private let orbitalBaseAngularVelocity: CGFloat = 0.15  // velocità base (anello 1)
    private let orbitalGrappleThreshold: CGFloat = 8    // distanza per aggancio
    private let orbitalDetachForce: CGFloat = 80        // forza necessaria per sganciarsi (ridotta da 200)
    private var isGrappledToOrbit: Bool = false
    private var orbitalGrappleStrength: CGFloat = 0.0   // 0.0 = libero, 1.0 = completamente agganciato
    private var currentOrbitalRing: Int = 0  // 1, 2, o 3 - quale anello è agganciato
    
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
    
    // Parallax background layers
    private var starsLayer1: SKNode!  // Stelle più lontane (movimento lento)
    private var starsLayer2: SKNode!  // Stelle medie
    private var starsLayer3: SKNode!  // Stelle più vicine (movimento veloce)
    
    // Play field size multiplier (3x larger than screen)
    private let playFieldMultiplier: CGFloat = 3.0
    
    // Dynamic camera zoom (distanze separate per H e V)
    private let zoomDistanceNearH: CGFloat = 400     // Distanza orizzontale - primo zoom out
    private let zoomDistanceFarH: CGFloat = 800      // Distanza orizzontale - secondo zoom out
    private let zoomDistanceNearV: CGFloat = 300     // Distanza verticale - primo zoom out (più corta)
    private let zoomDistanceFarV: CGFloat = 600      // Distanza verticale - secondo zoom out (più corta)
    private let zoomLevelClose: CGFloat = 1.0        // Zoom normale (vicino)
    private let zoomLevelMedium: CGFloat = 1.6       // Zoom medio (più lontano)
    private let zoomLevelFar: CGFloat = 2.5          // Zoom massimo (molto lontano)
    private var currentZoomLevel: CGFloat = 1.0
    
    // Controls
    private var joystick: JoystickNode!
    private var fireButton: FireButtonNode!
    private var joystickDirection = CGVector.zero
    private var isFiring = false
    private var lastFireTime: TimeInterval = 0
    private let fireRate: TimeInterval = 0.45  // Triplicato da 0.15 a 0.45 (1/3 della frequenza)
    // Runtime-adjustable fire rate (used for power-ups)
    private var currentFireRate: TimeInterval = 0.45
    private var baseFireRate: TimeInterval { return fireRate }
    
    // Projectiles
    private var projectiles: [SKShapeNode] = []
    // Projectile base sizes (can be modified by BigAmmo power-up)
    private var projectileBaseSize = CGSize(width: 3, height: 12)
    private var projectileWidthMultiplier: CGFloat = 1.0 // BigAmmo sets to 4x width
    private var projectileHeightMultiplier: CGFloat = 1.0 // BigAmmo sets to 2x height
    private var projectileDamageMultiplier: CGFloat = 1.0 // BigAmmo sets to 4x damage
    
    // Asteroids
    private var asteroids: [SKShapeNode] = []
    private var lastAsteroidSpawnTime: TimeInterval = 0
    private let asteroidSpawnInterval: TimeInterval = 3.0  // Ogni 3 secondi
    
    // Wave system
    private var currentWave: Int = 0
    private var isWaveActive: Bool = false
    private var asteroidsToSpawnInWave: Int = 0
    private var asteroidsSpawnedInWave: Int = 0
    private var currentWaveConfig: WaveConfig?
    private var asteroidSpawnQueue: [AsteroidType] = []  // Coda di spawn
    private var asteroidGravityMultiplier: CGFloat = 1.4375  // Base: 1.25 + 15% = 1.4375, aumenta del 5% per wave
    
    // Collision tracking
    private var lastCollisionTime: TimeInterval = 0
    private let collisionCooldown: TimeInterval = 0.5  // 500ms tra collisioni
    private var lastUpdateTime: TimeInterval = 0  // Traccia l'ultimo currentTime da update
    
    // Score
    private var score: Int = 0
    private var scoreLabel: SKLabelNode!
    // Power-up HUD label (sotto il punteggio in alto a destra)
    private var powerupLabel: SKLabelNode!

    // Power-up state
    private var vulcanActive: Bool = false
    private var bigAmmoActive: Bool = false
    private var atmosphereActive: Bool = false
    private var activePowerupEndTime: TimeInterval = 0
    
    // Pause system
    private var isGamePaused: Bool = false
    private var pauseButton: SKShapeNode!
    private var pauseOverlay: SKNode?
    
    // Particle texture cache
    private var particleTexture: SKTexture?
    
    // Audio system
    private var musicPlayerCurrent: AVAudioPlayer?
    private var musicPlayerNext: AVAudioPlayer?
    private var crossfadeTimer: Timer?
    
    // Sound effects
    private var shootSound1: AVAudioPlayer?  // Sparo normale
    private var shootSound2: AVAudioPlayer?  // Sparo big ammo
    private var shootSound3: AVAudioPlayer?  // Sparo vulcan
    
    // MARK: - Setup
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // FISICA: Configura la fisica della scena
        physicsWorld.gravity = .zero  // Niente gravità di default, la applichiamo manualmente
        physicsWorld.contactDelegate = self
        
        debugLog("=== GRAVITY SHIELD ===")
        debugLog("Scene size: \(size)")
        debugLog("======================")
        
        // Crea texture per particelle
        createParticleTexture()
        
        // Carica suoni degli spari
        loadShootSounds()
        
        setupLayers()
        setupCamera()
        setupPlanet()
        setupAtmosphere()
        setupOrbitalRing()
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
        debugLog("✅ Particle texture created")
    }
    
    private func loadShootSounds() {
        // Carica i 3 suoni di sparo - i file sono nella root del bundle
        if let url1 = Bundle.main.url(forResource: "sparo1", withExtension: "m4a") {
            print("🔊 Found sparo1 at: \(url1)")
            shootSound1 = try? AVAudioPlayer(contentsOf: url1)
            shootSound1?.prepareToPlay()
            print("🔊 sparo1 loaded, volume: \(shootSound1?.volume ?? 0)")
        } else {
            print("❌ sparo1 NOT FOUND")
        }
        if let url2 = Bundle.main.url(forResource: "sparo2", withExtension: "m4a") {
            print("🔊 Found sparo2 at: \(url2)")
            shootSound2 = try? AVAudioPlayer(contentsOf: url2)
            shootSound2?.prepareToPlay()
        } else {
            print("❌ sparo2 NOT FOUND")
        }
        if let url3 = Bundle.main.url(forResource: "sparo3", withExtension: "m4a") {
            print("🔊 Found sparo3 at: \(url3)")
            shootSound3 = try? AVAudioPlayer(contentsOf: url3)
            shootSound3?.prepareToPlay()
        } else {
            print("❌ sparo3 NOT FOUND")
        }
    }
    
    private func playShootSound() {
        // Scegli il suono in base ai power-up attivi
        let sound: AVAudioPlayer?
        
        if bigAmmoActive {
            sound = shootSound2  // Big Ammo
        } else if vulcanActive {
            sound = shootSound3  // Vulcan
        } else {
            sound = shootSound1  // Normale
        }
        
        // Riavvia dall'inizio se è già in riproduzione
        sound?.currentTime = 0
        print("🔊 Playing shoot sound, volume: \(sound?.volume ?? 0), isPlaying: \(sound?.isPlaying ?? false)")
        sound?.play()
    }
    
    private func setupLayers() {
        // Background parallax layers - DIETRO a tutto
        setupParallaxBackground()
        
        // World layer: contiene tutti gli oggetti di gioco (player, pianeta, asteroidi, etc)
        // Posizionato al centro della scena - le coordinate del world sono relative al centro
        worldLayer = SKNode()
        worldLayer.position = .zero  // Nessun offset, usiamo coordinate assolute
        addChild(worldLayer)
        
        debugLog("✅ World layer created")
    }
    
    private func setupParallaxBackground() {
        // Crea 3 layer di stelle con parallasse
        starsLayer1 = createStarsLayer(starCount: 80, alpha: 0.15, zPosition: -30)  // Lontane, quasi invisibili
        starsLayer2 = createStarsLayer(starCount: 60, alpha: 0.25, zPosition: -20)  // Medie
        starsLayer3 = createStarsLayer(starCount: 40, alpha: 0.35, zPosition: -10)  // Vicine, più visibili
        
        addChild(starsLayer1)
        addChild(starsLayer2)
        addChild(starsLayer3)
        
        debugLog("✅ Parallax background created")
    }
    
    private func createStarsLayer(starCount: Int, alpha: CGFloat, zPosition: CGFloat) -> SKNode {
        let layer = SKNode()
        layer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        layer.zPosition = zPosition
        
        // Area più grande del viewport per supportare il movimento
        let areaWidth = size.width * playFieldMultiplier
        let areaHeight = size.height * playFieldMultiplier
        
        for _ in 0..<starCount {
            // Posizione random nell'area estesa
            let x = CGFloat.random(in: -areaWidth/2...areaWidth/2)
            let y = CGFloat.random(in: -areaHeight/2...areaHeight/2)
            
            // Stella come piccolo cerchio
            let starSize = CGFloat.random(in: 1.0...2.5)
            let star = SKShapeNode(circleOfRadius: starSize)
            star.fillColor = UIColor.white.withAlphaComponent(alpha)
            star.strokeColor = .clear
            star.position = CGPoint(x: x, y: y)
            star.glowWidth = 0.5  // Leggero glow
            
            layer.addChild(star)
        }
        
        return layer
    }
    
    private func setupCamera() {
        // Camera fissa al centro del mondo (dove sarà il pianeta)
        gameCamera = SKCameraNode()
        gameCamera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(gameCamera)  // Attacca alla scene, non al worldLayer
        camera = gameCamera
        
        // HUD layer: attaccato alla camera per essere immune allo zoom
        // Le coordinate sono relative alla camera (centrate)
        hudLayer = SKNode()
        gameCamera.addChild(hudLayer)
        
        debugLog("✅ Camera created at center with HUD layer (immune to zoom)")
    }
    
    private func setupPlanet() {
        // Crea un path irregolare simile agli asteroidi ma più circolare
        let planetPath = createIrregularPlanetPath(radius: planetRadius)
        planet = SKShapeNode(path: planetPath)
        planet.fillColor = .white
        planet.strokeColor = .clear
        planet.name = "planet"
        planet.zPosition = 1
        planet.position = CGPoint(x: size.width / 2, y: size.height / 2)  // Centro dello schermo
        
        // Physics body per il pianeta (mantiene collisione circolare perfetta)
        let planetBody = SKPhysicsBody(circleOfRadius: planetRadius)
        planetBody.isDynamic = false
        planetBody.categoryBitMask = PhysicsCategory.planet
        planetBody.contactTestBitMask = PhysicsCategory.asteroid
        planetBody.collisionBitMask = 0
        planet.physicsBody = planetBody
        
        // Rotazione lenta antioraria del pianeta
        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 60.0) // Un giro completo in 60 secondi
        planet.run(SKAction.repeatForever(rotateAction))
        
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
        
        debugLog("✅ Planet created at: \(planet.position)")
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
        
        debugLog("✅ Atmosphere created with radius: \(atmosphereRadius)")
    }
    
    private func setupOrbitalRing() {
        let centerPosition = CGPoint(x: size.width / 2, y: size.height / 2)
        let dashPattern: [CGFloat] = [10, 10]
        
        // ANELLO 1 (interno) - velocità base
        let path1 = CGMutablePath()
        path1.addArc(center: .zero, radius: orbitalRing1Radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        orbitalRing1 = SKShapeNode(path: path1)
        orbitalRing1.strokeColor = UIColor.white.withAlphaComponent(0.25)
        orbitalRing1.lineWidth = 1
        orbitalRing1.fillColor = .clear
        orbitalRing1.name = "orbitalRing1"
        orbitalRing1.zPosition = 1
        orbitalRing1.position = centerPosition
        orbitalRing1.path = path1.copy(dashingWithPhase: 0, lengths: dashPattern)
        worldLayer.addChild(orbitalRing1)
        
        let velocity1 = orbitalBaseAngularVelocity
        let rotateAction1 = SKAction.rotate(byAngle: .pi * 2, duration: 1.0 / velocity1 * 2 * .pi)
        orbitalRing1.run(SKAction.repeatForever(rotateAction1))
        
        // ANELLO 2 (medio) - velocità +33%
        let path2 = CGMutablePath()
        path2.addArc(center: .zero, radius: orbitalRing2Radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        orbitalRing2 = SKShapeNode(path: path2)
        orbitalRing2.strokeColor = UIColor.white.withAlphaComponent(0.25)
        orbitalRing2.lineWidth = 1
        orbitalRing2.fillColor = .clear
        orbitalRing2.name = "orbitalRing2"
        orbitalRing2.zPosition = 1
        orbitalRing2.position = centerPosition
        orbitalRing2.path = path2.copy(dashingWithPhase: 0, lengths: dashPattern)
        worldLayer.addChild(orbitalRing2)
        
        let velocity2 = orbitalBaseAngularVelocity * 1.33  // +33%
        let rotateAction2 = SKAction.rotate(byAngle: .pi * 2, duration: 1.0 / velocity2 * 2 * .pi)
        orbitalRing2.run(SKAction.repeatForever(rotateAction2))
        
        // ANELLO 3 (esterno) - velocità +66% (33% * 2)
        let path3 = CGMutablePath()
        path3.addArc(center: .zero, radius: orbitalRing3Radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        orbitalRing3 = SKShapeNode(path: path3)
        orbitalRing3.strokeColor = UIColor.white.withAlphaComponent(0.25)
        orbitalRing3.lineWidth = 1
        orbitalRing3.fillColor = .clear
        orbitalRing3.name = "orbitalRing3"
        orbitalRing3.zPosition = 1
        orbitalRing3.position = centerPosition
        orbitalRing3.path = path3.copy(dashingWithPhase: 0, lengths: dashPattern)
        worldLayer.addChild(orbitalRing3)
        
        let velocity3 = orbitalBaseAngularVelocity * 1.77  // +77% (1.33 * 1.33)
        let rotateAction3 = SKAction.rotate(byAngle: .pi * 2, duration: 1.0 / velocity3 * 2 * .pi)
        orbitalRing3.run(SKAction.repeatForever(rotateAction3))
        
        debugLog("✅ Orbital rings created: R1=\(orbitalRing1Radius) (v=\(velocity1)), R2=\(orbitalRing2Radius) (v=\(velocity2)), R3=\(orbitalRing3Radius) (v=\(velocity3))")
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
        
        debugLog("✅ Player created at: \(player.position)")
    }
    
    private func setupControls() {
        debugLog("=== CONTROLS SETUP START ===")
        debugLog("Scene size: \(size)")
        
        // Coordinate relative alla camera (centrata sullo schermo)
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        
        // Joystick - fisso in basso a sinistra (nell'HUD layer)
        joystick = JoystickNode(baseRadius: 70, thumbRadius: 30)
        joystick.position = CGPoint(x: 120 - halfWidth, y: 120 - halfHeight)
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
        fireButton.position = CGPoint(x: size.width - 120 - halfWidth, y: 120 - halfHeight)
        fireButton.zPosition = 1000
        fireButton.onPress = { [weak self] in
            self?.isFiring = true
        }
        fireButton.onRelease = { [weak self] in
            self?.isFiring = false
        }
        hudLayer.addChild(fireButton)
        
        debugLog("✅ Controls in HUD layer (unaffected by camera zoom)")
        debugLog("=== CONTROLS SETUP END ===")
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
        
        // Coordinate relative alla camera (centrata sullo schermo)
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        
        scoreLabel = SKLabelNode(fontNamed: fontName)
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = .white
        scoreLabel.text = "0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.position = CGPoint(x: size.width - 20 - halfWidth, y: size.height - 20 - halfHeight)
        scoreLabel.zPosition = 1000
        
        hudLayer.addChild(scoreLabel)

    // Power-up label sotto il punteggio (vuoto finché non c'è un power-up)
    powerupLabel = SKLabelNode(fontNamed: fontName)
    powerupLabel.fontSize = 18
    powerupLabel.fontColor = .yellow
    powerupLabel.text = ""
    powerupLabel.horizontalAlignmentMode = .right
    powerupLabel.verticalAlignmentMode = .top
    powerupLabel.position = CGPoint(x: size.width - 20 - halfWidth, y: size.height - 60 - halfHeight)
    powerupLabel.zPosition = 1000
    hudLayer.addChild(powerupLabel)
        
        debugLog("✅ Score label created with font: \(fontName)")
    }
    
    private func setupPauseButton() {
        // Pulsante pause in alto a sinistra
        let buttonSize: CGFloat = 50
        
        // Coordinate relative alla camera (centrata sullo schermo)
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        
        pauseButton = SKShapeNode(rectOf: CGSize(width: buttonSize, height: buttonSize), cornerRadius: 8)
        pauseButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        pauseButton.strokeColor = .white
        pauseButton.lineWidth = 2
        pauseButton.position = CGPoint(x: 80 - halfWidth, y: size.height - 30 - halfHeight)
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
        
        debugLog("✅ Pause button created")
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
                if node.name == "saveScoreButton" {
                    showInitialEntryScene()
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
        
        lastUpdateTime = currentTime  // Salva per usarlo in didBegin
        
        applyGravity()
        limitAsteroidSpeed()  // Limita velocità asteroidi
        updateOrbitalGrapple()  // Gestisce aggancio/sgancio orbital ring
        updatePlayerMovement()
        updatePlayerShooting(currentTime)
        updateCameraZoom()  // Aggiorna zoom dinamico basato su distanza
        updateParallaxBackground()  // Muove le stelle in parallasse
        // Gestione timer power-up
        if activePowerupEndTime > 0 {
            let remaining = max(0, activePowerupEndTime - currentTime)
            let remainingFormatted = String(format: "%.2f", remaining)
            
            if vulcanActive {
                powerupLabel.text = "Vulcan \(remainingFormatted)s"
            } else if bigAmmoActive {
                powerupLabel.text = "BigAmmo \(remainingFormatted)s"
            } else if atmosphereActive {
                // Per Atmosphere: solo nome, NO timer (timer solo per tracking interno)
                powerupLabel.text = "Atmosphere"
            }

            if currentTime >= activePowerupEndTime {
                // Expire all temporary effects
                deactivatePowerups()
            }
        }
        spawnAsteroidsForWave(currentTime)
        wrapPlayerAroundScreen()
        wrapAsteroidsAroundScreen()
        cleanupProjectiles()
        cleanupAsteroids()
        checkWaveComplete()
    }
    
    private func wrapPlayerAroundScreen() {
        let playFieldWidth = size.width * playFieldMultiplier
        let playFieldHeight = size.height * playFieldMultiplier
        let minX = size.width / 2 - playFieldWidth / 2
        let maxX = size.width / 2 + playFieldWidth / 2
        let minY = size.height / 2 - playFieldHeight / 2
        let maxY = size.height / 2 + playFieldHeight / 2
        
        // Wrap orizzontale
        if player.position.x < minX {
            player.position.x = maxX
        } else if player.position.x > maxX {
            player.position.x = minX
        }
        
        // Wrap verticale
        if player.position.y < minY {
            player.position.y = maxY
        } else if player.position.y > maxY {
            player.position.y = minY
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
        
        if currentTime - lastFireTime >= currentFireRate {
            fireProjectile()
            lastFireTime = currentTime
        }
    }
    
    private func fireProjectile() {
        // Riproduci il suono di sparo
        playShootSound()
        
        // Proiettile a forma di linea spessa (rettangolo)
        let usedSize = CGSize(width: projectileBaseSize.width * projectileWidthMultiplier,
                              height: projectileBaseSize.height * projectileHeightMultiplier)
        let projectile = SKShapeNode(rectOf: usedSize, cornerRadius: 1)
        
        // Colora le munizioni in base al power-up attivo
        if vulcanActive {
            projectile.fillColor = .red
            projectile.strokeColor = .red
        } else if bigAmmoActive {
            projectile.fillColor = .green
            projectile.strokeColor = .green
        } else {
            projectile.fillColor = .white
            projectile.strokeColor = .white
        }
        projectile.lineWidth = 0
        
        // Physics body per il proiettile
        projectile.physicsBody = SKPhysicsBody(rectangleOf: usedSize)
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
        
        // Salva il moltiplicatore di danno nel userData
        projectile.userData = NSMutableDictionary()
        projectile.userData?["damageMultiplier"] = projectileDamageMultiplier
        
        // EFFETTO SCIA: Particelle che seguono il proiettile
        let trail = SKEmitterNode()
        trail.particleTexture = particleTexture
        
        // Configura scia in base al power-up attivo
        if bigAmmoActive {
            trail.particleBirthRate = 250          // 3x più densa (era 80)
            trail.particleLifetime = 0.8           // 2x più lunga (era 0.4)
            trail.particleSpeed = 50               // Più veloce
            trail.particleSpeedRange = 25
            trail.particleScale = 1.2              // 4x più grande (era 0.4) - proporzionato al proiettile 4x
            trail.particleScaleRange = 0.6
            trail.particleColor = .green           // Verde per BigAmmo
        } else if vulcanActive {
            trail.particleBirthRate = 120          // Scia più densa per Vulcan
            trail.particleLifetime = 0.5
            trail.particleSpeed = 40
            trail.particleSpeedRange = 20
            trail.particleScale = 0.25
            trail.particleScaleRange = 0.12
            trail.particleColor = .red             // Rosso per Vulcan
        } else {
            trail.particleBirthRate = 80
            trail.particleLifetime = 0.4
            trail.particleSpeed = 30
            trail.particleSpeedRange = 15
            trail.particleScale = 0.2
            trail.particleScaleRange = 0.1
            trail.particleColor = .white
        }
        
        trail.numParticlesToEmit = 0  // Continua finché esiste
        trail.emissionAngle = angle - .pi  // Direzione opposta al movimento
        trail.emissionAngleRange = 0.2
        trail.particleScaleSpeed = -0.5
        trail.particleAlpha = 0.8
        trail.particleAlphaSpeed = -2.0
        trail.particleBlendMode = .add
        trail.particleZPosition = -1
        trail.targetNode = worldLayer  // Le particelle rimangono nel world
        projectile.addChild(trail)
        
        debugLog("☄️ Projectile fired with trail")
        
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
        
        debugLog("💥 Fired projectile from: \(projectile.position)")
    }
    
    private func cleanupProjectiles() {
        projectiles.removeAll { $0.parent == nil }
    }
    
    // MARK: - Gravity System
    private func applyGravity() {
        // Applica gravità al player (ridotta del 5%)
        if let playerBody = player.physicsBody {
            applyGravityToNode(node: player, body: playerBody, multiplier: 0.95)
        }
        
        // Applica gravità agli asteroidi (aumenta del 5% per ogni wave)
        for asteroid in asteroids {
            if let asteroidBody = asteroid.physicsBody {
                applyGravityToNode(node: asteroid, body: asteroidBody, multiplier: asteroidGravityMultiplier)
            }
        }
        
        // Applica gravità ai power-up (normale)
        worldLayer.enumerateChildNodes(withName: "powerup_*") { node, _ in
            if let powerupBody = node.physicsBody {
                self.applyGravityToNode(node: node, body: powerupBody, multiplier: 1.0)
            }
        }
    }
    
    private func applyGravityToNode(node: SKNode, body: SKPhysicsBody, multiplier: CGFloat) {
        // Calcola distanza dal pianeta
        let dx = planet.position.x - node.position.x
        let dy = planet.position.y - node.position.y
        let distanceSquared = dx * dx + dy * dy
        let distance = sqrt(distanceSquared)
        
        // Evita divisione per zero e collisione col pianeta
        guard distance > planetRadius else { return }
        
        // Formula gravitazionale: F = G * m1 * m2 / r²
        // Moltiplicata per il fattore specifico dell'oggetto
        let force = gravitationalConstant * planetMass * body.mass / distanceSquared * multiplier
        
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
    
    private func updateOrbitalGrapple() {
        guard let playerBody = player.physicsBody else { return }
        
        // Calcola distanza dal centro del pianeta
        let planetCenter = planet.position
        let dx = player.position.x - planetCenter.x
        let dy = player.position.y - planetCenter.y
        let distanceFromCenter = sqrt(dx * dx + dy * dy)
        
        // Trova l'anello più vicino
        let distanceFromRing1 = abs(distanceFromCenter - orbitalRing1Radius)
        let distanceFromRing2 = abs(distanceFromCenter - orbitalRing2Radius)
        let distanceFromRing3 = abs(distanceFromCenter - orbitalRing3Radius)
        
        let minDistance = min(distanceFromRing1, distanceFromRing2, distanceFromRing3)
        let closestRing: Int
        let closestRingRadius: CGFloat
        let closestRingVelocity: CGFloat
        let closestRingNode: SKShapeNode
        
        if minDistance == distanceFromRing1 {
            closestRing = 1
            closestRingRadius = orbitalRing1Radius
            closestRingVelocity = orbitalBaseAngularVelocity
            closestRingNode = orbitalRing1
        } else if minDistance == distanceFromRing2 {
            closestRing = 2
            closestRingRadius = orbitalRing2Radius
            closestRingVelocity = orbitalBaseAngularVelocity * 1.33
            closestRingNode = orbitalRing2
        } else {
            closestRing = 3
            closestRingRadius = orbitalRing3Radius
            closestRingVelocity = orbitalBaseAngularVelocity * 1.77
            closestRingNode = orbitalRing3
        }
        
        let distanceFromRing = minDistance
        
        // AGGANCIO GRADUALE: più sei vicino, più sei attratto
        if distanceFromRing < orbitalGrappleThreshold {
            if !isGrappledToOrbit || currentOrbitalRing != closestRing {
                isGrappledToOrbit = true
                currentOrbitalRing = closestRing
                debugLog("🔗 Grappling to orbital ring \(closestRing)...")
            }
            
            // Controlla se il giocatore sta spingendo forte (tentativo di sgancio)
            let thrustMagnitude = sqrt(joystickDirection.dx * joystickDirection.dx + joystickDirection.dy * joystickDirection.dy)
            let isThrusting = thrustMagnitude > 0.25
            
            // Aumenta gradualmente la forza di aggancio solo se NON sta spingendo
            if !isThrusting {
                let targetStrength: CGFloat = 1.0 - (distanceFromRing / orbitalGrappleThreshold)
                let transitionSpeed: CGFloat = 0.08
                orbitalGrappleStrength += (targetStrength - orbitalGrappleStrength) * transitionSpeed
            }
            // Se sta spingendo, l'aggancio non si rafforza (si indebolisce solo nella sezione sgancio manuale)
            
            // Feedback visivo graduale - solo sull'anello corrente
            let visualAlpha = 0.25 + (0.35 * orbitalGrappleStrength)  // Da 0.25 a 0.6
            let visualWidth = 1.0 + (1.0 * orbitalGrappleStrength)    // Da 1 a 2
            closestRingNode.strokeColor = UIColor.cyan.withAlphaComponent(visualAlpha)
            closestRingNode.lineWidth = visualWidth
            
            // Ripristina gli altri anelli
            if closestRing != 1 {
                orbitalRing1.strokeColor = UIColor.white.withAlphaComponent(0.25)
                orbitalRing1.lineWidth = 1
            }
            if closestRing != 2 {
                orbitalRing2.strokeColor = UIColor.white.withAlphaComponent(0.25)
                orbitalRing2.lineWidth = 1
            }
            if closestRing != 3 {
                orbitalRing3.strokeColor = UIColor.white.withAlphaComponent(0.25)
                orbitalRing3.lineWidth = 1
            }
            
        } else if isGrappledToOrbit {
            // Troppo lontano: diminuisci la forza gradualmente
            orbitalGrappleStrength -= 0.05
            
            if orbitalGrappleStrength <= 0 {
                // Sgancio completo
                isGrappledToOrbit = false
                orbitalGrappleStrength = 0
                currentOrbitalRing = 0
                
                // Ripristina tutti gli anelli
                orbitalRing1.strokeColor = UIColor.white.withAlphaComponent(0.25)
                orbitalRing1.lineWidth = 1
                orbitalRing2.strokeColor = UIColor.white.withAlphaComponent(0.25)
                orbitalRing2.lineWidth = 1
                orbitalRing3.strokeColor = UIColor.white.withAlphaComponent(0.25)
                orbitalRing3.lineWidth = 1
                
                debugLog("🔓 Detached from orbital ring (distance)")
                return
            }
        }
        
        // SGANCIO MANUALE: qualsiasi spinta forte del joystick sgancia
        if isGrappledToOrbit && orbitalGrappleStrength > 0.2 {
            let thrustDirection = joystickDirection
            let forceMagnitude = sqrt(thrustDirection.dx * thrustDirection.dx + thrustDirection.dy * thrustDirection.dy)
            
            // Sgancio semplificato: qualsiasi spinta sopra la soglia riduce l'aggancio
            if forceMagnitude > 0.25 {  // Soglia molto bassa per facilitare lo sgancio
                orbitalGrappleStrength -= 0.35  // Sgancio molto rapido
                
                if orbitalGrappleStrength <= 0 {
                    isGrappledToOrbit = false
                    orbitalGrappleStrength = 0
                    currentOrbitalRing = 0
                    
                    // Ripristina tutti gli anelli
                    orbitalRing1.strokeColor = UIColor.white.withAlphaComponent(0.25)
                    orbitalRing1.lineWidth = 1
                    orbitalRing2.strokeColor = UIColor.white.withAlphaComponent(0.25)
                    orbitalRing2.lineWidth = 1
                    orbitalRing3.strokeColor = UIColor.white.withAlphaComponent(0.25)
                    orbitalRing3.lineWidth = 1
                    
                    debugLog("🔓 Detached from orbital ring (manual)")
                    return
                }
            }
        }
        
        // APPLICA EFFETTO ORBITALE (se c'è aggancio)
        if isGrappledToOrbit && orbitalGrappleStrength > 0 {
            // Calcola l'angolo attuale del player rispetto al centro
            let currentAngle = atan2(dy, dx)
            
            // Incrementa l'angolo in base alla velocità angolare dell'anello corrente e forza di aggancio
            let angularSpeed = closestRingVelocity * CGFloat(1.0/60.0) * orbitalGrappleStrength
            let newAngle = currentAngle + angularSpeed
            
            // Posizione target sulla circonferenza dell'anello corrente
            let targetX = planetCenter.x + cos(newAngle) * closestRingRadius
            let targetY = planetCenter.y + sin(newAngle) * closestRingRadius
            
            // Interpola tra posizione attuale e target in base alla forza di aggancio
            let currentX = player.position.x
            let currentY = player.position.y
            let newX = currentX + (targetX - currentX) * orbitalGrappleStrength
            let newY = currentY + (targetY - currentY) * orbitalGrappleStrength
            
            player.position = CGPoint(x: newX, y: newY)
            
            // Velocità tangenziale ponderata dalla forza di aggancio (usa la velocità dell'anello corrente)
            let tangentialVelocity = closestRingVelocity * closestRingRadius * orbitalGrappleStrength
            let tangentialVx = -sin(newAngle) * tangentialVelocity
            let tangentialVy = cos(newAngle) * tangentialVelocity
            
            // Mescola velocità orbitale con velocità attuale
            let currentVx = playerBody.velocity.dx
            let currentVy = playerBody.velocity.dy
            playerBody.velocity = CGVector(
                dx: currentVx + (tangentialVx - currentVx) * orbitalGrappleStrength * 0.3,
                dy: currentVy + (tangentialVy - currentVy) * orbitalGrappleStrength * 0.3
            )
        }
    }
    
    // MARK: - Wave System
    
    // Configura la wave specifica
    private func configureWave(_ wave: Int) -> WaveConfig {
        switch wave {
        case 1:
            // WAVE 1 - Solo meteoriti normali (+44% quantità totale: 6 -> 7, arrotondato da 7.2)
            return WaveConfig(
                waveNumber: 1,
                asteroidSpawns: [
                    (.normal(.large), 7)       // 7 asteroidi (+20% da 6, totale +44% dall'originale 5)
                ],
                spawnInterval: 3.0
            )
            
        case 2:
            // WAVE 2 - Introduzione medium, fast, heavy (verde) e armored (grigio) (+20%)
            return WaveConfig(
                waveNumber: 2,
                asteroidSpawns: [
                    (.normal(.large), 4),      // +1 da 3
                    (.normal(.medium), 2),
                    (.fast(.large), 1),
                    (.heavy(.large), 2),       // Verdi: 4x danno
                    (.armored(.large), 2)      // Grigi: 2x vita (stessa quantità dei verdi)
                ],
                spawnInterval: 2.8
            )
            
        case 3:
            // WAVE 3 - Mix bilanciato di tutti i tipi (+20%)
            return WaveConfig(
                waveNumber: 3,
                asteroidSpawns: [
                    (.normal(.large), 4),      // +1 da 3
                    (.fast(.large), 2),
                    (.armored(.large), 2),     // Grigi: 2x vita
                    (.heavy(.large), 2),       // Verdi: 4x danno
                    (.normal(.medium), 3)      // +1 da 2
                ],
                spawnInterval: 2.5
            )
            
        default:
            // WAVE 4+ - Progressione automatica con tutti i tipi (+20% da baseCount)
            let baseCount = 12 + (wave - 1) * 2  // +20% da 10 -> 12
            return WaveConfig(
                waveNumber: wave,
                asteroidSpawns: [
                    (.normal(.large), baseCount / 3),
                    (.fast(.large), baseCount / 3),
                    (.armored(.large), baseCount / 5),   // Grigi: 2x vita (stessa quantità dei verdi)
                    (.heavy(.large), baseCount / 5),     // Verdi: 4x danno (stessa quantità dei grigi)
                    (.normal(.medium), baseCount / 4)
                ],
                spawnInterval: max(1.5, 3.0 - CGFloat(wave) * 0.2)
            )
        }
    }
    
    private func startWave(_ wave: Int) {
        currentWave = wave
        isWaveActive = false  // Disattiva il gioco durante il messaggio
        
        // Aumenta la gravità degli asteroidi del 5% per ogni wave (dopo la prima)
        if wave > 1 {
            asteroidGravityMultiplier *= 1.05
            debugLog("🌍 Asteroid gravity increased to \(asteroidGravityMultiplier) for wave \(wave)")
        }
        
        // Avvia la musica per questa wave con crossfade
        // Alterna casualmente tra temp3 e temp4
        let musicFile = Bool.random() ? "temp3" : "temp4"
        crossfadeTo(musicFile)
        
        // Configura la wave
        currentWaveConfig = configureWave(wave)
        
        // Crea la coda di spawn
        asteroidSpawnQueue.removeAll()
        if let config = currentWaveConfig {
            for spawn in config.asteroidSpawns {
                for _ in 0..<spawn.count {
                    asteroidSpawnQueue.append(spawn.type)
                }
            }
            // Mescola la coda per variare l'ordine di spawn
            asteroidSpawnQueue.shuffle()
            
            asteroidsToSpawnInWave = config.totalAsteroids
        }
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
        
        // Background opaco dietro il messaggio (coordinate relative alla camera)
        let waveBackground = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.6), size: size)
        waveBackground.position = CGPoint.zero  // Centro della camera
        waveBackground.zPosition = 1999
        waveBackground.alpha = 0
        
        hudLayer.addChild(waveBackground)
        
        let waveMessage = SKLabelNode(fontNamed: fontName)
        waveMessage.fontSize = 64
        waveMessage.fontColor = .white
        waveMessage.text = "WAVE \(wave)"
        waveMessage.position = CGPoint.zero  // Centro della camera
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
            self?.debugLog("🌊 Wave \(wave) started - Asteroids to spawn: \(self?.asteroidsToSpawnInWave ?? 0)")
        }
        
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove, activateWave])
        waveMessage.run(sequence)
        waveBackground.run(sequence)  // Stesso effetto anche per il background
        
        debugLog("🌊 Wave \(wave) message displayed")
    }
    
    private func spawnAsteroidsForWave(_ currentTime: TimeInterval) {
        // Non spawnare se la wave non è attiva
        guard isWaveActive else { return }
        
        // Non spawnare se abbiamo già spawnato tutti gli asteroidi della wave
        guard asteroidsSpawnedInWave < asteroidsToSpawnInWave else { return }
        
        // Non spawnare se la coda è vuota
        guard !asteroidSpawnQueue.isEmpty else { return }
        
        // Usa l'intervallo di spawn della wave corrente
        let spawnInterval = currentWaveConfig?.spawnInterval ?? asteroidSpawnInterval
        guard currentTime - lastAsteroidSpawnTime > spawnInterval else { return }
        lastAsteroidSpawnTime = currentTime
        
        // Prendi il prossimo tipo dalla coda
        let asteroidType = asteroidSpawnQueue.removeFirst()
        
        // Spawna l'asteroide con il tipo specificato
        spawnAsteroid(type: asteroidType, at: nil)
        asteroidsSpawnedInWave += 1
        
        debugLog("☄️ Spawned \(asteroidType) asteroid \(asteroidsSpawnedInWave)/\(asteroidsToSpawnInWave)")
    }
    
    private func checkWaveComplete() {
        // Controlla se la wave è completa
        guard isWaveActive else { return }
        guard asteroidsSpawnedInWave >= asteroidsToSpawnInWave else { return }
        guard asteroids.isEmpty else { return }
        
        // Wave completata! Ripristina la salute del pianeta
        debugLog("🎉 Wave \(currentWave) completed!")
        
        // Ripristina la salute del pianeta al massimo
        planetHealth = maxPlanetHealth
        updatePlanetHealthLabel()
        debugLog("💚 Planet health restored to \(maxPlanetHealth)")
        
        startWave(currentWave + 1)
    }
    
    // MARK: - Asteroid Management
    
    // Overload per spawnar asteroidi con tipo specifico
    private func spawnAsteroid(type asteroidType: AsteroidType, at position: CGPoint?) {
        let asteroidSize = asteroidType.size
        
        // Crea forma a linee spezzate (stile Asteroids)
        let path = createAsteroidPath(radius: asteroidSize.radius)
        let asteroid = SKShapeNode(path: path)
        asteroid.fillColor = .clear
        asteroid.strokeColor = asteroidType.color  // Colore basato sul tipo
        asteroid.lineWidth = asteroidType.lineWidth  // Spessore basato sul tipo
        asteroid.zPosition = 5
        asteroid.name = "asteroid_\(asteroidSize.rawValue)"
        
        // Salva il tipo e la vita nell'userData
        asteroid.userData = NSMutableDictionary()
        asteroid.userData?["type"] = asteroidType
        asteroid.userData?["health"] = asteroidType.healthMultiplier
        asteroid.userData?["size"] = asteroidSize.rawValue
        
        // Posizione
        if let pos = position {
            asteroid.position = pos
        } else {
            // Posizione casuale ai bordi del campo di gioco esteso (3x)
            let playFieldWidth = self.size.width * playFieldMultiplier
            let playFieldHeight = self.size.height * playFieldMultiplier
            let minX = self.size.width / 2 - playFieldWidth / 2
            let maxX = self.size.width / 2 + playFieldWidth / 2
            let minY = self.size.height / 2 - playFieldHeight / 2
            let maxY = self.size.height / 2 + playFieldHeight / 2
            let margin: CGFloat = 50
            
            let edge = Int.random(in: 0...3)
            switch edge {
            case 0: // Top
                asteroid.position = CGPoint(x: CGFloat.random(in: minX...maxX), y: maxY + margin)
            case 1: // Right
                asteroid.position = CGPoint(x: maxX + margin, y: CGFloat.random(in: minY...maxY))
            case 2: // Bottom
                asteroid.position = CGPoint(x: CGFloat.random(in: minX...maxX), y: minY - margin)
            default: // Left
                asteroid.position = CGPoint(x: minX - margin, y: CGFloat.random(in: minY...maxY))
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
        
        // Velocità iniziale basata sul tipo
        if position == nil {
            let baseSpeed: CGFloat = 50
            let speed = baseSpeed * asteroidType.speedMultiplier
            let randomVelocity = CGVector(
                dx: CGFloat.random(in: -speed...speed),
                dy: CGFloat.random(in: -speed...speed)
            )
            asteroid.physicsBody?.velocity = randomVelocity
        }
        
        // Rotazione casuale (asteroidi blu ruotano il doppio più velocemente)
        let baseRotationSpeed = CGFloat.random(in: -0.3...0.3)
        let rotationMultiplier: CGFloat = {
            switch asteroidType {
            case .fast: return 2.0  // Blu ruotano il doppio
            default: return 1.0
            }
        }()
        asteroid.physicsBody?.angularVelocity = baseRotationSpeed * rotationMultiplier
        
        worldLayer.addChild(asteroid)
        asteroids.append(asteroid)
        
        debugLog("☄️ \(asteroidType) asteroid spawned at: \(asteroid.position)")
    }
    
    // Mantieni la funzione originale per retrocompatibilità
    private func spawnAsteroid(size asteroidSize: AsteroidSize, at position: CGPoint?) {
        // Delega alla nuova funzione con tipo normal
        spawnAsteroid(type: .normal(asteroidSize), at: position)
    }
    
    // Versione legacy (non più usata direttamente)
    private func spawnAsteroid_legacy(size asteroidSize: AsteroidSize, at position: CGPoint?) {
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
            // Posizione casuale ai bordi del campo di gioco esteso (3x)
            let playFieldWidth = self.size.width * playFieldMultiplier
            let playFieldHeight = self.size.height * playFieldMultiplier
            let minX = self.size.width / 2 - playFieldWidth / 2
            let maxX = self.size.width / 2 + playFieldWidth / 2
            let minY = self.size.height / 2 - playFieldHeight / 2
            let maxY = self.size.height / 2 + playFieldHeight / 2
            let margin: CGFloat = 50
            
            let edge = Int.random(in: 0...3)
            switch edge {
            case 0: // Top
                asteroid.position = CGPoint(x: CGFloat.random(in: minX...maxX), y: maxY + margin)
            case 1: // Right
                asteroid.position = CGPoint(x: maxX + margin, y: CGFloat.random(in: minY...maxY))
            case 2: // Bottom
                asteroid.position = CGPoint(x: CGFloat.random(in: minX...maxX), y: minY - margin)
            default: // Left
                asteroid.position = CGPoint(x: minX - margin, y: CGFloat.random(in: minY...maxY))
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
        
        debugLog("☄️ Asteroid (\(asteroidSize)) spawned at: \(asteroid.position)")
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
    
    private func createIrregularPlanetPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        // Più lati per una forma più circolare ma comunque irregolare
        let sides = 24  // Più lati = più circolare
        let angleStep = (2 * .pi) / CGFloat(sides)
        
        for i in 0..<sides {
            let angle = angleStep * CGFloat(i)
            // Variazione molto ridotta per mantenere forma quasi circolare
            let variation = CGFloat.random(in: 0.92...1.08)
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
        let playFieldWidth = size.width * playFieldMultiplier
        let playFieldHeight = size.height * playFieldMultiplier
        let minX = size.width / 2 - playFieldWidth / 2
        let maxX = size.width / 2 + playFieldWidth / 2
        let minY = size.height / 2 - playFieldHeight / 2
        let maxY = size.height / 2 + playFieldHeight / 2
        let margin: CGFloat = 50
        
        for asteroid in asteroids {
            // Wrap orizzontale
            if asteroid.position.x < minX - margin {
                asteroid.position.x = maxX + margin
            } else if asteroid.position.x > maxX + margin {
                asteroid.position.x = minX - margin
            }
            
            // Wrap verticale
            if asteroid.position.y < minY - margin {
                asteroid.position.y = maxY + margin
            } else if asteroid.position.y > maxY + margin {
                asteroid.position.y = minY - margin
            }
        }
        
        // Wrap anche per i power-up
        worldLayer.enumerateChildNodes(withName: "powerup_*") { node, _ in
            // Wrap orizzontale
            if node.position.x < minX - margin {
                node.position.x = maxX + margin
            } else if node.position.x > maxX + margin {
                node.position.x = minX - margin
            }
            
            // Wrap verticale
            if node.position.y < minY - margin {
                node.position.y = maxY + margin
            } else if node.position.y > maxY + margin {
                node.position.y = minY - margin
            }
        }
    }
    
    private func cleanupAsteroids() {
        asteroids.removeAll { $0.parent == nil }
    }
    
    // MARK: - Camera Zoom System
    private func updateParallaxBackground() {
        // Muove le stelle in base al movimento della camera (effetto parallasse inverso)
        guard let cameraPos = camera?.position else { return }
        
        // Calcola offset dal centro dello schermo
        let centerX = size.width / 2
        let centerY = size.height / 2
        let offsetX = cameraPos.x - centerX
        let offsetY = cameraPos.y - centerY
        
        // Layer 1: Stelle più lontane - movimento molto lento (10% della camera)
        starsLayer1.position = CGPoint(
            x: centerX - offsetX * 0.1,
            y: centerY - offsetY * 0.1
        )
        
        // Layer 2: Stelle medie - movimento medio (20% della camera)
        starsLayer2.position = CGPoint(
            x: centerX - offsetX * 0.2,
            y: centerY - offsetY * 0.2
        )
        
        // Layer 3: Stelle più vicine - movimento veloce (35% della camera)
        starsLayer3.position = CGPoint(
            x: centerX - offsetX * 0.35,
            y: centerY - offsetY * 0.35
        )
    }
    
    private func updateCameraZoom() {
        // Calcola distanze assolute dal pianeta
        let dx = abs(player.position.x - planet.position.x)
        let dy = abs(player.position.y - planet.position.y)
        
        // Soglie fisse basate sulle dimensioni dello schermo
        // Primo zoom quando il player raggiunge circa 40% della larghezza/altezza schermo
        let limitMediumH: CGFloat = size.width * 0.35
        let limitMediumV: CGFloat = size.height * 0.30
        
        // Secondo zoom quando raggiunge circa 70% della larghezza/altezza schermo
        let limitFarH: CGFloat = size.width * 0.60
        let limitFarV: CGFloat = size.height * 0.50
        
        // Determina il livello di zoom necessario per orizzontale
        let needsZoomH: Int
        if dx < limitMediumH {
            needsZoomH = 0  // Vicino - no zoom
        } else if dx < limitFarH {
            needsZoomH = 1  // Medio - primo zoom
        } else {
            needsZoomH = 2  // Lontano - zoom massimo
        }
        
        // Determina il livello di zoom necessario per verticale
        let needsZoomV: Int
        if dy < limitMediumV {
            needsZoomV = 0  // Vicino - no zoom
        } else if dy < limitFarV {
            needsZoomV = 1  // Medio - primo zoom
        } else {
            needsZoomV = 2  // Lontano - zoom massimo
        }
        
        // Usa il livello di zoom maggiore tra H e V
        let maxZoomNeeded = max(needsZoomH, needsZoomV)
        
        // Determina il target zoom
        let targetZoom: CGFloat
        switch maxZoomNeeded {
        case 0:
            targetZoom = zoomLevelClose
        case 1:
            targetZoom = zoomLevelMedium
        default:
            targetZoom = zoomLevelFar
        }
        
        // Interpolazione fluida verso il target zoom
        let zoomSpeed: CGFloat = 0.12  // Ridotto per transizioni più morbide
        currentZoomLevel = currentZoomLevel + (targetZoom - currentZoomLevel) * zoomSpeed
        
        // Applica lo zoom alla camera solo se cambia significativamente
        // Questo riduce il flickering dovuto a piccole oscillazioni
        if abs(currentZoomLevel - gameCamera.xScale) > 0.01 {
            gameCamera.setScale(currentZoomLevel)
        }
        
        // Debug (opzionale)
        // debugLog("dx: \(Int(dx))/\(Int(limitFarH)) dy: \(Int(dy))/\(Int(limitFarV)) | ZoomH: \(needsZoomH) ZoomV: \(needsZoomV) | Target: \(String(format: "%.2f", targetZoom)) Current: \(String(format: "%.2f", currentZoomLevel))")
    }
    
    // MARK: - Collision Handling
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let currentTime = lastUpdateTime  // Usa il currentTime da update loop
        
        // Player + Atmosphere
        if collision == (PhysicsCategory.player | PhysicsCategory.atmosphere) {
            // Cooldown per evitare collisioni multiple consecutive
            guard currentTime - lastCollisionTime > collisionCooldown else { return }
            lastCollisionTime = currentTime
            
            handleAtmosphereBounce(contact: contact, isPlayer: true)
            // RIMOSSA ricarica quando il player colpisce l'atmosfera con lo scudo
            flashAtmosphere()
            flashPlayerShield()
            
            // Bonus per rimbalzo
            score += 5
            scoreLabel.text = "\(score)"
            
            debugLog("🌀 Player hit atmosphere - bounce (no recharge) + 5 points")
        }
        
        // Projectile + Atmosphere
        else if collision == (PhysicsCategory.projectile | PhysicsCategory.atmosphere) {
            handleAtmosphereBounce(contact: contact, isPlayer: false)
            rechargeAtmosphere(amount: 1.05)  // Ridotto del 30% da 1.5 a 1.05
            flashAtmosphere()
            
            // Rimuovi il proiettile
            if contact.bodyA.categoryBitMask == PhysicsCategory.projectile {
                contact.bodyA.node?.removeFromParent()
            } else {
                contact.bodyB.node?.removeFromParent()
            }
            debugLog("💥 Projectile hit atmosphere - bounce + recharge")
        }
        
        // Asteroid + Atmosphere
        else if collision == (PhysicsCategory.asteroid | PhysicsCategory.atmosphere) {
            handleAsteroidAtmosphereBounce(contact: contact)
            
            // Calcola danno basato sul tipo di asteroide
            let asteroidBody = contact.bodyA.categoryBitMask == PhysicsCategory.asteroid ? contact.bodyA : contact.bodyB
            var damageAmount: CGFloat = 2.66  // Danno base aumentato del 33% (era 2.0)
            
            if let asteroidNode = asteroidBody.node as? SKShapeNode,
               let asteroidType = asteroidNode.userData?["type"] as? AsteroidType {
                damageAmount *= asteroidType.atmosphereDamageMultiplier
            }
            
            damageAtmosphere(amount: damageAmount)
            flashAtmosphere()
            
            // Effetto particellare al punto di contatto con colore random
            createCollisionParticles(at: contact.contactPoint, color: randomExplosionColor())
            
            debugLog("☄️ Asteroid hit atmosphere - bounce + \(damageAmount) damage")
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
                    debugLog("💔 Planet damaged! Health: \(planetHealth)/\(maxPlanetHealth)")
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
                        debugLog("💥 Small asteroid destroyed by planet impact")
                    } else {
                        // Large e medium si frammentano
                        fragmentAsteroid(asteroid)
                        debugLog("💥 Asteroid fragmented by planet impact")
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
                
                // Effetto particellare con colore random
                createCollisionParticles(at: contact.contactPoint, color: randomExplosionColor())
                
                debugLog("💥 Player hit asteroid - bounce + damage")
            }
        }

        // Player + Power-up
        else if collision == (PhysicsCategory.player | PhysicsCategory.powerup) {
            // Identifica il power-up
            let powerupBody = contact.bodyA.categoryBitMask == PhysicsCategory.powerup ? contact.bodyA : contact.bodyB
            if let powerupNode = powerupBody.node {
                // Determina il tipo dalla name (powerup_V, powerup_B, powerup_A)
                if let name = powerupNode.name, name.contains("powerup_") {
                    let parts = name.split(separator: "_")
                    if parts.count > 1 {
                        let type = String(parts[1])
                        
                        // Animazione di pickup: fade out + scale up (NON esplosione)
                        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
                        let scaleUp = SKAction.scale(to: 2.0, duration: 0.3)
                        let group = SKAction.group([fadeOut, scaleUp])
                        let remove = SKAction.removeFromParent()
                        powerupNode.run(SKAction.sequence([group, remove]))
                        
                        // Attiva effetto power-up
                        activatePowerup(type: type, currentTime: currentTime)
                        
                        debugLog("✨ Power-up \(type) collected")
                    }
                } else {
                    powerupNode.removeFromParent()
                }
            }
        }
        
        // Power-up + Atmosphere (rimbalzo senza danni)
        else if collision == (PhysicsCategory.powerup | PhysicsCategory.atmosphere) {
            let powerupBody = contact.bodyA.categoryBitMask == PhysicsCategory.powerup ? contact.bodyA : contact.bodyB
            if let powerupNode = powerupBody.node {
                // Flash leggero dell'atmosfera
                let originalAlpha = atmosphere.strokeColor.withAlphaComponent(0.6)
                atmosphere.strokeColor = .cyan
                let wait = SKAction.wait(forDuration: 0.05)
                let restore = SKAction.run { [weak self] in
                    self?.atmosphere.strokeColor = originalAlpha
                }
                atmosphere.run(SKAction.sequence([wait, restore]))
            }
        }
        
        // Power-up + Planet (rimbalzo senza danni)
        else if collision == (PhysicsCategory.powerup | PhysicsCategory.planet) {
            // Rimbalzo forte per i power-up
            let powerup = contact.bodyA.categoryBitMask == PhysicsCategory.powerup ? contact.bodyA.node : contact.bodyB.node
            if let powerupNode = powerup, let powerupBody = powerupNode.physicsBody {
                let dx = powerupNode.position.x - planet.position.x
                let dy = powerupNode.position.y - planet.position.y
                let distance = sqrt(dx * dx + dy * dy)
                
                guard distance > 0 else { return }
                
                let normalX = dx / distance
                let normalY = dy / distance
                
                let velocity = powerupBody.velocity
                let dotProduct = velocity.dx * normalX + velocity.dy * normalY
                
                guard dotProduct < 0 else { return }
                
                let reflectedVelocityX = velocity.dx - 2 * dotProduct * normalX
                let reflectedVelocityY = velocity.dy - 2 * dotProduct * normalY
                
                let bounceFactor: CGFloat = 5.0  // Rimbalzo molto forte per i power-up
                powerupBody.velocity = CGVector(
                    dx: reflectedVelocityX * bounceFactor,
                    dy: reflectedVelocityY * bounceFactor
                )
            }
            debugLog("✨ Power-up bounced off planet")
        }
        
        // Power-up + Asteroid (rimbalzo senza danni)
        else if collision == (PhysicsCategory.powerup | PhysicsCategory.asteroid) {
            // Solo rimbalzo fisico, nessun danno
            debugLog("✨ Power-up bounced off asteroid")
        }
        
        // Projectile + Asteroid
        else if collision == (PhysicsCategory.projectile | PhysicsCategory.asteroid) {
            // Identifica proiettile e asteroide
            let projectile = contact.bodyA.categoryBitMask == PhysicsCategory.projectile ? contact.bodyA.node : contact.bodyB.node
            let asteroid = contact.bodyA.categoryBitMask == PhysicsCategory.asteroid ? contact.bodyA.node as? SKShapeNode : contact.bodyB.node as? SKShapeNode
            
            // Leggi il damage multiplier dal proiettile
            let damageMultiplier = (projectile?.userData?["damageMultiplier"] as? CGFloat) ?? 1.0
            
            // Rimuovi il proiettile
            projectile?.removeFromParent()
            
            // Frammenta l'asteroide con il damage multiplier
            if let asteroid = asteroid {
                // Effetto particellare con colore random
                createExplosionParticles(at: asteroid.position, color: randomExplosionColor())
                fragmentAsteroid(asteroid, damageMultiplier: damageMultiplier)
            }
            
            debugLog("💥 Projectile destroyed asteroid (damage: \(damageMultiplier)x)")
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
        
        // Boost extra per frammenti piccoli (più attratti dalla gravità)
        var bounceFactor: CGFloat = 4.62
        if let sizeData = asteroid.userData?["size"] as? AsteroidSize {
            if sizeData == .small {
                bounceFactor = 6.5  // Frammenti piccoli: boost extra del 40%
            } else if sizeData == .medium {
                bounceFactor = 5.5  // Frammenti medi: boost intermedio
            }
        }
        
        asteroidBody.velocity = CGVector(
            dx: reflectedVelocityX * bounceFactor,
            dy: reflectedVelocityY * bounceFactor
        )
        
        // Sposta l'asteroide FUORI dal pianeta per evitare collisioni multiple
        let pushDistance: CGFloat = 15
        asteroid.position.x += normalX * pushDistance
        asteroid.position.y += normalY * pushDistance
        
        // Effetto particellare al punto di contatto con colore random
        createCollisionParticles(at: contact.contactPoint, color: randomExplosionColor())
        
        debugLog("💥 Asteroid bounced off planet")
    }
    
    private func flashAsteroid(_ asteroid: SKShapeNode) {
        // Effetto flash rosso sull'asteroide
        let originalColor = asteroid.fillColor
        asteroid.fillColor = .red
        
        let wait = SKAction.wait(forDuration: 0.1)
        let restore = SKAction.run { [weak asteroid] in
            asteroid?.fillColor = originalColor
        }
        asteroid.run(SKAction.sequence([wait, restore]))
    }
    
    private func fragmentAsteroid(_ asteroid: SKShapeNode, damageMultiplier: CGFloat = 1.0) {
        guard let sizeString = asteroid.name?.split(separator: "_").last,
              let sizeRaw = Int(String(sizeString)),
              let size = AsteroidSize(rawValue: sizeRaw) else { return }
        
        // Controlla se l'asteroide ha vita (armored)
        if let health = asteroid.userData?["health"] as? Int, health > 1 {
            // Riduci la vita invece di distruggere
            let newHealth = health - 1
            asteroid.userData?["health"] = newHealth
            
            // Flash per indicare il colpo
            let originalColor = asteroid.strokeColor
            asteroid.strokeColor = .yellow
            let wait = SKAction.wait(forDuration: 0.1)
            let restore = SKAction.run { [weak asteroid] in
                asteroid?.strokeColor = originalColor
            }
            asteroid.run(SKAction.sequence([wait, restore]))
            
            // Effetto particellare ridotto
            createCollisionParticles(at: asteroid.position, color: .yellow)
            
            debugLog("💪 Armored asteroid hit! Health: \(newHealth)")
            return  // Non frammentare ancora
        }
        
        // Aggiungi punti in base alla dimensione (moltiplicati per danno)
        let basePoints: Int
        switch size {
        case .large: basePoints = 20
        case .medium: basePoints = 15
        case .small: basePoints = 10
        }
        let points = Int(CGFloat(basePoints) * damageMultiplier)
        score += points
        scoreLabel.text = "\(score)"
        
        let position = asteroid.position
        let velocity = asteroid.physicsBody?.velocity ?? .zero
        
        // Recupera il tipo per l'esplosione
        let asteroidType = asteroid.userData?["type"] as? AsteroidType
        
        // Effetto particellare per la frammentazione con colore basato sul tipo
        let explosionColor: UIColor
        if let type = asteroidType {
            explosionColor = type.color
        } else {
            explosionColor = randomExplosionColor()
        }
        createExplosionParticles(at: position, color: explosionColor)
        
        // Rimuovi l'asteroide originale
        asteroid.removeFromParent()
        asteroids.removeAll { $0 == asteroid }
        
        // Possibilità di rilascio power-up
        spawnPowerUp(at: position)
        
        // Con BigAmmo (4x damage), gli asteroidi si frammentano più violentemente
        // Large -> salta direttamente a Small se damage >= 4x
        let shouldSkipMedium = (size == .large && damageMultiplier >= 4.0)
        
        // Crea frammenti se non è small
        if size != .small {
            let nextSize: AsteroidSize
            if shouldSkipMedium {
                nextSize = .small  // Salta direttamente a small
            } else {
                nextSize = size == .large ? .medium : .small
            }
            
            // Determina il tipo dei frammenti (eredita da parent se heavy/armored/fast)
            let fragmentType: AsteroidType
            if let parentType = asteroidType {
                switch parentType {
                case .heavy:
                    fragmentType = .heavy(nextSize)  // I frammenti heavy rimangono heavy
                case .armored:
                    fragmentType = .armored(nextSize)  // I frammenti armored rimangono armored
                case .fast:
                    fragmentType = .fast(nextSize)  // I frammenti fast rimangono fast
                default:
                    fragmentType = .normal(nextSize)  // Gli altri diventano normali
                }
            } else {
                fragmentType = .normal(nextSize)
            }
            
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
                
                // Spawna il frammento con il tipo ereditato
                spawnAsteroid(type: fragmentType, at: fragmentPosition)
                
                // Applica velocità ereditata + esplosione (più forte con BigAmmo)
                if let fragment = asteroids.last {
                    let explosionForce: CGFloat = 60 * damageMultiplier  // Più forte con BigAmmo
                    fragment.physicsBody?.velocity = CGVector(
                        dx: velocity.dx * 0.7 + cos(angle) * explosionForce,  // Eredita 70% velocità
                        dy: velocity.dy * 0.7 + sin(angle) * explosionForce
                    )
                }
            }
            
            debugLog("💥 Asteroid fragmented into \(fragmentCount) x \(fragmentType) (damage: \(damageMultiplier)x)")
        } else {
            debugLog("💥 Small asteroid destroyed (damage: \(damageMultiplier)x)")
        }
    }
    
    private func damageAsteroid(_ asteroid: SKShapeNode) {
        guard let sizeString = asteroid.name?.split(separator: "_").last,
              let sizeRaw = Int(String(sizeString)),
              let size = AsteroidSize(rawValue: sizeRaw) else { return }
        
        // Recupera il tipo dell'asteroide
        let asteroidType = asteroid.userData?["type"] as? AsteroidType
        
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
            let explosionColor = asteroidType?.color ?? randomExplosionColor()
            createExplosionParticles(at: position, color: explosionColor)
            asteroid.removeFromParent()
            asteroids.removeAll { $0 == asteroid }
            // Possibilità di rilascio power-up
            spawnPowerUp(at: position)
            debugLog("💥 Small asteroid destroyed by player")
        } else {
            // Large e medium si frammentano (ma con meno energia)
            let position = asteroid.position
            let velocity = asteroid.physicsBody?.velocity ?? .zero
            
            // Effetto particellare per il danneggiamento con colore basato sul tipo
            let particleColor = asteroidType?.color ?? randomExplosionColor()
            createCollisionParticles(at: position, color: particleColor)
            
            asteroid.removeFromParent()
            asteroids.removeAll { $0 == asteroid }
            
            let nextSize: AsteroidSize = size == .large ? .medium : .small
            
            // Determina il tipo dei frammenti (eredita da parent)
            let fragmentType: AsteroidType
            if let parentType = asteroidType {
                switch parentType {
                case .heavy:
                    fragmentType = .heavy(nextSize)  // Heavy rimane heavy
                case .armored:
                    fragmentType = .armored(nextSize)  // Armored rimane armored
                case .fast:
                    fragmentType = .fast(nextSize)  // Fast rimane fast
                default:
                    fragmentType = .normal(nextSize)
                }
            } else {
                fragmentType = .normal(nextSize)
            }
            
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
                
                // Spawna con il tipo ereditato
                spawnAsteroid(type: fragmentType, at: fragmentPosition)
                
                // Velocità più bassa rispetto all'esplosione del proiettile
                if let fragment = asteroids.last {
                    let pushForce: CGFloat = 40  // Molto più basso di 60 (proiettile)
                    fragment.physicsBody?.velocity = CGVector(
                        dx: velocity.dx * 0.5 + cos(angle) * pushForce,
                        dy: velocity.dy * 0.5 + sin(angle) * pushForce
                    )
                }
            }
            
            debugLog("💥 Asteroid damaged by player - fragmented into \(fragmentCount) x \(fragmentType)")
        }
    }
    
    private func rechargeAtmosphere(amount: CGFloat) {
        // Non ricaricare se l'atmosfera è al minimo (raggio = raggio pianeta)
        if atmosphereRadius <= planetRadius {
            debugLog("🚫 Atmosphere at critical level - cannot recharge!")
            return
        }
        
        // Aumenta il raggio dell'atmosfera (max 80)
        atmosphereRadius = min(atmosphereRadius + amount, maxAtmosphereRadius)
        
        updateAtmosphereVisuals()
        debugLog("🔋 Atmosphere recharged: \(atmosphereRadius)")
    }
    
    private func damageAtmosphere(amount: CGFloat) {
        // Riduci il raggio dell'atmosfera (min = raggio pianeta)
        atmosphereRadius = max(atmosphereRadius - amount, planetRadius)
        
        // Se raggiunge il raggio del pianeta, nascondi l'atmosfera
        if atmosphereRadius <= planetRadius {
            atmosphere.alpha = 0  // Invisibile
            debugLog("💀 Atmosphere DESTROYED - planet vulnerable!")
        }
        
        updateAtmosphereVisuals()
        debugLog("⚠️ Atmosphere damaged: \(atmosphereRadius)")
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
        
        debugLog("⚡ Player-Asteroid bounce: restitution=\(restitution), impulse=\(j)")
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
        
        debugLog("✨ Collision particles created at \(position)")
        
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
        emitter.particleColorBlendFactor = 1.0  // Forza il colore al 100%
        emitter.particleBlendMode = .add
        emitter.zPosition = 100
        
        worldLayer.addChild(emitter)
        
        debugLog("💥 Explosion particles created at \(position)")
        
        // Rimuovi dopo il completamento
        let waitAction = SKAction.wait(forDuration: 1.0)
        let removeAction = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([waitAction, removeAction]))
    }
    
    private func createPlanetExplosion(at position: CGPoint) {
        // Crea 3 esplosioni successive per effetto più drammatico
        for i in 0..<3 {
            let delay = Double(i) * 0.35  // Esplosioni ogni 0.35 secondi
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                let emitter = SKEmitterNode()
                emitter.position = position
                
                // Esplosione massiva del pianeta
                emitter.particleTexture = self.particleTexture
                emitter.particleBirthRate = 1500       // Ancora più particelle
                emitter.numParticlesToEmit = 200       // Più particelle per esplosione
                emitter.particleLifetime = 1.2         // Durata 1 secondo
                emitter.emissionAngle = 0
                emitter.emissionAngleRange = CGFloat.pi * 2
                emitter.particleSpeed = 700            // Velocità maggiore
                emitter.particleSpeedRange = 400
                emitter.particleScale = 1.5            // Particelle più grandi
                emitter.particleScaleRange = 0.8
                emitter.particleScaleSpeed = -1.2      // Dissolvenza veloce
                emitter.particleAlpha = 1.0
                emitter.particleAlphaSpeed = -0.8
                
                // Varia colore per le 3 esplosioni
                switch i {
                case 0: emitter.particleColor = .red
                case 1: emitter.particleColor = .orange
                case 2: emitter.particleColor = .yellow
                default: emitter.particleColor = .red
                }
                
                emitter.particleColorBlendFactor = 1.0
                emitter.particleBlendMode = .add
                emitter.zPosition = 100
                
                self.worldLayer.addChild(emitter)
                
                // Rimuovi dopo il completamento
                let waitAction = SKAction.wait(forDuration: 1.5)
                let removeAction = SKAction.removeFromParent()
                emitter.run(SKAction.sequence([waitAction, removeAction]))
            }
        }
        
        debugLog("💥💥💥 MASSIVE PLANET EXPLOSION at \(position)")
    }
    
    private func playExplosionSound() {
        if let url = Bundle.main.url(forResource: "esplosione1", withExtension: "m4a") {
            do {
                let explosionPlayer = try AVAudioPlayer(contentsOf: url)
                explosionPlayer.volume = 1.0         // Volume massimo
                explosionPlayer.enableRate = true
                explosionPlayer.rate = 0.75          // Rallentato del 25% (più drammatico)
                explosionPlayer.play()
                print("🔊 Playing MASSIVE explosion sound (slowed)")
            } catch {
                print("❌ Error playing explosion sound: \(error)")
            }
        } else {
            print("❌ Explosion sound not found")
        }
    }

    // MARK: - Power-ups
    private func spawnPowerUp(at position: CGPoint) {
        // Probabilità di spawn: 25%
        let roll = Int.random(in: 0..<100)
        guard roll < 25 else { return }

        // Scegli tipo: V (rosso), B (verde), A (blu)
        let types: [(String, UIColor)] = [("V", .red), ("B", UIColor.green), ("A", UIColor.cyan)]
        let choice = types.randomElement()!

        let radius: CGFloat = 14
        let powerup = SKShapeNode(circleOfRadius: radius)
        powerup.fillColor = choice.1
        powerup.strokeColor = .white
        powerup.lineWidth = 2
        powerup.position = position
        powerup.zPosition = 50
        powerup.name = "powerup_\(choice.0)"

        // Lettera al centro
        let letter = SKLabelNode(fontNamed: "AvenirNext-Bold")
        letter.text = choice.0
        letter.fontSize = 18
        letter.verticalAlignmentMode = .center
        letter.horizontalAlignmentMode = .center
        letter.fontColor = .white
        powerup.addChild(letter)

        // Physics body DINAMICO per gravità (come asteroide)
        powerup.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        powerup.physicsBody?.isDynamic = true
        powerup.physicsBody?.mass = 0.3
        powerup.physicsBody?.linearDamping = 0
        powerup.physicsBody?.angularDamping = 1.0  // Impedisce rotazione
        powerup.physicsBody?.allowsRotation = false  // Nessuna rotazione
        powerup.physicsBody?.restitution = 0.8 // Rimbalzo elastico
        powerup.physicsBody?.categoryBitMask = PhysicsCategory.powerup
        powerup.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.atmosphere | PhysicsCategory.planet | PhysicsCategory.asteroid
        powerup.physicsBody?.collisionBitMask = PhysicsCategory.planet | PhysicsCategory.atmosphere | PhysicsCategory.asteroid // Rimbalza fisicamente

        // Velocità iniziale casuale (come frammento di asteroide)
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let speed: CGFloat = CGFloat.random(in: 40...80)
        powerup.physicsBody?.velocity = CGVector(
            dx: cos(angle) * speed,
            dy: sin(angle) * speed
        )

        worldLayer.addChild(powerup)
        
        // Animazione pulsazione per renderlo visibile
        let pulseUp = SKAction.scale(to: 1.15, duration: 0.6)
        let pulseDown = SKAction.scale(to: 1.0, duration: 0.6)
        let pulse = SKAction.sequence([pulseUp, pulseDown])
        powerup.run(SKAction.repeatForever(pulse))
        
        // Decadimento dopo 15 secondi: fade out progressivo e poi rimozione
        let waitBeforeFade = SKAction.wait(forDuration: 10.0)  // Visibile per 10s
        let fadeOut = SKAction.fadeOut(withDuration: 5.0)      // Diventa trasparente in 5s
        let remove = SKAction.removeFromParent()
        let decaySequence = SKAction.sequence([waitBeforeFade, fadeOut, remove])
        powerup.run(decaySequence, withKey: "powerupDecay")
    }

    private func activatePowerup(type: String, currentTime: TimeInterval) {
        // Se c'è già un power-up attivo (V o B), disattiva il precedente e attiva il nuovo
        // A (Atmosphere) può essere raccolto anche con altri power-up attivi
        if type != "A" && (vulcanActive || bigAmmoActive) {
            debugLog("⚠️ Replacing active power-up with \(type)")
            // Disattiva il power-up precedente (ma mantieni activePowerupEndTime per resettarlo)
            deactivatePowerups()
        }
        
        // Attiva l'effetto e imposta timer a 10s
        activePowerupEndTime = currentTime + 10.0
        
        if type == "V" {
            vulcanActive = true
            // Velocità di fuoco ancora più alta: 5x invece di 3x
            currentFireRate = baseFireRate / 5.0
            powerupLabel.fontColor = .orange
            powerupLabel.text = "Vulcan 10.00s"
        } else if type == "B" {
            bigAmmoActive = true
            // Rendi i colpi 4x più spessi e 2x più lunghi
            projectileWidthMultiplier = 4.0
            projectileHeightMultiplier = 2.0
            // Danno 4x più forte
            projectileDamageMultiplier = 4.0
            powerupLabel.fontColor = UIColor.green
            powerupLabel.text = "BigAmmo 10.00s"
        } else if type == "A" {
            atmosphereActive = true
            // Ripristina metà dell'atmosfera (o riattivala se esaurita)
            let halfAtmosphere = (minAtmosphereRadius + maxAtmosphereRadius) / 2.0
            atmosphereRadius = max(atmosphereRadius, halfAtmosphere)
            
            // Se era esaurita (al minimo = raggio pianeta), la riattiva
            if atmosphereRadius <= planetRadius {
                atmosphereRadius = halfAtmosphere
            }
            
            // Rendi l'atmosfera visibile e aggiorna
            atmosphere.alpha = 1.0
            updateAtmosphereVisuals()
            
            powerupLabel.fontColor = UIColor.cyan
            powerupLabel.text = "Atmosphere"  // NO timer nel testo
            debugLog("🌀 Atmosphere restored to \(atmosphereRadius)")
        }
    }

    private func deactivatePowerups() {
        // Resetta gli stati
        vulcanActive = false
        bigAmmoActive = false
        atmosphereActive = false
        projectileWidthMultiplier = 1.0
        projectileHeightMultiplier = 1.0
        projectileDamageMultiplier = 1.0
        currentFireRate = baseFireRate
        activePowerupEndTime = 0
        powerupLabel.text = ""
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
        
        // Crea overlay scuro (coordinate relative alla camera)
        let overlay = SKNode()
        overlay.name = "pauseOverlay"
        overlay.zPosition = 2000
        
        // Background semi-trasparente
        let background = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.7), size: size)
        background.position = CGPoint.zero  // Centro della camera
        overlay.addChild(background)
        
        // Titolo PAUSED
        let fontName = "AvenirNext-Bold"
        let titleLabel = SKLabelNode(fontNamed: fontName)
        titleLabel.text = "PAUSED"
        titleLabel.fontSize = 64
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 100)  // Relativo al centro
        overlay.addChild(titleLabel)
        
        // Pulsante RESUME
        let resumeButton = SKShapeNode(rectOf: CGSize(width: 250, height: 70), cornerRadius: 10)
        resumeButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        resumeButton.strokeColor = .white
        resumeButton.lineWidth = 3
        resumeButton.position = CGPoint(x: 0, y: 0)  // Relativo al centro
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
        quitButton.position = CGPoint(x: 0, y: -100)  // Relativo al centro
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
        
        debugLog("⏸️ Game paused")
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
        
        debugLog("▶️ Game resumed")
    }
    
    private func quitToMenu() {
        // Transizione al menu principale
        let transition = SKTransition.fade(withDuration: 0.5)
        let menuScene = MainMenuScene(size: size)
        menuScene.scaleMode = scaleMode
        view?.presentScene(menuScene, transition: transition)
        
        debugLog("🏠 Returning to main menu")
    }
    
    private func retryGame() {
        // Riavvia il gioco
        let newGame = GameScene(size: size)
        newGame.scaleMode = scaleMode
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(newGame, transition: transition)
        
        debugLog("🔄 Restarting game")
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
        
        // Ferma la musica con fade out
        fadeOutAndStop()
        
        // Esplosione finale del pianeta (3x più grande)
        createPlanetExplosion(at: planet.position)
        planet.alpha = 0
        
        // Suono esplosione
        playExplosionSound()
        
        // Controlla se il punteggio è top-10
        checkIfTopTen()
    }
    
    private func checkIfTopTen() {
        guard let url = URL(string: "https://formazioneweb.org/orbitica/score.php?action=list") else {
            showGameOverScreen(isTopTen: false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.debugLog("❌ Error checking top-10: \(error.localizedDescription)")
                    self.showGameOverScreen(isTopTen: false)
                    return
                }
                
                guard let data = data else {
                    self.showGameOverScreen(isTopTen: false)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let scoresArray = json["scores"] as? [[String: Any]] {
                        
                        // Controlla se il punteggio qualifica per top-10
                        let isTopTen: Bool
                        if scoresArray.count < 10 {
                            // Meno di 10 score salvati = automaticamente top-10
                            isTopTen = true
                        } else if let lowestScore = scoresArray.last?["score"] as? Int {
                            // Confronta con il 10° posto
                            isTopTen = self.score > lowestScore
                        } else {
                            isTopTen = false
                        }
                        
                        if isTopTen {
                            self.showInitialEntryScene()
                        } else {
                            self.showGameOverScreen(isTopTen: false)
                        }
                    } else {
                        self.showGameOverScreen(isTopTen: false)
                    }
                } catch {
                    self.debugLog("❌ Parse error: \(error.localizedDescription)")
                    self.showGameOverScreen(isTopTen: false)
                }
            }
        }
        
        task.resume()
    }
    
    private func showInitialEntryScene() {
        // Vai alla schermata inserimento iniziali
        let transition = SKTransition.fade(withDuration: 0.5)
        let initialEntryScene = InitialEntryScene(size: size, score: score, wave: currentWave)
        initialEntryScene.scaleMode = scaleMode
        view?.presentScene(initialEntryScene, transition: transition)
    }
    
    private func showGameOverScreen(isTopTen: Bool) {
        // Overlay scuro (coordinate relative alla camera)
        let overlay = SKNode()
        overlay.name = "gameOverOverlay"
        overlay.zPosition = 3000
        
        let background = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.8), size: size)
        background.position = CGPoint.zero  // Centro della camera
        overlay.addChild(background)
        
        // Testo GAME OVER
        let fontName = "AvenirNext-Bold"
        let gameOverLabel = SKLabelNode(fontNamed: fontName)
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 72
        gameOverLabel.fontColor = .red
        gameOverLabel.horizontalAlignmentMode = .center
        gameOverLabel.position = CGPoint(x: 0, y: 50)  // Relativo al centro
        overlay.addChild(gameOverLabel)
        
        // Score finale
        let finalScoreLabel = SKLabelNode(fontNamed: fontName)
        finalScoreLabel.text = "FINAL SCORE: \(score)"
        finalScoreLabel.fontSize = 32
        finalScoreLabel.fontColor = .white
        finalScoreLabel.horizontalAlignmentMode = .center
        finalScoreLabel.position = CGPoint(x: 0, y: -30)  // Relativo al centro
        overlay.addChild(finalScoreLabel)
        
        // Wave raggiunta
        let waveLabel = SKLabelNode(fontNamed: fontName)
        waveLabel.text = "WAVE \(currentWave)"
        waveLabel.fontSize = 24
        waveLabel.fontColor = UIColor.white.withAlphaComponent(0.7)
        waveLabel.horizontalAlignmentMode = .center
        waveLabel.position = CGPoint(x: 0, y: -70)  // Relativo al centro
        overlay.addChild(waveLabel)
        
        // Pulsante SAVE SCORE (giallo, in alto)
        let saveScoreButton = SKShapeNode(rectOf: CGSize(width: 250, height: 60), cornerRadius: 10)
        saveScoreButton.fillColor = UIColor.yellow.withAlphaComponent(0.2)
        saveScoreButton.strokeColor = .yellow
        saveScoreButton.lineWidth = 3
        saveScoreButton.position = CGPoint(x: 0, y: -130)  // Relativo al centro
        saveScoreButton.name = "saveScoreButton"
        
        let saveScoreLabel = SKLabelNode(fontNamed: fontName)
        saveScoreLabel.text = "SAVE SCORE"
        saveScoreLabel.fontSize = 24
        saveScoreLabel.fontColor = .yellow
        saveScoreLabel.verticalAlignmentMode = .center
        saveScoreButton.addChild(saveScoreLabel)
        overlay.addChild(saveScoreButton)
        
        // Pulsante RETRY
        let retryButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        retryButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        retryButton.strokeColor = .white
        retryButton.lineWidth = 3
        retryButton.position = CGPoint(x: -110, y: -210)  // Relativo al centro
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
        menuButton.position = CGPoint(x: 110, y: -210)  // Relativo al centro
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
        
        debugLog("💀 GAME OVER - Final Score: \(score), Wave: \(currentWave)")
    }
    
    // MARK: - Audio System
    
    /// Carica e avvia la riproduzione di un file audio con crossfade dal brano precedente
    /// - Parameter filename: Nome del file audio (es. "wave1")
    private func crossfadeTo(_ filename: String) {
        // Cerca il file nella root del bundle (folder reference copia i file nella root)
        guard let url = Bundle.main.url(forResource: filename, withExtension: "m4a") else {
            debugLog("⚠️ Audio file not found: \(filename).m4a")
            return
        }
        
        do {
            // Prepara il nuovo player
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1  // Loop infinito
            newPlayer.volume = 0.0
            newPlayer.prepareToPlay()
            newPlayer.play()
            
            // Se c'è un player corrente attivo, esegui il crossfade
            if let currentPlayer = musicPlayerCurrent, currentPlayer.isPlaying {
                musicPlayerNext = newPlayer
                startCrossfade()
            } else {
                // Nessun player attivo, fade in diretto
                musicPlayerCurrent = newPlayer
                fadeInMusic()
            }
            
            debugLog("🎵 Started music: \(filename)")
        } catch {
            debugLog("⚠️ Error loading audio file: \(error)")
        }
    }
    
    /// Avvia il crossfade tra currentPlayer e nextPlayer
    private func startCrossfade() {
        // Cancella eventuali timer precedenti
        crossfadeTimer?.invalidate()
        
        let steps = 30  // 30 step di interpolazione
        let duration = 1.0  // 1 secondo totale
        let interval = duration / Double(steps)
        var currentStep = 0
        
        let initialVolumeOut = musicPlayerCurrent?.volume ?? 1.0
        let initialVolumeIn: Float = 0.0
        
        crossfadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            
            // Fade out del player corrente
            if let current = self.musicPlayerCurrent {
                current.volume = initialVolumeOut * (1.0 - progress)
            }
            
            // Fade in del player successivo
            if let next = self.musicPlayerNext {
                next.volume = initialVolumeIn + progress
            }
            
            // Quando raggiungiamo l'ultimo step
            if currentStep >= steps {
                timer.invalidate()
                
                // Ferma e rilascia il vecchio player
                self.musicPlayerCurrent?.stop()
                self.musicPlayerCurrent = self.musicPlayerNext
                self.musicPlayerNext = nil
                
                debugLog("🎵 Crossfade completed")
            }
        }
    }
    
    /// Fade in della musica corrente (da 0 a 1 in 1 secondo)
    private func fadeInMusic() {
        crossfadeTimer?.invalidate()
        
        let steps = 30
        let duration = 1.0
        let interval = duration / Double(steps)
        var currentStep = 0
        
        crossfadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            
            if let current = self.musicPlayerCurrent {
                current.volume = progress
            }
            
            if currentStep >= steps {
                timer.invalidate()
                debugLog("🎵 Fade in completed")
            }
        }
    }
    
    /// Ferma la musica con fade out
    private func fadeOutAndStop() {
        guard let currentPlayer = musicPlayerCurrent, currentPlayer.isPlaying else {
            return
        }
        
        crossfadeTimer?.invalidate()
        
        let steps = 30
        let duration = 1.0
        let interval = duration / Double(steps)
        var currentStep = 0
        let initialVolume = currentPlayer.volume
        
        crossfadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            
            if let current = self.musicPlayerCurrent {
                current.volume = initialVolume * (1.0 - progress)
            }
            
            if currentStep >= steps {
                timer.invalidate()
                self.musicPlayerCurrent?.stop()
                self.musicPlayerCurrent = nil
                debugLog("🎵 Music stopped")
            }
        }
    }
}
