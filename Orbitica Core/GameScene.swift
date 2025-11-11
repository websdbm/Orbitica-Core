//
//  GameScene.swift
//  Orbitica Core - GRAVITY SHIELD
//
//  Created by Alessandro Grassi on 07/11/25.
//

import SpriteKit
import GameplayKit
import AVFoundation
import UIKit

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
    case square(AsteroidSize)    // Asteroide quadrato (arancione, cambia direzione random)
    case repulsor(AsteroidSize)  // Asteroide repulsore (viola, sfera con particelle, respinge il player)
    
    var size: AsteroidSize {
        switch self {
        case .normal(let size), .fast(let size), .armored(let size), .explosive(let size), .heavy(let size), .square(let size), .repulsor(let size):
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
        case .square: return UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0)  // Arancione
        case .repulsor: return UIColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0)  // Viola
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
        case .square: return 2    // Square richiede 2 colpi (doppia resistenza)
        case .repulsor: return 2  // Repulsor richiede 2 colpi
        default: return 1
        }
    }
    
    var atmosphereDamageMultiplier: CGFloat {
        switch self {
        case .heavy: return 4.0  // Quadruplo danno all'atmosfera
        case .square: return 2.0 // Doppio danno all'atmosfera
        default: return 1.0
        }
    }
    
    var repulsionForce: CGFloat {
        switch self {
        case .repulsor(let size):
            // Forza di repulsione proporzionale alla dimensione
            switch size {
            case .large: return 150.0   // Repulsione forte
            case .medium: return 100.0  // Repulsione media (2/3 di large)
            case .small: return 50.0    // Repulsione debole (1/3 di large)
            }
        default: return 0.0
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

// MARK: - Space Environments
enum SpaceEnvironment: CaseIterable {
    // NUOVI AMBIENTI ENHANCED (Priorità per release)
    case cosmicNebula       // Nebulosa Cosmica con nebula02 ⭐ NUOVO
    case animatedCosmos     // Sistemi solari animati + galassie rotanti ⭐ NUOVO
    case deepSpaceEnhanced  // Deep Space con starfield dinamico multi-layer
    case nebulaGalaxy       // Galassie/Nebulose animate con particelle dust ⭐ NUOVO
    
    // AMBIENTI ORIGINALI (da mantenere per ora)
    case deepSpace      // Nero profondo con stelle twinkle e colorate
    case nebula         // Nebulose colorate (blu/viola/rosa) con sfumature
    case voidSpace      // Gradiente nero-blu con stelle luminose
    case redGiant       // Stella rossa gigante con atmosfera calda
    case asteroidBelt   // Campo di asteroidi distanti
    case binaryStars    // Sistema binario con due stelle
    case ionStorm       // Tempesta di ioni elettrica
    case pulsarField    // Stella pulsar con onde radio pulsanti
    case planetarySystem // Sistema planetario con pianeti in orbita
    case cometTrail     // Comete con scie luminose
    case darkMatterCloud // Nuvole di materia oscura con particelle
    case supernovaRemnant // Espansione gas da esplosione stellare
    
    var name: String {
        switch self {
        case .cosmicNebula: return "Cosmic Nebula ★"  // NUOVO - Primo (nebula02)
        case .animatedCosmos: return "Animated Cosmos ★"  // NUOVO
        case .deepSpaceEnhanced: return "Deep Space ★"  // Stella per indicare versione enhanced
        case .nebulaGalaxy: return "Nebula Galaxy ★"  // NUOVO (nebula01)
        case .deepSpace: return "Deep Space"
        case .nebula: return "Nebula"
        case .voidSpace: return "Void Space"
        case .redGiant: return "Red Giant"
        case .asteroidBelt: return "Asteroid Belt"
        case .binaryStars: return "Binary Stars"
        case .ionStorm: return "Ion Storm"
        case .pulsarField: return "Pulsar Field"
        case .planetarySystem: return "Planetary System"
        case .cometTrail: return "Comet Trail"
        case .darkMatterCloud: return "Dark Matter Cloud"
        case .supernovaRemnant: return "Supernova Remnant"
        }
    }
}

// MARK: - Game Scene
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Debug flag - imposta su true per abilitare i log
    private let debugMode: Bool = false
    
    // Starting wave (per debug scene)
    var startingWave: Int = 1
    
    // AI Controller configuration
    var useAIController: Bool = false
    var aiDifficulty: AIController.AIDifficulty = .normal
    private var aiController: AIController?
    private var aiTargetPosition: CGPoint?  // Target dell'AI per puntare la nave
    
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
    private var brakeFlame: SKNode!  // Può essere SKEmitterNode o SKShapeNode
    
    // Planet & Atmosphere
    private var planet: SKShapeNode!
    private var atmosphere: SKShapeNode!
    private var planetOriginalColor: UIColor = .white  // Memorizza il colore originale del pianeta
    private var atmosphereRadius: CGFloat = 96  // Aumentato del 20% (80 * 1.2)
    private let maxAtmosphereRadius: CGFloat = 96  // Aumentato del 20% (80 * 1.2)
    private let minAtmosphereRadius: CGFloat = 40
    
    // Orbital Ring (grapple system) - 3 anelli concentrici
    private var orbitalRing1: SKShapeNode?  // Anello interno
    private var orbitalRing2: SKShapeNode?  // Anello medio
    private var orbitalRing3: SKShapeNode?  // Anello esterno
    private let orbitalRing1Radius: CGFloat = 200
    private let orbitalRing2Radius: CGFloat = 300  // +100px dal precedente (era 280)
    private let orbitalRing3Radius: CGFloat = 430  // +130px dal precedente (era 360) - molto più largo
    private let orbitalBaseAngularVelocity: CGFloat = 0.28  // Velocità bilanciata (più veloce del player ma non eccessiva)
    private var orbitalRing1IsEllipse: Bool = false
    private var orbitalRing2IsEllipse: Bool = false
    private var orbitalRing3IsEllipse: Bool = false
    private let ellipseRatio: CGFloat = 1.5  // Ratio dell'ellisse (larghezza/altezza)
    private let orbitalGrappleThreshold: CGFloat = 15    // distanza per aggancio (aumentata da 8 per ellissi)
    private let orbitalDetachThreshold: CGFloat = 18     // distanza per sgancio (ridotto per facilitare)
    private let orbitalDetachForce: CGFloat = 50        // forza necessaria per sganciarsi (ulteriormente ridotta)
    private var isGrappledToOrbit: Bool = false
    private var orbitalGrappleStrength: CGFloat = 0.0   // 0.0 = libero, 1.0 = completamente agganciato
    private var currentOrbitalRing: Int = 0  // 1, 2, o 3 - quale anello è agganciato
    private var lastOrbitalVelocity: CGVector = .zero    // Ultima velocità orbitale calcolata (per conservazione moto allo sgancio)
    private var justDetachedFromOrbit: Bool = false      // Flag per evitare interferenze subito dopo lo sgancio
    private var detachCooldownFrames: Int = 0            // Frames di cooldown dopo sgancio
    private var radialThrustAccumulator: CGFloat = 0.0   // Accumula spinta radiale per sgancio graduale (serve "attrito")
    // Player slingshot state
    private var playerSlingshotOrbits: Int = 0
    private var playerSlingshotStartAngle: CGFloat = 0.0
    private var playerSlingshotTargetRadius: CGFloat = 0.0
    
    // VECCHIO Slingshot Zones system (DISATTIVATO)
    // private let slingshotCaptureThreshold: CGFloat = 50
    // private let slingshotCaptureChance: CGFloat = 0.85
    // private let slingshotReleaseChancePerFrame: CGFloat = 0.005
    // private let slingshotEjectChance: CGFloat = 0.001
    // private let slingshotBoostMultiplier: CGFloat = 0.6
    // private let slingshotMaxDuration: TimeInterval = 7.0
    // private var lastSlingshotCheck: TimeInterval = 0
    
    // NUOVO: Spiral Descent System - Forze continue per movimento a spirale
    private let spiralInfluenceDistance: CGFloat = 40      // Distanza di influenza dal ring - RIDOTTA (era 80)
    private let spiralTangentialForce: CGFloat = 40        // Forza tangenziale debole come piccolo reattore
    private let spiralRadialForce: CGFloat = 150           // Forza radiale verso l'interno (discesa principale)
    private let spiralDamping: CGFloat = 0.96              // Damping leggero per fluidità
    
    // Planet health system
    private var planetHealth: Int = 3
    private let maxPlanetHealth: Int = 3
    private var planetHealthLabel: SKLabelNode!
    
    // Physics constants
    private let planetRadius: CGFloat = 40
    private let planetMass: CGFloat = 10000
    private let gravitationalConstant: CGFloat = 100  // Aumentata da 80 per attrazione più forte
    
    // Camera & Layers
    private var gameCamera: SKCameraNode!
    private var worldLayer: SKNode!
    private var hudLayer: SKNode!
    
    // Parallax background layers
    private var starsLayer1: SKNode?  // Stelle più lontane (movimento lento)
    private var starsLayer2: SKNode?  // Stelle medie
    private var starsLayer3: SKNode?  // Stelle più vicine (movimento veloce)
    private var nebulaLayer: SKNode?  // Layer per nebulose (opzionale)
    private var currentEnvironment: SpaceEnvironment = .deepSpace
    
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
    
    // Controls (optional perché non vengono creati in AI mode)
    private var joystick: JoystickNode?
    private var fireButton: FireButtonNode?
    private var brakeButton: BrakeButtonNode?
    private var joystickDirection = CGVector.zero
    private var isBraking = false
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
    
    // OTTIMIZZAZIONE: Limite detriti per performance
    private let maxSmallDebris: Int = 25  // Max 25 detriti small contemporaneamente
    
    // Wave system
    private var currentWave: Int = 0
    private var isWaveActive: Bool = false
    private var asteroidsToSpawnInWave: Int = 0
    private var asteroidsSpawnedInWave: Int = 0
    private var currentWaveConfig: WaveConfig?
    private var asteroidSpawnQueue: [AsteroidType] = []  // Coda di spawn
    private var asteroidGravityMultiplier: CGFloat = 1.25  // Base: 1.25 (ridotto da 1.4375), aumenta del 5% per wave
    private var debrisCleanupActive: Bool = false  // Gravità aumentata per cleanup detriti
    
    // Collision tracking
    private var lastCollisionTime: TimeInterval = 0
    private let collisionCooldown: TimeInterval = 0.5  // 500ms tra collisioni
    private var lastUpdateTime: TimeInterval = 0  // Traccia l'ultimo currentTime da update
    private var frameCount: Int = 0  // Contatore frame per debug periodici
    
    // Score
    private var score: Int = 0
    private var scoreLabel: SKLabelNode!
    private var waveLabel: SKLabelNode!  // Wave corrente in alto al centro
    // Power-up HUD label (sotto il punteggio in alto a destra)
    private var powerupLabel: SKLabelNode!

    // Power-up state
    private var vulcanActive: Bool = false
    private var bigAmmoActive: Bool = false
    private var atmosphereActive: Bool = false
    private var gravityActive: Bool = false  // Nuovo: Gravity power-up
    private var waveBlastActive: Bool = false  // Nuovo: Wave Blast power-up
    private var missileActive: Bool = false  // Nuovo: Missile homing
    private var activePowerupEndTime: TimeInterval = 0
    private var missiles: [SKNode] = []  // Array per tracciare tutti i missili attivi
    
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
    private var explosionPlayer: AVAudioPlayer?  // Suono esplosioni
    
    // Haptic feedback
    private var impactFeedback: UIImpactFeedbackGenerator?
    
    // MARK: - Setup
    override func didMove(to view: SKView) {
        print("🎯 didMove called - useAIController: \(useAIController), aiDifficulty: \(aiDifficulty)")
        debugLog("🎯 didMove called - useAIController: \(useAIController), aiDifficulty: \(aiDifficulty)")
        
        backgroundColor = .black
        
        // Mantieni lo schermo acceso durante il gioco
        UIApplication.shared.isIdleTimerDisabled = true
        
        // FISICA: Configura la fisica della scena
        physicsWorld.gravity = .zero  // Niente gravità di default, la applichiamo manualmente
        physicsWorld.contactDelegate = self
        
        // OTTIMIZZAZIONE: Riduci la precisione fisica per migliorare le performance
        physicsWorld.speed = 1.0  // Velocità normale
        // Riduce le iterazioni fisiche per frame - migliora performance con molti oggetti
        // Default è spesso 10, riduciamo a 5 per performance migliori
        if let sceneView = self.view {
            sceneView.preferredFramesPerSecond = 60  // Target 60 FPS
        }
        
        debugLog("=== GRAVITY SHIELD ===")
        debugLog("Scene size: \(size)")
        debugLog("======================")
        
        // Crea texture per particelle
        createParticleTexture()
        
        // Carica suoni degli spari
        loadShootSounds()
        
        // Prepara haptic feedback (solo su dispositivi che lo supportano)
        impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback?.prepare()
        
        setupLayers()
        setupCamera()
        setupPlanet()
        setupAtmosphere()
        setupOrbitalRing()
        setupPlayer()
        setupControls()
        setupScore()
        setupWaveLabel()
        setupPauseButton()
        
        // Avvia la wave iniziale (1 o quella selezionata dal debug)
        startWave(startingWave)
    }
    
    override func willMove(from view: SKView) {
        // Ripristina idle timer quando esci dalla scena
        UIApplication.shared.isIdleTimerDisabled = false
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
        if let url1 = Bundle.main.url(forResource: "sparo1", withExtension: "m4a") {
            shootSound1 = try? AVAudioPlayer(contentsOf: url1)
            shootSound1?.prepareToPlay()
        }
        if let url2 = Bundle.main.url(forResource: "sparo2", withExtension: "m4a") {
            shootSound2 = try? AVAudioPlayer(contentsOf: url2)
            shootSound2?.prepareToPlay()
        }
        if let url3 = Bundle.main.url(forResource: "sparo3", withExtension: "m4a") {
            shootSound3 = try? AVAudioPlayer(contentsOf: url3)
            shootSound3?.prepareToPlay()
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
        sound?.play()
    }
    
    private func setupLayers() {
        // World layer: contiene tutti gli oggetti di gioco (player, pianeta, asteroidi, etc)
        // DEVE essere creato PRIMA del background perché alcuni setup lo usano!
        worldLayer = SKNode()
        worldLayer.position = .zero  // Nessun offset, usiamo coordinate assolute
        addChild(worldLayer)
        
        debugLog("✅ World layer created")
        
        // Background parallax layers - DIETRO a tutto (dopo worldLayer)
        setupParallaxBackground()
    }
    
    // MARK: - Environment Cleanup
    
    /// Rimuove TUTTI gli effetti specifici dell'ambiente precedente
    /// Chiamata PRIMA di applicare un nuovo ambiente per evitare sovrapposizioni
    private func cleanupPreviousEnvironment() {
        print("🧹 Cleaning up previous environment effects...")
        
        // 1. Rimuovi TUTTI gli emitter di particelle dal worldLayer
        worldLayer.children.forEach { node in
            if node is SKEmitterNode {
                print("   ❌ Removing emitter: \(node.name ?? "unnamed")")
                node.removeFromParent()
            }
        }
        
        // 2. Rimuovi nodi specifici degli ambienti enhanced (PER NOME)
        let environmentNodes = [
            "backgroundStars",          // Cosmic Nebula, Nebula Galaxy
            "cosmicNebulaLayer1",       // Cosmic Nebula 3-layer (fondo)
            "cosmicNebulaLayer2",       // Cosmic Nebula 3-layer (medio)
            "cosmicNebulaLayer3",       // Cosmic Nebula 3-layer (fronte)
            "mainNebula",               // Nebula Galaxy sprite
            "mainSolarSystem",          // Animated Cosmos
            "parallaxStarfield",        // Deep Space Enhanced
            "nebula",                   // Altri ambienti
            "starfield"                 // Altri starfield
        ]
        
        for nodeName in environmentNodes {
            if let node = worldLayer.childNode(withName: nodeName) {
                print("   ❌ Removing: \(nodeName)")
                node.removeFromParent()
            }
        }
        
        // 3. Rimuovi TUTTI i nodi con nomi che contengono keywords di ambiente
        // MA PROTEGGI i nodi di gioco essenziali
        let protectedNames = ["planet", "atmosphere", "player", "asteroid", "bullet", "powerup", "orbital"]
        let environmentKeywords = ["dust", "nebula", "solar", "cosmic", "star", "galaxy"]
        
        worldLayer.children.forEach { node in
            if let nodeName = node.name?.lowercased() {
                // Verifica se è protetto
                let isProtected = protectedNames.contains { nodeName.contains($0.lowercased()) }
                
                if !isProtected {
                    // Verifica se contiene keyword di ambiente
                    let isEnvironmentNode = environmentKeywords.contains { nodeName.contains($0) }
                    
                    if isEnvironmentNode {
                        print("   ❌ Removing environment keyword node: \(node.name ?? "unnamed")")
                        node.removeFromParent()
                    }
                }
            }
        }
        
        print("✅ Environment cleanup complete")
    }
    
    private func setupParallaxBackground() {
        // Sequenza fissa basata sulla wave corrente (ciclo attraverso tutti i 12 ambienti)
        let environments: [SpaceEnvironment] = [
            .cosmicNebula,       // Wave 1 - Nebulosa Cosmica (nebula02) ⭐ PRIMO TEST
            .nebulaGalaxy,       // Wave 2 - Galassie/Nebulose (nebula01) ⭐
            .animatedCosmos,     // Wave 3 - Sistema Solare Animato ⭐
            .voidSpace,          // Wave 4
            .redGiant,           // Wave 4
            .asteroidBelt,       // Wave 5
            .binaryStars,        // Wave 6
            .ionStorm,           // Wave 7
            .pulsarField,        // Wave 8
            .planetarySystem,    // Wave 9
            .cometTrail,         // Wave 10
            .darkMatterCloud,    // Wave 11
            .supernovaRemnant    // Wave 12
        ]
        
        // Usa modulo per ciclare attraverso gli ambienti - FIX: gestisci wave 0
        let safeWave = max(1, currentWave)  // Minimo wave 1
        let environmentIndex = (safeWave - 1) % environments.count
        currentEnvironment = environments[environmentIndex]
        
        applyEnvironment(currentEnvironment)
        
        debugLog("✅ Parallax background created - Wave \(currentWave) - Environment: \(currentEnvironment.name)")
    }
    
    private func applyEnvironment(_ environment: SpaceEnvironment) {
        // PULIZIA COMPLETA degli effetti dell'ambiente precedente
        cleanupPreviousEnvironment()
        
        // Rimuovi layer esistenti (legacy) - con guard per evitare crash
        starsLayer1?.removeFromParent()
        starsLayer1 = nil
        starsLayer2?.removeFromParent()
        starsLayer2 = nil
        starsLayer3?.removeFromParent()
        starsLayer3 = nil
        nebulaLayer?.removeFromParent()
        nebulaLayer = nil
        
        // Rimuovi anche starfield dinamico se presente
        childNode(withName: "dynamicStarfield")?.removeFromParent()
        
        switch environment {
        case .cosmicNebula:
            setupCosmicNebulaEnvironment()
        case .deepSpaceEnhanced:
            setupDeepSpaceEnhancedEnvironment()
        case .animatedCosmos:
            setupAnimatedCosmosEnvironment()
        case .nebulaGalaxy:
            setupNebulaGalaxyEnvironment()
        case .deepSpace:
            setupDeepSpaceEnvironment()
        case .nebula:
            setupNebulaEnvironment()
        case .voidSpace:
            setupVoidSpaceEnvironment()
        case .redGiant:
            setupRedGiantEnvironment()
        case .asteroidBelt:
            setupAsteroidBeltEnvironment()
        case .binaryStars:
            setupBinaryStarsEnvironment()
        case .ionStorm:
            setupIonStormEnvironment()
        case .pulsarField:
            setupPulsarFieldEnvironment()
        case .planetarySystem:
            setupPlanetarySystemEnvironment()
        case .cometTrail:
            setupCometTrailEnvironment()
        case .darkMatterCloud:
            setupDarkMatterCloudEnvironment()
        case .supernovaRemnant:
            setupSupernovaRemnantEnvironment()
        }
        
        currentEnvironment = environment
    }
    
    // MARK: - Enhanced Environment Setup
    
    private func setupDeepSpaceEnhancedEnvironment() {
        // Background nero profondo
        backgroundColor = .black
        
        print("🔍 Creating discrete parallax starfield in worldLayer")
        
        // Starfield discreto nel worldLayer - parte del mondo di gioco
        let starfieldContainer = SKNode()
        starfieldContainer.name = "parallaxStarfield"
        starfieldContainer.zPosition = -1000  // DIETRO a tutto
        starfieldContainer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Layer 1: stelle lontane - piccole, lente
        let distantLayer = makeParallaxStarEmitter(
            speed: 8,   // Lente per sfondo discreto
            scale: 0.10,  // Piccole ma visibili
            birthRate: 1.0,
            color: UIColor.white.withAlphaComponent(0.5)
        )
        starfieldContainer.addChild(distantLayer)
        
        // Layer 2: stelle medie
        let midLayer = makeParallaxStarEmitter(
            speed: 15,  // Medie
            scale: 0.14,  // Medie
            birthRate: 1.5,
            color: UIColor.white.withAlphaComponent(0.6)
        )
        starfieldContainer.addChild(midLayer)
        
        // Layer 3: stelle vicine - più grandi per effetto parallasse
        let nearLayer = makeParallaxStarEmitter(
            speed: 25,  // Più veloci
            scale: 0.18,  // Più visibili
            birthRate: 2.0,
            color: UIColor.cyan.withAlphaComponent(0.5)
        )
        starfieldContainer.addChild(nearLayer)
        
        // AGGIUNGI AL WORLD LAYER - fa parte del mondo di gioco
        worldLayer.addChild(starfieldContainer)
        
        print("⭐ Discrete parallax starfield created in worldLayer")
        print("   - Container position: \(starfieldContainer.position)")
        print("   - Container zPosition: \(starfieldContainer.zPosition)")
        print("   - Parent: worldLayer")
        print("   - 3 layers - speeds: 8, 15, 25 px/s")
        print("   - Scales: 0.10, 0.14, 0.18 (small but visible)")
        print("   - Alpha: 0.5-0.6 (faint but visible)")
        
        debugLog("⭐ Discrete parallax starfield (world-based)")
    }
    
    // Emitter specifico per parallasse scrolling - stelle discrete ma visibili
    func makeParallaxStarEmitter(speed: CGFloat, scale: CGFloat, birthRate: CGFloat, color: UIColor) -> SKEmitterNode {
        let texture = createStarParticleTexture()
        
        let emitter = SKEmitterNode()
        emitter.particleTexture = texture
        emitter.particleBirthRate = birthRate
        emitter.particleColor = color
        
        // Lifetime lungo per coprire area ampia del mondo
        let playAreaWidth = size.width * playFieldMultiplier
        emitter.particleLifetime = playAreaWidth / speed
        emitter.particleSpeed = speed
        emitter.particleScale = scale
        emitter.particleColorBlendFactor = 1
        emitter.particleScaleRange = scale * 0.3
        
        // Spawn in AREA AMPIA intorno al mondo di gioco
        let playAreaHeight = size.height * playFieldMultiplier
        emitter.position = CGPoint(x: playAreaWidth / 2, y: 0)
        emitter.particlePositionRange = CGVector(dx: playAreaWidth, dy: playAreaHeight)
        emitter.particleSpeedRange = 0  // Velocità costante per parallasse pulito
        
        // Emissione verso SINISTRA (da destra a sinistra)
        emitter.emissionAngle = .pi  // 180 gradi
        emitter.emissionAngleRange = 0
        
        // Alpha moderato - visibile ma discreto
        emitter.particleAlpha = 0.6
        emitter.particleAlphaRange = 0.3
        emitter.particleBlendMode = .alpha
        
        print("   🔹 Parallax layer: speed=\(speed), scale=\(scale), alpha=0.6, area=\(Int(playAreaWidth))x\(Int(playAreaHeight))")
        
        return emitter
    }
    
    // MARK: - Animated Cosmos Environment (Solar Systems + Galaxies)
    
    private func setupAnimatedCosmosEnvironment() {
        // Background nero profondo
        backgroundColor = .black
        
        print("🌌 Creating Spectacular Animated Solar System")
        
        let playAreaWidth = size.width * playFieldMultiplier
        let playAreaHeight = size.height * playFieldMultiplier
        
        // 1. STELLE DI SFONDO (discrete e statiche)
        let backgroundStars = SKNode()
        backgroundStars.name = "backgroundStars"
        backgroundStars.zPosition = -1000
        backgroundStars.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        for _ in 0..<120 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.4...1.2))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.25...0.5)
            star.position = CGPoint(
                x: CGFloat.random(in: -playAreaWidth/2...playAreaWidth/2),
                y: CGFloat.random(in: -playAreaHeight/2...playAreaHeight/2)
            )
            backgroundStars.addChild(star)
        }
        worldLayer.addChild(backgroundStars)
        
        // 2. NEBULOSA DISTANTE (sfondo elegante)
        let nebula = SKShapeNode(circleOfRadius: 450)
        nebula.fillColor = UIColor(red: 0.35, green: 0.25, blue: 0.65, alpha: 0.08)
        nebula.strokeColor = .clear
        nebula.glowWidth = 120
        nebula.zPosition = -950
        nebula.position = CGPoint(
            x: size.width/2 - 400,
            y: size.height/2 + 300
        )
        worldLayer.addChild(nebula)
        
        // Rotazione lentissima nebulosa
        let nebulaRotate = SKAction.rotate(byAngle: .pi * 2, duration: 180)
        nebula.run(SKAction.repeatForever(nebulaRotate))
        
        // 3. SISTEMA SOLARE SPETTACOLARE - UN SOLO GRANDE SISTEMA AL CENTRO
        createRealisticSolarSystem()
        
        print("✨ Spectacular Solar System created - realistic orbits and speeds")
        debugLog("🌌 Animated Cosmos environment complete")
    }
    
    // Crea un sistema solare realistico con orbite ellittiche e velocità diverse
    private func createRealisticSolarSystem() {
        let systemNode = SKNode()
        systemNode.name = "mainSolarSystem"
        systemNode.zPosition = -800
        
        // POSIZIONE RANDOM ma LONTANA dal centro (evita sovrapposizione con pianeta)
        let playAreaWidth = size.width * playFieldMultiplier
        let playAreaHeight = size.height * playFieldMultiplier
        
        // Scegli un quadrante random (angoli del mondo)
        let quadrants: [(x: CGFloat, y: CGFloat)] = [
            (size.width * 0.20, size.height * 0.75),  // Alto sinistra
            (size.width * 0.80, size.height * 0.75),  // Alto destra
            (size.width * 0.20, size.height * 0.25),  // Basso sinistra
            (size.width * 0.80, size.height * 0.25)   // Basso destra
        ]
        
        let chosenQuadrant = quadrants.randomElement()!
        systemNode.position = CGPoint(x: chosenQuadrant.x, y: chosenQuadrant.y)
        
        // SCALA ENORME - IL DOPPIO (5x invece di 2.5x)
        systemNode.setScale(5.0)
        
        // OPACITÀ 100% - colori scuri faranno da silhouette
        systemNode.alpha = 1.0
        
        // STELLA CENTRALE - Silhouette visibile ma elegante
        let sunSize: CGFloat = 35
        let sun = SKShapeNode(circleOfRadius: sunSize)
        sun.fillColor = UIColor(red: 0.22, green: 0.18, blue: 0.12, alpha: 1.0)  // Marrone più chiaro
        sun.strokeColor = UIColor(red: 0.28, green: 0.22, blue: 0.15, alpha: 0.6)
        sun.lineWidth = 2
        sun.glowWidth = sunSize * 0.3
        systemNode.addChild(sun)
        
        // Alone solare (corona) - più visibile
        let corona = SKShapeNode(circleOfRadius: sunSize * 1.3)
        corona.fillColor = UIColor(red: 0.18, green: 0.15, blue: 0.12, alpha: 0.3)
        corona.strokeColor = .clear
        corona.glowWidth = 8
        systemNode.addChild(corona)
        
        // Pulsazione sole (PIÙ LENTA - raddoppiata)
        let sunPulse = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.08, duration: 7.0),  // Era 3.5s -> 7.0s
                SKAction.fadeAlpha(to: 0.85, duration: 7.0)
            ]),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 7.0),
                SKAction.fadeAlpha(to: 1.0, duration: 7.0)
            ])
        ])
        sun.run(SKAction.repeatForever(sunPulse))
        corona.run(SKAction.repeatForever(sunPulse))
        
        // PIANETI CON CARATTERISTICHE REALISTICHE - COLORI SILHOUETTE PIÙ VISIBILI
        // Ogni pianeta ha: distanza, dimensione, colore, velocità orbitale (RALLENTATA +50%), angolo iniziale
        let planets: [(name: String, distance: CGFloat, size: CGFloat, color: UIColor, speed: Double, hasRings: Bool, hasMoon: Bool, startAngle: CGFloat)] = [
            // Mercurio - grigio (30 -> 45s)
            ("Mercury", 80, 4, UIColor(red: 0.18, green: 0.17, blue: 0.16, alpha: 1.0), 45, false, false, 0),
            // Venere - beige (44 -> 66s)
            ("Venus", 120, 6, UIColor(red: 0.22, green: 0.20, blue: 0.16, alpha: 1.0), 66, false, false, .pi / 3),
            // Terra - blu (60 -> 90s)
            ("Earth", 170, 6.5, UIColor(red: 0.12, green: 0.15, blue: 0.20, alpha: 1.0), 90, false, true, .pi * 2 / 3),
            // Marte - rosso (84 -> 126s)
            ("Mars", 220, 5, UIColor(red: 0.20, green: 0.12, blue: 0.10, alpha: 1.0), 126, false, false, .pi),
            // Giove - marrone (130 -> 195s)
            ("Jupiter", 300, 14, UIColor(red: 0.19, green: 0.17, blue: 0.15, alpha: 1.0), 195, false, false, .pi * 4 / 3),
            // Saturno - giallo pallido (170 -> 255s)
            ("Saturn", 380, 12, UIColor(red: 0.20, green: 0.19, blue: 0.15, alpha: 1.0), 255, true, false, .pi * 5 / 3)
        ]
        
        for (index, planet) in planets.enumerated() {
            // Container per ogni pianeta (ruota per l'orbita)
            let orbitContainer = SKNode()
            orbitContainer.name = "\(planet.name)Orbit"
            
            // SFASAMENTO INIZIALE - ogni pianeta parte da un angolo diverso
            orbitContainer.zRotation = planet.startAngle
            
            systemNode.addChild(orbitContainer)
            
            // ORBITA CIRCOLARE - più visibile
            let orbitCircle = SKShapeNode(circleOfRadius: planet.distance)
            orbitCircle.strokeColor = UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 0.35)
            orbitCircle.lineWidth = 0.8
            orbitCircle.fillColor = .clear
            orbitCircle.glowWidth = 0.3
            systemNode.addChild(orbitCircle)
            
            // Pianeta - silhouette scura
            let planetNode = SKShapeNode(circleOfRadius: planet.size)
            planetNode.fillColor = planet.color
            planetNode.strokeColor = planet.color.withAlphaComponent(0.4)
            planetNode.lineWidth = 0.5
            planetNode.glowWidth = planet.size * 0.1  // Quasi nessun glow
            planetNode.position = CGPoint(x: planet.distance, y: 0)
            orbitContainer.addChild(planetNode)
            
            // Anelli (Saturno)
            if planet.hasRings {
                let ringRadius = planet.size * 2.2
                let ring = SKShapeNode(circleOfRadius: ringRadius)
                ring.strokeColor = planet.color.withAlphaComponent(0.5)
                ring.lineWidth = planet.size * 0.6
                ring.fillColor = .clear
                ring.glowWidth = 2
                planetNode.addChild(ring)
                
                // Anello interno
                let innerRing = SKShapeNode(circleOfRadius: ringRadius * 0.75)
                innerRing.strokeColor = planet.color.withAlphaComponent(0.3)
                innerRing.lineWidth = planet.size * 0.3
                innerRing.fillColor = .clear
                planetNode.addChild(innerRing)
            }
            
            // Luna (Terra) - grigio visibile
            if planet.hasMoon {
                let moonContainer = SKNode()
                planetNode.addChild(moonContainer)
                
                let moon = SKShapeNode(circleOfRadius: planet.size * 0.35)
                moon.fillColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)  // Grigio più chiaro
                moon.strokeColor = .clear
                moon.position = CGPoint(x: planet.size * 2.5, y: 0)
                moonContainer.addChild(moon)
                
                // Orbita luna (rallentata anche questa)
                let moonOrbit = SKAction.rotate(byAngle: .pi * 2, duration: planet.speed / 10)
                moonContainer.run(SKAction.repeatForever(moonOrbit))
            }
            
            // Rotazione orbitale (velocità diverse, realistiche)
            // Pianeti più distanti vanno più lenti (legge di Keplero approssimata)
            let orbitRotation = SKAction.rotate(byAngle: .pi * 2, duration: planet.speed)
            orbitContainer.run(SKAction.repeatForever(orbitRotation))
            
            // Auto-rotazione pianeta (molto più veloce dell'orbita)
            let planetRotation = SKAction.rotate(byAngle: .pi * 2, duration: planet.speed / 20)
            planetNode.run(SKAction.repeatForever(planetRotation))
            
            print("   🪐 \(planet.name): orbit=\(Int(planet.distance))px, size=\(planet.size), period=\(Int(planet.speed))s")
        }
        
        worldLayer.addChild(systemNode)
        print("   ⭐ Main solar system created with 6 planets (realistic speeds)")
    }
    
    // Helper: crea path ellittico
    private func createEllipsePath(radiusX: CGFloat, radiusY: CGFloat, segments: Int) -> CGPath {
        let path = CGMutablePath()
        let angleStep = (2.0 * .pi) / CGFloat(segments)
        
        for i in 0...segments {
            let angle = angleStep * CGFloat(i)
            let x = radiusX * cos(angle)
            let y = radiusY * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
    
    // MARK: - Cosmic Nebula Environment (nebula02 + particelle)
    
    private func setupCosmicNebulaEnvironment() {
        backgroundColor = .black
        
        print("🌌 Creating Cosmic Nebula environment with animated sprites")
        
        let playAreaWidth = size.width * playFieldMultiplier
        let playAreaHeight = size.height * playFieldMultiplier
        
        // 1. STELLE DI SFONDO statiche
        let backgroundStars = SKNode()
        backgroundStars.name = "backgroundStars"
        backgroundStars.zPosition = -1000
        backgroundStars.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        for _ in 0..<100 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.4...1.2))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.2...0.5)
            star.position = CGPoint(
                x: CGFloat.random(in: -playAreaWidth/2...playAreaWidth/2),
                y: CGFloat.random(in: -playAreaHeight/2...playAreaHeight/2)
            )
            backgroundStars.addChild(star)
        }
        worldLayer.addChild(backgroundStars)
        
        // 2. NEBULOSA TRIPLA LAYER (parallasse rotazionale concentrico)
        print("🔍 DEBUG: Creazione nebulosa a 3 layer con nebula02.png")
        
        let nebulaTexture = SKTexture(imageNamed: "nebula02")
        print("🔍 DEBUG: Texture size: \(nebulaTexture.size())")
        
        // Posizione condivisa per tutti i layer (stesso centro)
        let positions: [(x: CGFloat, y: CGFloat)] = [
            (size.width * 0.30, size.height * 0.70),
            (size.width * 0.70, size.height * 0.30),
            (size.width * 0.25, size.height * 0.40),
            (size.width * 0.75, size.height * 0.60)
        ]
        let sharedPosition = positions.randomElement()!
        let nebulaPosition = CGPoint(x: sharedPosition.x, y: sharedPosition.y)
        
        // Scala condivisa per tutti i layer
        let sharedScale = CGFloat.random(in: 2.5...3.5)
        
        // LAYER 1: Nebulosa di fondo (più lenta, più trasparente)
        let nebulaLayer1 = SKSpriteNode(texture: nebulaTexture)
        nebulaLayer1.name = "cosmicNebulaLayer1"
        nebulaLayer1.position = nebulaPosition
        nebulaLayer1.setScale(sharedScale)
        nebulaLayer1.alpha = 0.60  // 60% opacità (più in alto)
        nebulaLayer1.blendMode = .add
        nebulaLayer1.zPosition = -920  // Più lontano
        nebulaLayer1.zRotation = 0  // Parte da 0°
        worldLayer.addChild(nebulaLayer1)
        
        // LAYER 2: Nebulosa intermedia (velocità media, opacità media)
        let nebulaLayer2 = SKSpriteNode(texture: nebulaTexture)
        nebulaLayer2.name = "cosmicNebulaLayer2"
        nebulaLayer2.position = nebulaPosition
        nebulaLayer2.setScale(sharedScale)
        nebulaLayer2.alpha = 0.80  // 80% opacità (più in basso)
        nebulaLayer2.blendMode = .add
        nebulaLayer2.zPosition = -910  // Intermedio
        nebulaLayer2.zRotation = .pi * 2 / 3  // Parte da 120°
        worldLayer.addChild(nebulaLayer2)
        
        // LAYER 3: Nebulosa frontale (più veloce, più opaca)
        let nebulaLayer3 = SKSpriteNode(texture: nebulaTexture)
        nebulaLayer3.name = "cosmicNebulaLayer3"
        nebulaLayer3.position = nebulaPosition
        nebulaLayer3.setScale(sharedScale)
        nebulaLayer3.alpha = 1.0  // 100% opacità (più vicino)
        nebulaLayer3.blendMode = .add
        nebulaLayer3.zPosition = -900  // Più vicino
        nebulaLayer3.zRotation = .pi * 4 / 3  // Parte da 240°
        worldLayer.addChild(nebulaLayer3)
        
        // ROTAZIONI DIFFERENZIATE (parallasse concentrico)
        // Layer 1 (fondo): MOLTO LENTO
        let duration1 = 240.0  // 4 minuti per giro completo
        let rotate1 = SKAction.rotate(byAngle: .pi * 2, duration: duration1)
        nebulaLayer1.run(SKAction.repeatForever(rotate1))
        
        // Layer 2 (medio): MEDIO
        let duration2 = 160.0  // 2.67 minuti per giro completo (1.5x più veloce)
        let rotate2 = SKAction.rotate(byAngle: .pi * 2, duration: duration2)
        nebulaLayer2.run(SKAction.repeatForever(rotate2))
        
        // Layer 3 (fronte): PIÙ VELOCE
        let duration3 = 100.0  // 1.67 minuti per giro completo (2.4x più veloce del fondo)
        let rotate3 = SKAction.rotate(byAngle: .pi * 2, duration: duration3)
        nebulaLayer3.run(SKAction.repeatForever(rotate3))
        
        // Pulsazione leggera coordinata su tutti i layer
        let basePulseAlpha1: CGFloat = 0.60
        let basePulseAlpha2: CGFloat = 0.80
        let basePulseAlpha3: CGFloat = 1.0
        let pulseDuration = Double.random(in: 10...15)
        
        let pulse1 = SKAction.sequence([
            SKAction.fadeAlpha(to: basePulseAlpha1 * 0.7, duration: pulseDuration),
            SKAction.fadeAlpha(to: basePulseAlpha1, duration: pulseDuration)
        ])
        nebulaLayer1.run(SKAction.repeatForever(pulse1))
        
        let pulse2 = SKAction.sequence([
            SKAction.fadeAlpha(to: basePulseAlpha2 * 0.8, duration: pulseDuration * 0.9),
            SKAction.fadeAlpha(to: basePulseAlpha2, duration: pulseDuration * 0.9)
        ])
        nebulaLayer2.run(SKAction.repeatForever(pulse2))
        
        let pulse3 = SKAction.sequence([
            SKAction.fadeAlpha(to: basePulseAlpha3 * 0.9, duration: pulseDuration * 0.8),
            SKAction.fadeAlpha(to: basePulseAlpha3, duration: pulseDuration * 0.8)
        ])
        nebulaLayer3.run(SKAction.repeatForever(pulse3))
        
        print("   � Cosmic Nebula 3-layer parallax created:")
        print("      Layer 1 (back):   α=60%, rotation=\(Int(duration1))s (slowest)")
        print("      Layer 2 (mid):    α=80%, rotation=\(Int(duration2))s")
        print("      Layer 3 (front):  α=100%, rotation=\(Int(duration3))s (fastest)")
        print("      Scale: \(String(format: "%.2f", sharedScale))x")
        
        // 3. PARTICELLE DUST LEGGERE (2 emitter) - specifiche per Cosmic Nebula
        createCosmicNebulaDustEmitters()
        
        print("✨ Cosmic Nebula created with sprite + dust particles")
        debugLog("🌌 Cosmic Nebula environment complete")
    }
    
    // MARK: - Nebula Galaxy Environment (Galassie animate + particelle)
    
    private func setupNebulaGalaxyEnvironment() {
        backgroundColor = .black
        
        print("🌌 Creating Nebula Galaxy environment with animated sprites")
        
        let playAreaWidth = size.width * playFieldMultiplier
        let playAreaHeight = size.height * playFieldMultiplier
        
        // 1. STELLE DI SFONDO statiche
        let backgroundStars = SKNode()
        backgroundStars.name = "backgroundStars"
        backgroundStars.zPosition = -1000
        backgroundStars.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        for _ in 0..<100 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.4...1.2))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.2...0.5)
            star.position = CGPoint(
                x: CGFloat.random(in: -playAreaWidth/2...playAreaWidth/2),
                y: CGFloat.random(in: -playAreaHeight/2...playAreaHeight/2)
            )
            backgroundStars.addChild(star)
        }
        worldLayer.addChild(backgroundStars)
        
        // 2. NEBULOSA GRANDE ANIMATA (usando nebula01.png)
        // Debug: verifica caricamento immagine
        print("🔍 DEBUG: Tentativo caricamento nebula01.png")
        if let imagePath = Bundle.main.path(forResource: "nebula01", ofType: "png") {
            print("✅ DEBUG: PNG trovato al path: \(imagePath)")
        } else {
            print("❌ DEBUG: nebula01.png NON trovata nel bundle")
            print("📦 DEBUG: Risorse disponibili nel bundle:")
            if let resourcePath = Bundle.main.resourcePath {
                let fileManager = FileManager.default
                if let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                    let imageFiles = files.filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".png") }
                    print("   Immagini trovate: \(imageFiles)")
                }
            }
        }
        
        let nebulaTexture = SKTexture(imageNamed: "nebula01")
        print("🔍 DEBUG: Texture size: \(nebulaTexture.size())")
        let nebula = SKSpriteNode(texture: nebulaTexture)
        nebula.name = "mainNebula"
        nebula.zPosition = -900
        
        // Posizione random nel mondo (non al centro)
        let positions: [(x: CGFloat, y: CGFloat)] = [
            (size.width * 0.30, size.height * 0.70),
            (size.width * 0.70, size.height * 0.30),
            (size.width * 0.25, size.height * 0.40),
            (size.width * 0.75, size.height * 0.60)
        ]
        let chosenPos = positions.randomElement()!
        nebula.position = CGPoint(x: chosenPos.x, y: chosenPos.y)
        
        // Scala grande
        let nebulaScale = CGFloat.random(in: 2.5...3.5)
        nebula.setScale(nebulaScale)
        
        // Opacità bassa per sfondo elegante
        nebula.alpha = 0.25
        
        // Blend mode per effetto nebulosa
        nebula.blendMode = .add
        
        worldLayer.addChild(nebula)
        
        // ROTAZIONE MOLTO LENTA (120-180 secondi per giro completo)
        let rotationDuration = Double.random(in: 120...180)
        let rotationDirection: CGFloat = Bool.random() ? 1 : -1
        let rotate = SKAction.rotate(byAngle: .pi * 2 * rotationDirection, duration: rotationDuration)
        nebula.run(SKAction.repeatForever(rotate))
        
        // Pulsazione leggera dell'alpha
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.18, duration: Double.random(in: 8...12)),
            SKAction.fadeAlpha(to: 0.32, duration: Double.random(in: 8...12))
        ])
        nebula.run(SKAction.repeatForever(pulse))
        
        print("   🌫️ Nebula sprite loaded: scale=\(nebulaScale), rotation=\(Int(rotationDuration))s")
        
        // 3. PARTICELLE DUST LEGGERE (2 emitter) - specifiche per Nebula Galaxy
        createNebulaGalaxyDustEmitters()
        
        print("✨ Nebula Galaxy created with sprite + dust particles")
        debugLog("🌌 Nebula Galaxy environment complete")
    }
    
    // Crea emitter di particelle "dust" per Cosmic Nebula (nebula02)
    private func createCosmicNebulaDustEmitters() {
        let playAreaWidth = size.width * playFieldMultiplier
        let playAreaHeight = size.height * playFieldMultiplier
        
        // Emitter 1: Dust rosa-viola
        let dustEmitter1 = SKEmitterNode()
        dustEmitter1.name = "cosmicDustEmitter1"
        dustEmitter1.particleTexture = createDustTexture()
        dustEmitter1.particleBirthRate = 0.8
        dustEmitter1.particleLifetime = 60
        dustEmitter1.particleLifetimeRange = 20
        dustEmitter1.particleSpeed = 5
        dustEmitter1.particleSpeedRange = 3
        dustEmitter1.particleScale = 0.3
        dustEmitter1.particleScaleRange = 0.15
        dustEmitter1.particleScaleSpeed = -0.002
        dustEmitter1.particleAlpha = 0.4
        dustEmitter1.particleAlphaRange = 0.2
        dustEmitter1.particleAlphaSpeed = -0.005
        dustEmitter1.particleColor = UIColor(red: 0.7, green: 0.3, blue: 0.6, alpha: 1.0)
        dustEmitter1.particleColorBlendFactor = 0.8
        dustEmitter1.particleBlendMode = .add
        dustEmitter1.emissionAngle = 0
        dustEmitter1.emissionAngleRange = .pi / 4
        dustEmitter1.particlePositionRange = CGVector(dx: playAreaWidth, dy: playAreaHeight * 0.5)
        dustEmitter1.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dustEmitter1.zPosition = -850
        dustEmitter1.targetNode = worldLayer
        
        worldLayer.addChild(dustEmitter1)
        
        let moveRight = SKAction.moveBy(x: 80, y: 20, duration: 40)
        let moveLeft = SKAction.moveBy(x: -80, y: -20, duration: 40)
        dustEmitter1.run(SKAction.repeatForever(SKAction.sequence([moveRight, moveLeft])))
        
        // Emitter 2: Dust blu-cyan
        let dustEmitter2 = SKEmitterNode()
        dustEmitter2.name = "cosmicDustEmitter2"
        dustEmitter2.particleTexture = createDustTexture()
        dustEmitter2.particleBirthRate = 0.6
        dustEmitter2.particleLifetime = 50
        dustEmitter2.particleLifetimeRange = 15
        dustEmitter2.particleSpeed = 8
        dustEmitter2.particleSpeedRange = 4
        dustEmitter2.particleScale = 0.25
        dustEmitter2.particleScaleRange = 0.12
        dustEmitter2.particleScaleSpeed = -0.003
        dustEmitter2.particleAlpha = 0.35
        dustEmitter2.particleAlphaRange = 0.15
        dustEmitter2.particleAlphaSpeed = -0.006
        dustEmitter2.particleColor = UIColor(red: 0.3, green: 0.6, blue: 0.8, alpha: 1.0)
        dustEmitter2.particleColorBlendFactor = 0.7
        dustEmitter2.particleBlendMode = .add
        dustEmitter2.emissionAngle = .pi / 2
        dustEmitter2.emissionAngleRange = .pi / 3
        dustEmitter2.particlePositionRange = CGVector(dx: playAreaWidth * 0.6, dy: playAreaHeight * 0.3)
        dustEmitter2.position = CGPoint(x: size.width * 0.7, y: size.height * 0.3)
        dustEmitter2.zPosition = -860
        dustEmitter2.targetNode = worldLayer
        
        worldLayer.addChild(dustEmitter2)
        
        let circlePath = CGMutablePath()
        circlePath.addArc(center: dustEmitter2.position, radius: 60, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        let circleMove = SKAction.follow(circlePath, asOffset: false, orientToPath: false, duration: 50)
        dustEmitter2.run(SKAction.repeatForever(circleMove))
        
        print("   ✨ Cosmic Nebula: 2 dust emitters created")
    }
    
    // Crea emitter di particelle "dust" per Nebula Galaxy (nebula01)
    private func createNebulaGalaxyDustEmitters() {
        let playAreaWidth = size.width * playFieldMultiplier
        let playAreaHeight = size.height * playFieldMultiplier
        
        // Emitter 1: Dust rosa-viola
        let dustEmitter1 = SKEmitterNode()
        dustEmitter1.name = "nebulaGalaxyDustEmitter1"
        dustEmitter1.particleTexture = createDustTexture()
        dustEmitter1.particleBirthRate = 0.8  // MOLTO BASSA
        dustEmitter1.particleLifetime = 60  // Lunga vita
        dustEmitter1.particleLifetimeRange = 20
        dustEmitter1.particleSpeed = 5  // Lente
        dustEmitter1.particleSpeedRange = 3
        dustEmitter1.particleScale = 0.3
        dustEmitter1.particleScaleRange = 0.15
        dustEmitter1.particleScaleSpeed = -0.002  // Diminuiscono lentamente
        dustEmitter1.particleAlpha = 0.4
        dustEmitter1.particleAlphaRange = 0.2
        dustEmitter1.particleAlphaSpeed = -0.005
        dustEmitter1.particleColor = UIColor(red: 0.7, green: 0.3, blue: 0.6, alpha: 1.0)  // Rosa-viola
        dustEmitter1.particleColorBlendFactor = 0.8
        dustEmitter1.particleBlendMode = .add
        dustEmitter1.emissionAngle = 0  // Orizzontale
        dustEmitter1.emissionAngleRange = .pi / 4
        dustEmitter1.particlePositionRange = CGVector(dx: playAreaWidth, dy: playAreaHeight * 0.5)
        dustEmitter1.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dustEmitter1.zPosition = -850
        dustEmitter1.targetNode = worldLayer
        
        worldLayer.addChild(dustEmitter1)
        
        // Movimento lento dell'emitter (sinistra-destra)
        let moveRight = SKAction.moveBy(x: 80, y: 20, duration: 40)
        let moveLeft = SKAction.moveBy(x: -80, y: -20, duration: 40)
        let moveSequence = SKAction.sequence([moveRight, moveLeft])
        dustEmitter1.run(SKAction.repeatForever(moveSequence))
        
        // Emitter 2: Dust blu-cyan
        let dustEmitter2 = SKEmitterNode()
        dustEmitter2.name = "nebulaGalaxyDustEmitter2"
        dustEmitter2.particleTexture = createDustTexture()
        dustEmitter2.particleBirthRate = 0.6
        dustEmitter2.particleLifetime = 50
        dustEmitter2.particleLifetimeRange = 15
        dustEmitter2.particleSpeed = 8
        dustEmitter2.particleSpeedRange = 4
        dustEmitter2.particleScale = 0.25
        dustEmitter2.particleScaleRange = 0.12
        dustEmitter2.particleScaleSpeed = -0.003
        dustEmitter2.particleAlpha = 0.35
        dustEmitter2.particleAlphaRange = 0.15
        dustEmitter2.particleAlphaSpeed = -0.006
        dustEmitter2.particleColor = UIColor(red: 0.3, green: 0.6, blue: 0.8, alpha: 1.0)  // Blu-cyan
        dustEmitter2.particleColorBlendFactor = 0.7
        dustEmitter2.particleBlendMode = .add
        dustEmitter2.emissionAngle = .pi / 2  // Verso l'alto
        dustEmitter2.emissionAngleRange = .pi / 3
        dustEmitter2.particlePositionRange = CGVector(dx: playAreaWidth * 0.6, dy: playAreaHeight * 0.3)
        dustEmitter2.position = CGPoint(x: size.width * 0.7, y: size.height * 0.3)
        dustEmitter2.zPosition = -860
        dustEmitter2.targetNode = worldLayer
        
        worldLayer.addChild(dustEmitter2)
        
        // Movimento circolare lento
        let circlePath = CGMutablePath()
        circlePath.addArc(center: dustEmitter2.position, radius: 60, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        let circleMove = SKAction.follow(circlePath, asOffset: false, orientToPath: false, duration: 50)
        dustEmitter2.run(SKAction.repeatForever(circleMove))
        
        print("   ✨ Nebula Galaxy: 2 dust emitters created")
    }
    
    // Crea texture per particelle dust (soft glow)
    private func createDustTexture() -> SKTexture {
        let size: CGFloat = 128
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return SKTexture()
        }
        
        let center = CGPoint(x: size / 2, y: size / 2)
        
        // Gradiente radiale soft per effetto "dust"
        let colors = [
            UIColor.white.withAlphaComponent(0.8).cgColor,
            UIColor.white.withAlphaComponent(0.4).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ] as CFArray
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 0.5, 1.0])!
        
        context.drawRadialGradient(gradient,
                                   startCenter: center, startRadius: 0,
                                   endCenter: center, endRadius: size / 2,
                                   options: [])
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return SKTexture(image: image)
        }
        
        return SKTexture()
    }
    
    // MARK: - Original Environment Setups
    
    private func setupDeepSpaceEnvironment() {
        // Background nero profondo
        backgroundColor = .black
        
        // Stelle di dimensioni variabili con colori
        starsLayer1 = createDeepSpaceStars(starCount: 100, zPosition: -30, sizeRange: CGFloat(0.8)...CGFloat(1.5), alphaRange: CGFloat(0.1)...CGFloat(0.3))
        starsLayer2 = createDeepSpaceStars(starCount: 70, zPosition: -20, sizeRange: CGFloat(1.5)...CGFloat(2.5), alphaRange: CGFloat(0.3)...CGFloat(0.5))
        starsLayer3 = createDeepSpaceStars(starCount: 50, zPosition: -10, sizeRange: CGFloat(2.0)...CGFloat(3.5), alphaRange: CGFloat(0.5)...CGFloat(0.7))
        
        if let layer1 = starsLayer1 { addChild(layer1) }
        if let layer2 = starsLayer2 { addChild(layer2) }
        if let layer3 = starsLayer3 { addChild(layer3) }
    }
    
    private func setupNebulaEnvironment() {
        // Background nero
        backgroundColor = .black
        
        // Layer nebulosa dietro alle stelle
        nebulaLayer = SKNode()
        nebulaLayer!.position = CGPoint(x: size.width / 2, y: size.height / 2)
        nebulaLayer!.zPosition = -40
        
        // Crea 3-4 nebulose grandi e sfumate
        let nebulaColors: [UIColor] = [
            UIColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 0.15),  // Viola
            UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.12),  // Blu
            UIColor(red: 0.8, green: 0.3, blue: 0.5, alpha: 0.10)   // Rosa
        ]
        
        let areaWidth = size.width * playFieldMultiplier
        let areaHeight = size.height * playFieldMultiplier
        
        for i in 0..<4 {
            let x = CGFloat.random(in: -areaWidth/2...areaWidth/2)
            let y = CGFloat.random(in: -areaHeight/2...areaHeight/2)
            let nebulaSize = CGFloat.random(in: CGFloat(400)...CGFloat(800))
            
            let nebula = SKShapeNode(circleOfRadius: nebulaSize)
            nebula.fillColor = nebulaColors[i % nebulaColors.count]
            nebula.strokeColor = .clear
            nebula.position = CGPoint(x: x, y: y)
            nebula.alpha = 0.8
            nebula.glowWidth = nebulaSize * 0.3
            
            // Animazione lenta di pulsazione
            let pulseOut = SKAction.scale(to: 1.15, duration: Double.random(in: Double(8)...Double(12)))
            let pulseIn = SKAction.scale(to: 0.85, duration: Double.random(in: Double(8)...Double(12)))
            let pulse = SKAction.sequence([pulseOut, pulseIn])
            nebula.run(SKAction.repeatForever(pulse))
            
            nebulaLayer!.addChild(nebula)
        }
        
        addChild(nebulaLayer!)
        
        // Stelle normali sopra le nebulose
        starsLayer1 = createStarsLayer(starCount: 60, alpha: 0.2, zPosition: -30)
        starsLayer2 = createStarsLayer(starCount: 45, alpha: 0.3, zPosition: -20)
        starsLayer3 = createStarsLayer(starCount: 30, alpha: 0.4, zPosition: -10)
        
        if let layer1 = starsLayer1 { addChild(layer1) }
        if let layer2 = starsLayer2 { addChild(layer2) }
        if let layer3 = starsLayer3 { addChild(layer3) }
    }
    
    private func setupVoidSpaceEnvironment() {
        // Gradiente nero → blu scuro - MOLTO PIÙ GRANDE per coprire tutto il playfield
        let gradientTexture = createGradientTexture()
        let background = SKSpriteNode(texture: gradientTexture)
        let fieldWidth = size.width * playFieldMultiplier
        let fieldHeight = size.height * playFieldMultiplier
        background.size = CGSize(width: fieldWidth, height: fieldHeight)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -50
        
        // Aggiungi al worldLayer per seguire il movimento
        worldLayer.addChild(background)
        
        // Stelle più luminose e visibili
        starsLayer1 = createStarsLayer(starCount: 70, alpha: 0.25, zPosition: -30)
        starsLayer2 = createStarsLayer(starCount: 50, alpha: 0.4, zPosition: -20)
        starsLayer3 = createStarsLayer(starCount: 35, alpha: 0.6, zPosition: -10)
        
        if let layer1 = starsLayer1 { addChild(layer1) }
        if let layer2 = starsLayer2 { addChild(layer2) }
        if let layer3 = starsLayer3 { addChild(layer3) }
        
        // Aggiungi alcune linee galattiche lontane - PIÙ GRANDI per coprire il playfield
        let galaxyLayer = SKNode()
        galaxyLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        galaxyLayer.zPosition = -35
        
        // Usa le variabili già dichiarate sopra
        for _ in 0..<8 {  // Più linee per coprire l'area
            let x = CGFloat.random(in: -fieldWidth/2...fieldWidth/2)
            let y = CGFloat.random(in: -fieldHeight/2...fieldHeight/2)
            let width = CGFloat.random(in: CGFloat(200)...CGFloat(400))
            
            let line = SKShapeNode(rectOf: CGSize(width: width, height: 2))
            line.fillColor = UIColor.cyan.withAlphaComponent(0.15)
            line.strokeColor = .clear
            line.position = CGPoint(x: x, y: y)
            line.zRotation = CGFloat.random(in: CGFloat(0)...(.pi * 2))
            line.glowWidth = 2
            
            galaxyLayer.addChild(line)
        }
        
        worldLayer.addChild(galaxyLayer)
    }
    
    private func setupRedGiantEnvironment() {
        // Gradiente rosso-arancio scuro
        let gradientTexture = createRedGiantGradientTexture()
        let background = SKSpriteNode(texture: gradientTexture)
        let fieldWidth = size.width * playFieldMultiplier
        let fieldHeight = size.height * playFieldMultiplier
        background.size = CGSize(width: fieldWidth, height: fieldHeight)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -50
        worldLayer.addChild(background)
        
        // Particelle di plasma fluttuanti
        let plasmaLayer = SKNode()
        plasmaLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        plasmaLayer.zPosition = -35
        
        for _ in 0..<12 {
            let x = CGFloat.random(in: -fieldWidth/2...fieldWidth/2)
            let y = CGFloat.random(in: -fieldHeight/2...fieldHeight/2)
            let size = CGFloat.random(in: CGFloat(60)...CGFloat(140))
            
            let plasma = SKShapeNode(circleOfRadius: size)
            plasma.fillColor = UIColor(red: 0.9, green: CGFloat.random(in: 0.3...0.5), blue: 0.1, alpha: CGFloat.random(in: 0.08...0.15))
            plasma.strokeColor = .clear
            plasma.position = CGPoint(x: x, y: y)
            plasma.glowWidth = size * 0.4
            
            // Movimento lento casuale
            let moveX = CGFloat.random(in: -50...50)
            let moveY = CGFloat.random(in: -50...50)
            let moveDuration = Double.random(in: 15...25)
            let moveAction = SKAction.moveBy(x: moveX, y: moveY, duration: moveDuration)
            let moveBack = SKAction.moveBy(x: -moveX, y: -moveY, duration: moveDuration)
            plasma.run(SKAction.repeatForever(SKAction.sequence([moveAction, moveBack])))
            
            // Pulsazione
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: Double.random(in: 4...6)),
                SKAction.scale(to: 0.8, duration: Double.random(in: 4...6))
            ])
            plasma.run(SKAction.repeatForever(pulse))
            
            plasmaLayer.addChild(plasma)
        }
        worldLayer.addChild(plasmaLayer)
        
        // Stelle dorate/arancioni
        starsLayer1 = createColoredStarsLayer(starCount: 50, color: UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 0.2), zPosition: -30)
        starsLayer2 = createColoredStarsLayer(starCount: 35, color: UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 0.3), zPosition: -20)
        starsLayer3 = createColoredStarsLayer(starCount: 25, color: UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.4), zPosition: -10)
        
        if let layer1 = starsLayer1 { addChild(layer1) }
        if let layer2 = starsLayer2 { addChild(layer2) }
        if let layer3 = starsLayer3 { addChild(layer3) }
    }
    
    private func setupAsteroidBeltEnvironment() {
        // Background grigio-marrone scuro
        backgroundColor = UIColor(red: 0.08, green: 0.06, blue: 0.05, alpha: 1.0)
        
        let fieldWidth = size.width * playFieldMultiplier
        let fieldHeight = size.height * playFieldMultiplier
        
        // Polvere spaziale sottile
        let dustLayer = SKNode()
        dustLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dustLayer.zPosition = -40
        
        for _ in 0..<20 {
            let x = CGFloat.random(in: -fieldWidth/2...fieldWidth/2)
            let y = CGFloat.random(in: -fieldHeight/2...fieldHeight/2)
            let width = CGFloat.random(in: CGFloat(150)...CGFloat(350))
            let height = CGFloat.random(in: CGFloat(80)...CGFloat(150))
            
            let dust = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
            dust.fillColor = UIColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 0.05)
            dust.strokeColor = .clear
            dust.position = CGPoint(x: x, y: y)
            dust.zRotation = CGFloat.random(in: 0...(.pi * 2))
            
            dustLayer.addChild(dust)
        }
        worldLayer.addChild(dustLayer)
        
        // Sagome di asteroidi distanti
        let asteroidSilhouetteLayer = SKNode()
        asteroidSilhouetteLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        asteroidSilhouetteLayer.zPosition = -35
        
        for _ in 0..<15 {
            let x = CGFloat.random(in: -fieldWidth/2...fieldWidth/2)
            let y = CGFloat.random(in: -fieldHeight/2...fieldHeight/2)
            let size = CGFloat.random(in: CGFloat(20)...CGFloat(60))
            
            let sides = Int.random(in: 5...8)
            let asteroid = SKShapeNode(circleOfRadius: size)
            asteroid.path = createIrregularPolygonPath(radius: size, sides: sides)
            asteroid.fillColor = UIColor(white: 0.15, alpha: CGFloat.random(in: 0.1...0.2))
            asteroid.strokeColor = .clear
            asteroid.position = CGPoint(x: x, y: y)
            
            asteroidSilhouetteLayer.addChild(asteroid)
        }
        worldLayer.addChild(asteroidSilhouetteLayer)
        
        // Stelle bianco-grigio opache
        starsLayer1 = createColoredStarsLayer(starCount: 40, color: UIColor(white: 0.6, alpha: 0.15), zPosition: -30)
        starsLayer2 = createColoredStarsLayer(starCount: 30, color: UIColor(white: 0.7, alpha: 0.2), zPosition: -20)
        starsLayer3 = createColoredStarsLayer(starCount: 20, color: UIColor(white: 0.8, alpha: 0.25), zPosition: -10)
        
        if let layer1 = starsLayer1 { addChild(layer1) }
        if let layer2 = starsLayer2 { addChild(layer2) }
        if let layer3 = starsLayer3 { addChild(layer3) }
    }
    
    private func setupBinaryStarsEnvironment() {
        // Background nero
        backgroundColor = .black
        
        let fieldWidth = size.width * playFieldMultiplier
        let fieldHeight = size.height * playFieldMultiplier
        
        // Due sorgenti luminose: blu a sinistra, gialla a destra
        let lightLayer = SKNode()
        lightLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        lightLayer.zPosition = -45
        
        // Stella blu (sinistra)
        let blueGlow = SKShapeNode(circleOfRadius: 400)
        blueGlow.fillColor = UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 0.08)
        blueGlow.strokeColor = .clear
        blueGlow.position = CGPoint(x: -fieldWidth/3, y: 0)
        blueGlow.glowWidth = 200
        lightLayer.addChild(blueGlow)
        
        // Stella gialla (destra)
        let yellowGlow = SKShapeNode(circleOfRadius: 400)
        yellowGlow.fillColor = UIColor(red: 0.9, green: 0.8, blue: 0.3, alpha: 0.08)
        yellowGlow.strokeColor = .clear
        yellowGlow.position = CGPoint(x: fieldWidth/3, y: 0)
        yellowGlow.glowWidth = 200
        lightLayer.addChild(yellowGlow)
        
        worldLayer.addChild(lightLayer)
        
        // Fasci di luce sottili
        let beamLayer = SKNode()
        beamLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        beamLayer.zPosition = -40
        
        for _ in 0..<6 {
            let startX = CGFloat.random(in: -fieldWidth/2...fieldWidth/2)
            let startY = CGFloat.random(in: -fieldHeight/2...fieldHeight/2)
            let length = CGFloat.random(in: CGFloat(300)...CGFloat(600))
            
            let beam = SKShapeNode(rectOf: CGSize(width: length, height: 1))
            beam.fillColor = UIColor(white: 1.0, alpha: 0.03)
            beam.strokeColor = .clear
            beam.position = CGPoint(x: startX, y: startY)
            beam.zRotation = CGFloat.random(in: 0...(.pi * 2))
            beam.glowWidth = 1
            
            beamLayer.addChild(beam)
        }
        worldLayer.addChild(beamLayer)
        
        // Stelle alternate blu/gialle
        starsLayer1 = createBinaryStarsLayer(starCount: 50, zPosition: -30)
        starsLayer2 = createBinaryStarsLayer(starCount: 35, zPosition: -20)
        starsLayer3 = createBinaryStarsLayer(starCount: 25, zPosition: -10)
        
        if let layer1 = starsLayer1 { addChild(layer1) }
        if let layer2 = starsLayer2 { addChild(layer2) }
        if let layer3 = starsLayer3 { addChild(layer3) }
    }
    
    private func setupIonStormEnvironment() {
        // Background nero-viola pulsante
        backgroundColor = UIColor(red: 0.05, green: 0.0, blue: 0.15, alpha: 1.0)
        
        let fieldWidth = size.width * playFieldMultiplier
        let fieldHeight = size.height * playFieldMultiplier
        
        // Particelle luminose verde/ciano scintillanti
        let ionLayer = SKNode()
        ionLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        ionLayer.zPosition = -35
        
        for _ in 0..<80 {
            let x = CGFloat.random(in: -fieldWidth/2...fieldWidth/2)
            let y = CGFloat.random(in: -fieldHeight/2...fieldHeight/2)
            let size = CGFloat.random(in: CGFloat(1.5)...CGFloat(4))
            
            let ion = SKShapeNode(circleOfRadius: size)
            let useGreen = Bool.random()
            ion.fillColor = useGreen ? UIColor(red: 0.2, green: 0.9, blue: 0.6, alpha: 0.6) : UIColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 0.6)
            ion.strokeColor = .clear
            ion.position = CGPoint(x: x, y: y)
            ion.glowWidth = size * 2
            
            // Scintillio rapido
            let fadeOut = SKAction.fadeAlpha(to: 0.1, duration: Double.random(in: 0.3...0.8))
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: Double.random(in: 0.3...0.8))
            let sparkle = SKAction.sequence([fadeOut, fadeIn])
            ion.run(SKAction.repeatForever(sparkle))
            
            ionLayer.addChild(ion)
        }
        worldLayer.addChild(ionLayer)
        
        // Fulmini elettrici occasionali (gestiti in update)
        
        // Stelle normali con glow intenso
        starsLayer1 = createColoredStarsLayer(starCount: 30, color: UIColor(white: 0.9, alpha: 0.3), zPosition: -30)
        starsLayer2 = createColoredStarsLayer(starCount: 20, color: UIColor(white: 0.95, alpha: 0.4), zPosition: -20)
        starsLayer3 = createColoredStarsLayer(starCount: 15, color: UIColor(white: 1.0, alpha: 0.5), zPosition: -10)
        
        if let layer1 = starsLayer1 { addChild(layer1) }
        if let layer2 = starsLayer2 { addChild(layer2) }
        if let layer3 = starsLayer3 { addChild(layer3) }
    }
    
    // MARK: - NEW ENVIRONMENTS
    
    private func setupPulsarFieldEnvironment() {
        // Background nero con lieve sfumatura blu
        backgroundColor = UIColor(red: 0.0, green: 0.02, blue: 0.08, alpha: 1.0)
        
        let fieldWidth = size.width * playFieldMultiplier
        let fieldHeight = size.height * playFieldMultiplier
        
        // Pulsar centrale (fuori schermo, solo effetti visibili)
        let pulsarLayer = SKNode()
        pulsarLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        pulsarLayer.zPosition = -35
        
        // Onde radio pulsanti - 4 anelli concentrici
        for i in 0..<4 {
            let radius = CGFloat(100 + i * 80)
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.strokeColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.3)
            ring.fillColor = .clear
            ring.lineWidth = 2
            ring.glowWidth = 8
            
            // Pulsazione con delay diverso per ogni anello
            let delay = SKAction.wait(forDuration: Double(i) * 0.3)
            let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 1.0)
            let fadeIn = SKAction.fadeAlpha(to: 0.6, duration: 0.2)
            let scaleUp = SKAction.scale(to: 1.3, duration: 1.0)
            let scaleReset = SKAction.scale(to: 1.0, duration: 0.0)
            let pulse = SKAction.sequence([fadeIn, SKAction.group([fadeOut, scaleUp]), scaleReset, delay])
            ring.run(SKAction.repeatForever(pulse))
            
            pulsarLayer.addChild(ring)
        }
        worldLayer.addChild(pulsarLayer)
        
        // Particelle energetiche che orbitano velocemente
        for _ in 0..<40 {
            let distance = CGFloat.random(in: 150...400)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let x = cos(angle) * distance
            let y = sin(angle) * distance
            
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3))
            particle.fillColor = UIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.8)
            particle.strokeColor = .clear
            particle.position = CGPoint(x: x, y: y)
            particle.glowWidth = 6
            
            // Orbita veloce
            let orbit = SKAction.rotate(byAngle: .pi * 2, duration: Double.random(in: 3...6))
            particle.run(SKAction.repeatForever(orbit))
            
            pulsarLayer.addChild(particle)
        }
        
        // Lampi periodici (gestiti nell'update se necessario)
        
        // Stelle di background
        starsLayer1 = createDeepSpaceStars(starCount: 50, zPosition: -30, sizeRange: 0.8...1.5, alphaRange: 0.2...0.4)
        starsLayer2 = createDeepSpaceStars(starCount: 30, zPosition: -20, sizeRange: 1.5...2.5, alphaRange: 0.3...0.5)
        
        if let layer1 = starsLayer1 { addChild(layer1) }
        if let layer2 = starsLayer2 { addChild(layer2) }
    }
    
    private func setupPlanetarySystemEnvironment() {
        // Background nero profondo
        backgroundColor = .black
        
        let planetaryLayer = SKNode()
        planetaryLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        planetaryLayer.zPosition = -35
        
        // Definizione pianeti: (raggio orbita, dimensione pianeta, colore, velocità orbitale, ha anelli)
        let planets: [(orbit: CGFloat, size: CGFloat, color: UIColor, speed: Double, hasRing: Bool)] = [
            (150, 12, UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0), 15.0, false),  // Pianeta rosso-arancio piccolo
            (250, 25, UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0), 25.0, false),  // Pianeta blu medio
            (380, 35, UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0), 40.0, true),   // Gigante gassoso con anelli
            (520, 18, UIColor(red: 0.5, green: 0.8, blue: 0.6, alpha: 1.0), 55.0, false)   // Pianeta verde lontano
        ]
        
        for (index, planet) in planets.enumerated() {
            // Orbita (linea tratteggiata sottile)
            let orbitPath = CGPath(ellipseIn: CGRect(x: -planet.orbit, y: -planet.orbit, width: planet.orbit * 2, height: planet.orbit * 2), transform: nil)
            let orbitLine = SKShapeNode(path: orbitPath)
            orbitLine.strokeColor = UIColor.white.withAlphaComponent(0.1)
            orbitLine.lineWidth = 1
            orbitLine.lineCap = .round
            
            // Pattern tratteggiato
            let pattern: [CGFloat] = [5, 10]
            orbitLine.path = orbitPath
            // Note: SKShapeNode non supporta nativamente dash pattern, ma l'effetto è accettabile
            
            planetaryLayer.addChild(orbitLine)
            
            // Contenitore per il pianeta (per rotazione orbitale)
            let planetContainer = SKNode()
            
            // Angolo iniziale random per ogni pianeta
            let startAngle = CGFloat.random(in: 0...(2 * .pi))
            planetContainer.zRotation = startAngle
            
            // Pianeta
            let planetNode = SKShapeNode(circleOfRadius: planet.size)
            planetNode.fillColor = planet.color
            planetNode.strokeColor = planet.color.withAlphaComponent(0.5)
            planetNode.lineWidth = 1
            planetNode.position = CGPoint(x: planet.orbit, y: 0)  // Posizionato alla distanza orbitale
            planetNode.glowWidth = planet.size * 0.3
            
            // Anelli (se previsto)
            if planet.hasRing {
                let ringOuter = planet.size * 1.8
                let ringInner = planet.size * 1.3
                let ringPath = CGMutablePath()
                ringPath.addEllipse(in: CGRect(x: -ringOuter, y: -ringOuter/3, width: ringOuter * 2, height: ringOuter * 2/3))
                ringPath.addEllipse(in: CGRect(x: -ringInner, y: -ringInner/3, width: ringInner * 2, height: ringInner * 2/3))
                
                let ring = SKShapeNode(path: ringPath)
                ring.fillColor = UIColor(red: 0.7, green: 0.6, blue: 0.5, alpha: 0.3)
                ring.strokeColor = UIColor(red: 0.7, green: 0.6, blue: 0.5, alpha: 0.5)
                ring.lineWidth = 0.5
                
                planetNode.addChild(ring)
            }
            
            planetContainer.addChild(planetNode)
            planetaryLayer.addChild(planetContainer)
            
            // Rotazione orbitale (più lento = più lontano)
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: planet.speed)
            planetContainer.run(SKAction.repeatForever(rotate))
        }
        
        worldLayer.addChild(planetaryLayer)
        
        // Polvere cosmica (particelle che attraversano)
        for _ in 0..<20 {
            let dust = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.5))
            dust.fillColor = UIColor.white.withAlphaComponent(CGFloat.random(in: 0.1...0.3))
            dust.strokeColor = .clear
            
            let x = CGFloat.random(in: -size.width...size.width)
            let y = CGFloat.random(in: -size.height...size.height)
            dust.position = CGPoint(x: x, y: y)
            dust.zPosition = -25
            
            planetaryLayer.addChild(dust)
        }
        
        // Stelle di background
        starsLayer1 = createDeepSpaceStars(starCount: 80, zPosition: -30, sizeRange: 0.8...1.5, alphaRange: 0.2...0.4)
        starsLayer2 = createDeepSpaceStars(starCount: 50, zPosition: -20, sizeRange: 1.5...2.5, alphaRange: 0.3...0.5)
        
        if let layer1 = starsLayer1 { addChild(layer1) }
        if let layer2 = starsLayer2 { addChild(layer2) }
    }
    
    private func setupCometTrailEnvironment() {
        // Background nero profondo
        backgroundColor = .black
        
        let cometLayer = SKNode()
        cometLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        cometLayer.zPosition = -35
        
        // 2-3 comete con traiettorie diverse
        let comets: [(startX: CGFloat, startY: CGFloat, endX: CGFloat, endY: CGFloat, duration: Double, color: UIColor)] = [
            (-300, 400, 800, -300, 25.0, UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1.0)),     // Bianco-azzurro
            (600, -200, -400, 500, 30.0, UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0)),     // Arancio-bianco
            (-200, -300, 700, 600, 28.0, UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0))     // Bianco puro
        ]
        
        for comet in comets {
            // Nucleo della cometa
            let cometHead = SKShapeNode(circleOfRadius: 8)
            cometHead.fillColor = comet.color
            cometHead.strokeColor = .white
            cometHead.lineWidth = 1
            cometHead.glowWidth = 15
            cometHead.position = CGPoint(x: comet.startX, y: comet.startY)
            
            cometLayer.addChild(cometHead)
            
            // Scia di particelle (emitter simulato con nodi)
            let trailContainer = SKNode()
            trailContainer.position = cometHead.position
            cometLayer.addChild(trailContainer)
            
            // Movimento della cometa
            let move = SKAction.move(to: CGPoint(x: comet.endX, y: comet.endY), duration: comet.duration)
            let resetPosition = SKAction.move(to: CGPoint(x: comet.startX, y: comet.startY), duration: 0)
            let sequence = SKAction.sequence([move, resetPosition])
            
            cometHead.run(SKAction.repeatForever(sequence))
            trailContainer.run(SKAction.repeatForever(sequence))
            
            // Crea particelle di scia (spawna periodicamente)
            // Simulazione semplice: aggiungi particelle che fadeOut
            let spawnTrail = SKAction.run {
                let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
                particle.fillColor = comet.color.withAlphaComponent(0.6)
                particle.strokeColor = .clear
                particle.position = cometHead.position
                particle.zPosition = -1
                
                cometLayer.addChild(particle)
                
                // Fade out e scala
                let fadeOut = SKAction.fadeOut(withDuration: 2.0)
                let scaleDown = SKAction.scale(to: 0.1, duration: 2.0)
                let remove = SKAction.removeFromParent()
                particle.run(SKAction.sequence([SKAction.group([fadeOut, scaleDown]), remove]))
            }
            
            let spawnDelay = SKAction.wait(forDuration: 0.1)
            let spawnSequence = SKAction.sequence([spawnTrail, spawnDelay])
            cometHead.run(SKAction.repeatForever(spawnSequence), withKey: "trailSpawn")
        }
        
        worldLayer.addChild(cometLayer)
        
        // Polvere stellare luminosa
        for _ in 0..<40 {
            let dust = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2.5))
            dust.fillColor = UIColor(white: 0.9, alpha: CGFloat.random(in: 0.2...0.4))
            dust.strokeColor = .clear
            
            let x = CGFloat.random(in: -size.width/2...size.width/2)
            let y = CGFloat.random(in: -size.height/2...size.height/2)
            dust.position = CGPoint(x: x, y: y)
            dust.zPosition = -28
            
            cometLayer.addChild(dust)
        }
        
        // Stelle di background
        starsLayer1 = createDeepSpaceStars(starCount: 100, zPosition: -30, sizeRange: 0.8...1.5, alphaRange: 0.2...0.4)
        starsLayer2 = createDeepSpaceStars(starCount: 60, zPosition: -20, sizeRange: 1.5...2.5, alphaRange: 0.3...0.5)
        
        if let layer1 = starsLayer1 { addChild(layer1) }
        if let layer2 = starsLayer2 { addChild(layer2) }
    }
    
    private func setupDarkMatterCloudEnvironment() {
        // Background nero profondo con sfumatura viola
        backgroundColor = UIColor(red: 0.02, green: 0.0, blue: 0.05, alpha: 1.0)
        
        let darkMatterLayer = SKNode()
        darkMatterLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        darkMatterLayer.zPosition = -35
        
        // Nuvole di materia oscura (forme amorfe semi-trasparenti)
        for i in 0..<5 {
            let cloudSize = CGFloat.random(in: 150...300)
            let cloud = SKShapeNode(circleOfRadius: cloudSize)
            cloud.fillColor = UIColor(red: 0.15, green: 0.05, blue: 0.25, alpha: 0.15)
            cloud.strokeColor = UIColor(red: 0.3, green: 0.1, blue: 0.4, alpha: 0.2)
            cloud.lineWidth = 2
            cloud.glowWidth = 40
            
            let x = CGFloat.random(in: -size.width/2...size.width/2)
            let y = CGFloat.random(in: -size.height/2...size.height/2)
            cloud.position = CGPoint(x: x, y: y)
            cloud.zPosition = CGFloat(-38 + i)
            
            // Movimento lento oscillatorio
            let moveX = CGFloat.random(in: -50...50)
            let moveY = CGFloat.random(in: -50...50)
            let duration = Double.random(in: 15...25)
            
            let move = SKAction.moveBy(x: moveX, y: moveY, duration: duration)
            let moveBack = move.reversed()
            let sequence = SKAction.sequence([move, moveBack])
            cloud.run(SKAction.repeatForever(sequence))
            
            // Pulsazione alpha
            let fadeOut = SKAction.fadeAlpha(to: 0.05, duration: Double.random(in: 3...6))
            let fadeIn = SKAction.fadeAlpha(to: 0.15, duration: Double.random(in: 3...6))
            let pulse = SKAction.sequence([fadeOut, fadeIn])
            cloud.run(SKAction.repeatForever(pulse))
            
            darkMatterLayer.addChild(cloud)
        }
        
        worldLayer.addChild(darkMatterLayer)
        
        // Particelle che si attraggono/respingono (effetto gravitazionale simulato)
        for _ in 0..<60 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3))
            particle.fillColor = UIColor(red: 0.7, green: 0.6, blue: 0.9, alpha: 0.5)
            particle.strokeColor = .clear
            particle.glowWidth = 4
            
            let x = CGFloat.random(in: -size.width/2...size.width/2)
            let y = CGFloat.random(in: -size.height/2...size.height/2)
            particle.position = CGPoint(x: x, y: y)
            particle.zPosition = -32
            
            // Movimento browniano (casuale)
            let moveX = CGFloat.random(in: -80...80)
            let moveY = CGFloat.random(in: -80...80)
            let duration = Double.random(in: 8...15)
            
            let move = SKAction.moveBy(x: moveX, y: moveY, duration: duration)
            let moveBack = move.reversed()
            let sequence = SKAction.sequence([move, moveBack])
            particle.run(SKAction.repeatForever(sequence))
            
            darkMatterLayer.addChild(particle)
        }
        
        // Stelle di background (poche, perché la materia oscura oscura)
        starsLayer1 = createDeepSpaceStars(starCount: 40, zPosition: -30, sizeRange: 0.8...1.5, alphaRange: 0.1...0.3)
        starsLayer2 = createDeepSpaceStars(starCount: 25, zPosition: -20, sizeRange: 1.5...2.5, alphaRange: 0.2...0.4)
        
        if let layer1 = starsLayer1 { addChild(layer1) }
        if let layer2 = starsLayer2 { addChild(layer2) }
    }
    
    private func setupSupernovaRemnantEnvironment() {
        // Background nero con lieve sfumatura rossa
        backgroundColor = UIColor(red: 0.05, green: 0.0, blue: 0.0, alpha: 1.0)
        
        let supernovaLayer = SKNode()
        supernovaLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        supernovaLayer.zPosition = -35
        
        // Nucleo stellare centrale luminoso
        let core = SKShapeNode(circleOfRadius: 15)
        core.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.8, alpha: 1.0)
        core.strokeColor = UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 0.8)
        core.lineWidth = 3
        core.glowWidth = 30
        
        // Pulsazione del nucleo
        let scaleUp = SKAction.scale(to: 1.2, duration: 1.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 1.5)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        core.run(SKAction.repeatForever(pulse))
        
        supernovaLayer.addChild(core)
        
        // Anelli concentrici in espansione (gas)
        let ringColors: [UIColor] = [
            UIColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 0.4),   // Rosso
            UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.3),   // Arancio
            UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 0.25),  // Giallo
            UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.2)    // Blu elettrico
        ]
        
        for (index, color) in ringColors.enumerated() {
            let ring = SKShapeNode(circleOfRadius: CGFloat(80 + index * 60))
            ring.strokeColor = color
            ring.fillColor = .clear
            ring.lineWidth = CGFloat(8) - CGFloat(index) * 1.5
            ring.glowWidth = 15
            ring.alpha = 0
            
            supernovaLayer.addChild(ring)
            
            // Espansione continua
            let delay = SKAction.wait(forDuration: TimeInterval(index) * 0.8)
            let fadeIn = SKAction.fadeAlpha(to: CGFloat(color.cgColor.alpha), duration: 0.5)
            let expand = SKAction.scale(to: 2.5, duration: 8.0)
            let fadeOut = SKAction.fadeOut(withDuration: 2.0)
            let reset = SKAction.group([
                SKAction.scale(to: 1.0, duration: 0),
                SKAction.fadeAlpha(to: 0, duration: 0)
            ])
            
            let sequence = SKAction.sequence([delay, fadeIn, SKAction.group([expand, fadeOut]), reset])
            ring.run(SKAction.repeatForever(sequence))
        }
        
        // Particelle espulse (schizzi dal centro)
        for _ in 0..<80 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            
            let colorChoice = Int.random(in: 0...3)
            switch colorChoice {
            case 0: particle.fillColor = UIColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 0.8)
            case 1: particle.fillColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.8)
            case 2: particle.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 0.8)
            default: particle.fillColor = UIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.8)
            }
            
            particle.strokeColor = .clear
            particle.position = .zero  // Parte dal centro
            particle.glowWidth = 6
            
            // Direzione random
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 200...500)
            let endX = cos(angle) * distance
            let endY = sin(angle) * distance
            let duration = Double.random(in: 4...8)
            
            let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: duration)
            let fadeOut = SKAction.fadeOut(withDuration: duration * 0.7)
            let reset = SKAction.group([
                SKAction.move(to: .zero, duration: 0),
                SKAction.fadeIn(withDuration: 0)
            ])
            let delay = SKAction.wait(forDuration: Double.random(in: 0...3))
            
            let sequence = SKAction.sequence([delay, SKAction.group([move, fadeOut]), reset])
            particle.run(SKAction.repeatForever(sequence))
            
            supernovaLayer.addChild(particle)
        }
        
        worldLayer.addChild(supernovaLayer)
        
        // Stelle di background
        starsLayer1 = createDeepSpaceStars(starCount: 60, zPosition: -30, sizeRange: 0.8...1.5, alphaRange: 0.2...0.4)
        starsLayer2 = createDeepSpaceStars(starCount: 40, zPosition: -20, sizeRange: 1.5...2.5, alphaRange: 0.3...0.5)
        
        if let layer1 = starsLayer1 { addChild(layer1) }
        if let layer2 = starsLayer2 { addChild(layer2) }
    }
    
    private func createRedGiantGradientTexture() -> SKTexture {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let colors = [UIColor(red: 0.15, green: 0.05, blue: 0.0, alpha: 1.0).cgColor, UIColor(red: 0.25, green: 0.08, blue: 0.05, alpha: 1.0).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        }
        return SKTexture(image: image)
    }
    
    private func createIrregularPolygonPath(radius: CGFloat, sides: Int) -> CGPath {
        let path = CGMutablePath()
        let angleStep = (2.0 * .pi) / CGFloat(sides)
        
        for i in 0..<sides {
            let angle = angleStep * CGFloat(i)
            let randomRadius = radius * CGFloat.random(in: 0.7...1.3)
            let x = randomRadius * cos(angle)
            let y = randomRadius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
    
    private func createColoredStarsLayer(starCount: Int, color: UIColor, zPosition: CGFloat) -> SKNode {
        let layer = SKNode()
        layer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        layer.zPosition = zPosition
        
        let areaWidth = size.width * playFieldMultiplier
        let areaHeight = size.height * playFieldMultiplier
        
        for _ in 0..<starCount {
            let x = CGFloat.random(in: -areaWidth/2...areaWidth/2)
            let y = CGFloat.random(in: -areaHeight/2...areaHeight/2)
            let starSize = CGFloat.random(in: CGFloat(1)...CGFloat(3))
            
            let star = SKShapeNode(circleOfRadius: starSize)
            star.fillColor = color
            star.strokeColor = .clear
            star.position = CGPoint(x: x, y: y)
            star.glowWidth = starSize * 0.8
            
            // Twinkle occasionale
            if Bool.random() {
                let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: Double.random(in: 1...2))
                let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: Double.random(in: 1...2))
                let twinkle = SKAction.sequence([fadeOut, fadeIn])
                star.run(SKAction.repeatForever(twinkle))
            }
            
            layer.addChild(star)
        }
        
        return layer
    }
    
    private func createBinaryStarsLayer(starCount: Int, zPosition: CGFloat) -> SKNode {
        let layer = SKNode()
        layer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        layer.zPosition = zPosition
        
        let areaWidth = size.width * playFieldMultiplier
        let areaHeight = size.height * playFieldMultiplier
        
        for _ in 0..<starCount {
            let x = CGFloat.random(in: -areaWidth/2...areaWidth/2)
            let y = CGFloat.random(in: -areaHeight/2...areaHeight/2)
            let starSize = CGFloat.random(in: CGFloat(1)...CGFloat(3))
            
            let star = SKShapeNode(circleOfRadius: starSize)
            
            // Alterna colori blu/giallo
            let useBlue = Bool.random()
            if useBlue {
                star.fillColor = UIColor(red: 0.6, green: 0.7, blue: 1.0, alpha: CGFloat.random(in: 0.3...0.6))
            } else {
                star.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: CGFloat.random(in: 0.3...0.6))
            }
            
            star.strokeColor = .clear
            star.position = CGPoint(x: x, y: y)
            star.glowWidth = starSize * 0.8
            
            layer.addChild(star)
        }
        
        return layer
    }
    
    private func createGradientTexture() -> SKTexture {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let colors = [UIColor.black.cgColor, UIColor(red: 0.0, green: 0.05, blue: 0.15, alpha: 1.0).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        }
        return SKTexture(image: image)
    }
    
    private func createDeepSpaceStars(starCount: Int, zPosition: CGFloat, sizeRange: ClosedRange<CGFloat>, alphaRange: ClosedRange<CGFloat>) -> SKNode {
        let layer = SKNode()
        layer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        layer.zPosition = zPosition
        
        let areaWidth = size.width * playFieldMultiplier
        let areaHeight = size.height * playFieldMultiplier
        
        for _ in 0..<starCount {
            let x = CGFloat.random(in: -areaWidth/2...areaWidth/2)
            let y = CGFloat.random(in: -areaHeight/2...areaHeight/2)
            
            let starSize = CGFloat.random(in: sizeRange)
            let star = SKShapeNode(circleOfRadius: starSize)
            
            // Colori variati: principalmente bianche, alcune colorate
            let colorChoice = Int.random(in: 0...10)
            let baseAlpha = CGFloat.random(in: alphaRange)
            
            if colorChoice < 8 {
                star.fillColor = UIColor.white.withAlphaComponent(baseAlpha)
            } else if colorChoice == 8 {
                star.fillColor = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: baseAlpha)  // Blu
            } else if colorChoice == 9 {
                star.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: baseAlpha)  // Giallo
            } else {
                star.fillColor = UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: baseAlpha)  // Rosso
            }
            
            star.strokeColor = .clear
            star.position = CGPoint(x: x, y: y)
            star.glowWidth = starSize * 0.5
            
            // Animazione twinkle random per alcune stelle
            if Bool.random() && starSize > 1.5 {
                let fadeOut = SKAction.fadeAlpha(to: baseAlpha * 0.3, duration: Double.random(in: 1.5...3.0))
                let fadeIn = SKAction.fadeAlpha(to: baseAlpha, duration: Double.random(in: 1.5...3.0))
                let twinkle = SKAction.sequence([fadeOut, fadeIn])
                star.run(SKAction.repeatForever(twinkle))
            }
            
            layer.addChild(star)
        }
        
        return layer
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
            let starSize = CGFloat.random(in: CGFloat(1.0)...CGFloat(2.5))
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
        planetOriginalColor = .white  // Memorizza il colore originale
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
        
        // DISTRIBUZIONE PROGRESSIVA: ring sbloccati per wave
        // Wave 1: nessun anello
        // Wave 2: solo ring 1 (interno)
        // Wave 3: ring 1 + 2
        // Wave 4+: tutti e 3
        
        // ===== ANELLO 1 (interno) - Magenta/Rosa =====
        // Appare da wave 2
        if currentWave >= 2 {
            let isEllipse = currentWave >= 7  // Diventa ellisse dalla wave 7
            createGravityWellRing(
                radius: orbitalRing1Radius,
                ringNode: &orbitalRing1,
                color: UIColor(red: 1.0, green: 0.3, blue: 0.7, alpha: 1.0),  // Magenta
                velocity: orbitalBaseAngularVelocity,
                centerPosition: centerPosition,
                name: "orbitalRing1",
                isEllipse: isEllipse,
                ellipseRatio: 1.5
            )
            orbitalRing1IsEllipse = isEllipse
        }
        
        // ===== ANELLO 2 (medio) - Cyan brillante =====
        // Appare da wave 3
        if currentWave >= 3 {
            let isEllipse = currentWave >= 6  // Diventa ellisse dalla wave 6
            createGravityWellRing(
                radius: orbitalRing2Radius,
                ringNode: &orbitalRing2,
                color: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0),  // Cyan
                velocity: orbitalBaseAngularVelocity * 1.33,
                centerPosition: centerPosition,
                name: "orbitalRing2",
                isEllipse: isEllipse,
                ellipseRatio: 1.5
            )
            orbitalRing2IsEllipse = isEllipse
        }
        
        // ===== ANELLO 3 (esterno) - Viola/Lavanda =====
        // Appare da wave 4
        if currentWave >= 4 {
            let isEllipse = currentWave >= 5  // Diventa ellisse dalla wave 5
            createGravityWellRing(
                radius: orbitalRing3Radius,
                ringNode: &orbitalRing3,
                color: UIColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0),  // Viola
                velocity: orbitalBaseAngularVelocity * 1.77,
                centerPosition: centerPosition,
                name: "orbitalRing3",
                isEllipse: isEllipse,
                ellipseRatio: 1.5  // Ellisse orizzontale
            )
            orbitalRing3IsEllipse = isEllipse
        }
        
        let numRings = currentWave >= 4 ? 3 : (currentWave >= 3 ? 2 : (currentWave >= 2 ? 1 : 0))
        debugLog("✅ Gravity Well rings created: \(numRings) active (wave \(currentWave)), ellipses: R1=\(orbitalRing1IsEllipse), R2=\(orbitalRing2IsEllipse), R3=\(orbitalRing3IsEllipse)")
    }
    
    // Aggiorna gli anelli orbitali quando si passa a una nuova wave
    private func updateOrbitalRingsForWave() {
        let centerPosition = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Aggiungi l'anello 1 se siamo alla wave 2+ e non esiste ancora
        if currentWave >= 2 && orbitalRing1 == nil {
            let isEllipse = currentWave >= 7  // Diventa ellisse dalla wave 7
            createGravityWellRing(
                radius: orbitalRing1Radius,
                ringNode: &orbitalRing1,
                color: UIColor(red: 1.0, green: 0.3, blue: 0.7, alpha: 1.0),  // Magenta
                velocity: orbitalBaseAngularVelocity,
                centerPosition: centerPosition,
                name: "orbitalRing1",
                isEllipse: isEllipse,
                ellipseRatio: 1.5
            )
            
            // Imposta lo stato ellisse
            orbitalRing1IsEllipse = isEllipse
            
            if let ring1Container = worldLayer.childNode(withName: "orbitalRing1") {
                activateRingAnimations(for: ring1Container)
            }
            
            debugLog("✨ Orbital ring 1 added and activated for wave \(currentWave), isEllipse: \(isEllipse)")
        }
        
        // Aggiungi l'anello 2 se siamo alla wave 3+ e non esiste ancora
        if currentWave >= 3 && orbitalRing2 == nil {
            let isEllipse = currentWave >= 6  // Diventa ellisse dalla wave 6
            createGravityWellRing(
                radius: orbitalRing2Radius,
                ringNode: &orbitalRing2,
                color: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0),  // Cyan
                velocity: orbitalBaseAngularVelocity * 1.33,
                centerPosition: centerPosition,
                name: "orbitalRing2",
                isEllipse: isEllipse,
                ellipseRatio: 1.5
            )
            
            // Imposta lo stato ellisse
            orbitalRing2IsEllipse = isEllipse
            
            if let ring2Container = worldLayer.childNode(withName: "orbitalRing2") {
                activateRingAnimations(for: ring2Container)
            }
            
            debugLog("✨ Orbital ring 2 added and activated for wave \(currentWave), isEllipse: \(isEllipse)")
        }
        
        // Aggiungi l'anello 3 se siamo alla wave 4+ e non esiste ancora
        if currentWave >= 4 && orbitalRing3 == nil {
            let isEllipse = currentWave >= 5  // Diventa ellisse dalla wave 5
            createGravityWellRing(
                radius: orbitalRing3Radius,
                ringNode: &orbitalRing3,
                color: UIColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0),  // Viola
                velocity: orbitalBaseAngularVelocity * 1.77,
                centerPosition: centerPosition,
                name: "orbitalRing3",
                isEllipse: isEllipse,
                ellipseRatio: 1.5
            )
            
            // Imposta lo stato ellisse
            orbitalRing3IsEllipse = isEllipse
            
            if let ring3Container = worldLayer.childNode(withName: "orbitalRing3") {
                activateRingAnimations(for: ring3Container)
            }
            
            debugLog("✨ Orbital ring 3 added and activated for wave \(currentWave), isEllipse: \(isEllipse)")
        }
        
        // Trasforma gli anelli in ellissi quando necessario
        if currentWave == 5 && orbitalRing3 != nil && !orbitalRing3IsEllipse {
            transformRingToEllipse(ringName: "orbitalRing3", radius: orbitalRing3Radius, color: UIColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0))
            orbitalRing3IsEllipse = true
        }
        if currentWave == 6 && orbitalRing2 != nil && !orbitalRing2IsEllipse {
            transformRingToEllipse(ringName: "orbitalRing2", radius: orbitalRing2Radius, color: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0))
            orbitalRing2IsEllipse = true
        }
        if currentWave == 7 && orbitalRing1 != nil && !orbitalRing1IsEllipse {
            transformRingToEllipse(ringName: "orbitalRing1", radius: orbitalRing1Radius, color: UIColor(red: 1.0, green: 0.3, blue: 0.7, alpha: 1.0))
            orbitalRing1IsEllipse = true
        }
    }
    
    // Trasforma un anello circolare in ellisse
    private func transformRingToEllipse(ringName: String, radius: CGFloat, color: UIColor) {
        guard let ringContainer = worldLayer.childNode(withName: ringName) else { return }
        guard let mainRing = ringContainer.childNode(withName: "mainRing") as? SKShapeNode else { return }
        
        // FERMA la rotazione del container (le ellissi non devono ruotare)
        ringContainer.removeAction(forKey: "ringRotation")
        ringContainer.zRotation = 0  // Reset della rotazione
        
        // Crea path ellittico
        let ellipsePath = CGMutablePath()
        ellipsePath.addEllipse(in: CGRect(x: -radius * 1.5, y: -radius, width: radius * 3.0, height: radius * 2.0))
        
        mainRing.path = ellipsePath
        
        // Anima le particelle lungo il percorso ellittico
        let velocity: CGFloat
        switch ringName {
        case "orbitalRing1": velocity = orbitalBaseAngularVelocity
        case "orbitalRing2": velocity = orbitalBaseAngularVelocity * 1.33
        case "orbitalRing3": velocity = orbitalBaseAngularVelocity * 1.77
        default: velocity = orbitalBaseAngularVelocity
        }
        
        animateEllipseParticles(container: ringContainer, radius: radius, ellipseRatio: ellipseRatio, velocity: velocity, numParticles: 4)
        
        debugLog("🔄 Ring \(ringName) transformed to ellipse - rotation stopped, particles animated")
    }
    
    // Attiva tutte le animazioni di un anello orbitale
    private func activateRingAnimations(for ringContainer: SKNode) {
        ringContainer.isPaused = false
        ringContainer.enumerateChildNodes(withName: "//*") { node, _ in
            node.isPaused = false
        }
    }
    
    // Calcola punto più vicino su ellisse e relativa distanza
    // Ritorna: (distanza, angolo parametrico del punto più vicino)
    private func closestPointOnEllipse(point: CGPoint, center: CGPoint, baseRadius: CGFloat, isEllipse: Bool) -> (distance: CGFloat, angle: CGFloat) {
        guard isEllipse else {
            // Per cerchi: calcolo semplice
            let dx = point.x - center.x
            let dy = point.y - center.y
            let angle = atan2(dy, dx)
            let distanceFromCenter = sqrt(dx * dx + dy * dy)
            return (abs(distanceFromCenter - baseRadius), angle)
        }
        
        // Per ellisse: algoritmo iterativo Newton-Raphson semplificato
        // Basato su "Distance from a Point to an Ellipse" - migliore dei 36 campioni
        let a = baseRadius * ellipseRatio  // semiasse maggiore (orizzontale)
        let b = baseRadius                  // semiasse minore (verticale)
        
        let px = point.x - center.x
        let py = point.y - center.y
        
        // Guess iniziale: angolo polare
        var theta = atan2(py, px)
        
        // Iterazioni Newton-Raphson (5 iterazioni sufficienti)
        for _ in 0..<5 {
            let cosT = cos(theta)
            let sinT = sin(theta)
            
            // Punto sull'ellisse
            let ex = a * cosT
            let ey = b * sinT
            
            // Vettore dal punto all'ellisse
            let dx = ex - px
            let dy = ey - py
            
            // Derivata della funzione distanza
            let fx = -a * sinT * dx + b * cosT * dy
            
            // Derivata seconda (per Newton-Raphson)
            let dfx = -a * cosT * dx - a * sinT * (-a * sinT) - b * sinT * dy + b * cosT * (b * cosT)
            
            if abs(dfx) > 0.0001 {
                theta = theta - fx / dfx
            }
        }
        
        // Calcola punto finale e distanza
        let finalX = center.x + a * cos(theta)
        let finalY = center.y + b * sin(theta)
        let dx = point.x - finalX
        let dy = point.y - finalY
        let distance = sqrt(dx * dx + dy * dy)
        
        return (distance, theta)
    }
    
    // Wrapper per compatibilità
    private func distanceFromEllipse(point: CGPoint, center: CGPoint, baseRadius: CGFloat, isEllipse: Bool) -> CGFloat {
        return closestPointOnEllipse(point: point, center: center, baseRadius: baseRadius, isEllipse: isEllipse).distance
    }
    
    // Calcola il moltiplicatore di velocità in base alla distanza dal centro del pianeta
    // Segue le leggi di Keplero: velocità inversamente proporzionale alla distanza
    // Ritorna 4.0 al perielio (più vicino) e 1.0 all'afelio (più lontano)
    private func getEllipseSpeedMultiplier(angle: CGFloat, baseRadius: CGFloat, isEllipse: Bool) -> CGFloat {
        guard isEllipse else { return 1.0 }
        
        // Per un'ellisse orizzontale con ratio 1.5:
        // - semiasse maggiore (orizzontale) = radius * 1.5
        // - semiasse minore (verticale) = radius
        let a = baseRadius * ellipseRatio  // semiasse maggiore
        let b = baseRadius                  // semiasse minore
        
        // Calcola la distanza effettiva dal centro a questo punto dell'ellisse
        // Usa coordinate parametriche dell'ellisse
        let x = a * cos(angle)
        let y = b * sin(angle)
        let distanceFromCenter = sqrt(x * x + y * y)
        
        // Distanza minima (perielio): quando θ = ±90° (lati corti dell'ellisse) = b
        // Distanza massima (afelio): quando θ = 0° o 180° (lati lunghi dell'ellisse) = a
        let minDistance = b  // più vicino al pianeta
        let maxDistance = a  // più lontano dal pianeta
        
        // Normalizza la distanza: 0 = più vicino, 1 = più lontano
        let normalizedDistance = (distanceFromCenter - minDistance) / (maxDistance - minDistance)
        
        // Velocità inversamente proporzionale alla distanza (leggi di Keplero)
        // Più vicino = più veloce: 2.5x al perielio, 1.0x all'afelio (bilanciato per stabilità)
        let speedMultiplier = 2.5 - (normalizedDistance * 1.5)
        
        // Debug ogni tanto
        let angleDeg = Int(angle * 180 / .pi)
        if angleDeg % 45 == 0 {
            debugLog("📊 SpeedMult: θ=\(angleDeg)°, dist=\(Int(distanceFromCenter)), norm=\(String(format: "%.2f", normalizedDistance)), mult=\(String(format: "%.2f", speedMultiplier))")
        }
        
        return speedMultiplier
    }
    
    private func createGravityWellRing(radius: CGFloat, ringNode: inout SKShapeNode?, color: UIColor, velocity: CGFloat, centerPosition: CGPoint, name: String, isEllipse: Bool, ellipseRatio: CGFloat) {
        // Container per tutti gli elementi del ring
        let ringContainer = SKNode()
        ringContainer.position = centerPosition
        ringContainer.zPosition = 1
        ringContainer.name = name
        
        // 1️⃣ ANELLO PRINCIPALE (sottile e semi-trasparente) - Circolare o Ellittico
        let mainPath = CGMutablePath()
        if isEllipse {
            // Ellisse orizzontale
            mainPath.addEllipse(in: CGRect(x: -radius * ellipseRatio, y: -radius, width: radius * ellipseRatio * 2.0, height: radius * 2.0))
        } else {
            // Cerchio normale
            mainPath.addArc(center: .zero, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        }
        
        let mainRingShape = SKShapeNode(path: mainPath)
        mainRingShape.strokeColor = color.withAlphaComponent(0.15)  // Molto più trasparente
        mainRingShape.lineWidth = 1.5  // Più sottile
        mainRingShape.fillColor = .clear
        mainRingShape.glowWidth = 1.0  // Glow ridotto
        mainRingShape.name = "mainRing"
        ringContainer.addChild(mainRingShape)
        
        // 2️⃣ ONDE CONCENTRICHE (2 cerchi sottili che pulsano delicatamente)
        for i in 1...2 {
            let waveRadius = radius + CGFloat(i) * 6.0
            let wavePath = CGMutablePath()
            wavePath.addArc(center: .zero, radius: waveRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            
            let wave = SKShapeNode(path: wavePath)
            wave.strokeColor = color.withAlphaComponent(0.08)  // Molto trasparente
            wave.lineWidth = 0.8
            wave.fillColor = .clear
            wave.name = "wave\(i)"
            ringContainer.addChild(wave)
            
            // Animazione pulsazione onde (più lenta e delicata)
            let expandDuration = 3.0 + Double(i) * 0.8
            let expand = SKAction.scale(to: 1.05, duration: expandDuration)
            let contract = SKAction.scale(to: 1.0, duration: expandDuration)
            let fadeOut = SKAction.fadeAlpha(to: 0.03, duration: expandDuration)
            let fadeIn = SKAction.fadeAlpha(to: 0.08, duration: expandDuration)
            
            let pulseGroup = SKAction.group([
                SKAction.sequence([expand, contract]),
                SKAction.sequence([fadeOut, fadeIn])
            ])
            wave.run(SKAction.repeatForever(pulseGroup))
        }
        
        // 3️⃣ PULSE RADIALE (espansione periodica molto delicata)
        let pulseEmitter = SKNode()
        pulseEmitter.position = .zero
        pulseEmitter.name = "pulseEmitter"
        ringContainer.addChild(pulseEmitter)
        
        // Crea pulse ogni 3 secondi
        let createPulse = SKAction.run { [weak ringContainer] in
            guard let container = ringContainer else { return }
            self.createRadialPulse(at: container, radius: radius, color: color)
        }
        let waitAction = SKAction.wait(forDuration: 3.0)
        let pulseSequence = SKAction.sequence([createPulse, waitAction])
        pulseEmitter.run(SKAction.repeatForever(pulseSequence))
        
        // 4️⃣ PARTICELLE CHE SEGUONO LA ROTAZIONE (indicano direzione)
        let numParticles = 4  // 4 particelle equamente distribuite
        for i in 0..<numParticles {
            let angle = (CGFloat(i) / CGFloat(numParticles)) * .pi * 2
            let particleNode = SKNode()
            
            // Per ellissi: usa posizione ellittica, per cerchi: posizione circolare
            if isEllipse {
                let a = radius * ellipseRatio  // semiasse maggiore
                let b = radius                  // semiasse minore
                particleNode.position = CGPoint(x: cos(angle) * a, y: sin(angle) * b)
            } else {
                particleNode.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            }
            particleNode.name = "rotationParticle\(i)"
            
            // Particella bianca piccola
            let particle = SKShapeNode(circleOfRadius: 2)
            particle.fillColor = .white
            particle.strokeColor = .white
            particle.alpha = 0.6
            particle.glowWidth = 4.0
            particleNode.addChild(particle)
            
            ringContainer.addChild(particleNode)
        }
        
        // 5️⃣ ROTAZIONE DELL'INTERO CONTAINER - SOLO PER CERCHI, NON PER ELLISSI
        if !isEllipse {
            let rotateDuration = 1.0 / velocity * 2 * .pi
            let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: rotateDuration)
            ringContainer.run(SKAction.repeatForever(rotateAction), withKey: "ringRotation")
        } else {
            // Per ellissi: anima le particelle lungo il percorso ellittico
            animateEllipseParticles(container: ringContainer, radius: radius, ellipseRatio: ellipseRatio, velocity: velocity, numParticles: numParticles)
        }
        
        worldLayer.addChild(ringContainer)
        ringNode = mainRingShape  // Riferimento all'anello principale per interazioni
        
        // Salva il riferimento al container per poterlo controllare
        ringContainer.userData = NSMutableDictionary()
        ringContainer.userData?["ringContainer"] = true
    }
    
    // Anima le particelle lungo un percorso ellittico (senza ruotare l'ellisse stessa)
    private func animateEllipseParticles(container: SKNode, radius: CGFloat, ellipseRatio: CGFloat, velocity: CGFloat, numParticles: Int) {
        let a = radius * ellipseRatio  // semiasse maggiore (orizzontale)
        let b = radius                  // semiasse minore (verticale)
        
        // Durata completa dell'orbita
        let orbitDuration = 1.0 / velocity * 2 * .pi
        
        for i in 0..<numParticles {
            guard let particleNode = container.childNode(withName: "rotationParticle\(i)") else { continue }
            
            // Offset iniziale per distribuire le particelle
            let startAngle = (CGFloat(i) / CGFloat(numParticles)) * .pi * 2
            
            // Crea un'azione personalizzata che muove la particella lungo l'ellisse
            let moveAction = SKAction.customAction(withDuration: orbitDuration) { node, elapsedTime in
                let progress = elapsedTime / orbitDuration
                let currentAngle = startAngle + (progress * .pi * 2)
                
                // Posizione parametrica sull'ellisse
                let x = cos(currentAngle) * a
                let y = sin(currentAngle) * b
                
                node.position = CGPoint(x: x, y: y)
            }
            
            particleNode.run(SKAction.repeatForever(moveAction))
        }
    }
    
    private func createRadialPulse(at container: SKNode, radius: CGFloat, color: UIColor) {
        // Crea un cerchio che si espande e svanisce (molto delicato)
        let pulsePath = CGMutablePath()
        pulsePath.addArc(center: .zero, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        let pulse = SKShapeNode(path: pulsePath)
        pulse.strokeColor = color.withAlphaComponent(0.12)  // Molto più trasparente
        pulse.lineWidth = 1.5  // Più sottile
        pulse.fillColor = .clear
        pulse.glowWidth = 2.0  // Glow ridotto
        
        container.addChild(pulse)
        
        // Animazione: expand + fade out (più lenta)
        let expand = SKAction.scale(to: 1.3, duration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 2.0)
        let remove = SKAction.removeFromParent()
        
        let sequence = SKAction.sequence([
            SKAction.group([expand, fadeOut]),
            remove
        ])
        pulse.run(sequence)
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
        
        // POSIZIONE INIZIALE RANDOMICA: sempre vicino al pianeta ma variabile
        // Distanza: tra 150 e 350 pixel dal centro (dopo atmosfera 96px, prima ring interno 200px)
        let spawnDistance = CGFloat.random(in: 150...350)
        let spawnAngle = CGFloat.random(in: 0...(2 * .pi))
        let spawnX = size.width / 2 + cos(spawnAngle) * spawnDistance
        let spawnY = size.height / 2 + sin(spawnAngle) * spawnDistance
        
        player.position = CGPoint(x: spawnX, y: spawnY)
        player.zPosition = 10
        
        debugLog("🎯 Player spawned at distance: \(spawnDistance), angle: \(spawnAngle * 180 / .pi)°")
        
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
        
        // Fiamma frenata: fiamma conica che esce dalla punta (opposta al thruster)
        createBrakeFlame()
        
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
    }
    
    private func setupControls() {
        print("=== CONTROLS SETUP START ===")
        print("AI Mode: \(useAIController)")
        debugLog("=== CONTROLS SETUP START ===")
        debugLog("Scene size: \(size)")
        debugLog("AI Mode: \(useAIController)")
        
        // Se AI è attiva, inizializza il controller AI e nascondi i controlli
        if useAIController {
            aiController = AIController()
            aiController?.difficulty = aiDifficulty
            print("✅ AI Controller initialized with difficulty: \(aiDifficulty)")
            debugLog("✅ AI Controller initialized with difficulty: \(aiDifficulty)")
            // Non creare controlli fisici - l'AI comanderà direttamente
            return
        }
        
        // Coordinate relative alla camera (centrata sullo schermo)
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        
        // Joystick - fisso in basso a sinistra (nell'HUD layer)
        joystick = JoystickNode(baseRadius: 70, thumbRadius: 30)
        joystick?.position = CGPoint(x: 120 - halfWidth, y: 120 - halfHeight)
        joystick?.zPosition = 1000
        joystick?.onMove = { [weak self] direction in
            self?.joystickDirection = direction
        }
        joystick?.onEnd = { [weak self] in
            self?.joystickDirection = .zero
        }
        if let joystick = joystick {
            hudLayer.addChild(joystick)
        }
        
        // Brake button - a sinistra del fire button (nell'HUD layer) - ridotto ulteriormente del 15%
        brakeButton = BrakeButtonNode(radius: 36.1)  // 42.5 * 0.85 = 36.125
        brakeButton?.position = CGPoint(x: size.width - 240 - halfWidth, y: 120 - halfHeight)
        brakeButton?.zPosition = 1000
        brakeButton?.onPress = { [weak self] in
            self?.isBraking = true
        }
        brakeButton?.onRelease = { [weak self] in
            self?.isBraking = false
        }
        if let brakeButton = brakeButton {
            hudLayer.addChild(brakeButton)
        }
        
        // Fire button - fisso in basso a destra (nell'HUD layer) - ridotto ulteriormente del 15%
        fireButton = FireButtonNode(radius: 43.35)  // 51 * 0.85 = 43.35
        fireButton?.position = CGPoint(x: size.width - 120 - halfWidth, y: 120 - halfHeight)
        fireButton?.zPosition = 1000
        fireButton?.onPress = { [weak self] in
            self?.isFiring = true
        }
        fireButton?.onRelease = { [weak self] in
            self?.isFiring = false
        }
        if let fireButton = fireButton {
            hudLayer.addChild(fireButton)
        }
        
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
    
    private func setupWaveLabel() {
        // Wave label in alto al centro
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
        
        waveLabel = SKLabelNode(fontNamed: fontName)
        waveLabel.fontSize = 28
        waveLabel.fontColor = UIColor.cyan.withAlphaComponent(0.9)
        waveLabel.text = "WAVE 1"
        waveLabel.horizontalAlignmentMode = .center
        waveLabel.verticalAlignmentMode = .top
        waveLabel.position = CGPoint(x: 0, y: size.height - 20 - halfHeight)  // Centro orizzontale, allineato in alto
        waveLabel.zPosition = 1000
        
        hudLayer.addChild(waveLabel)
        
        debugLog("✅ Wave label created with font: \(fontName)")
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
                joystick?.touchBegan(touch, in: self)
                fireButton?.touchBegan(touch, in: self)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGamePaused { return }
        for touch in touches {
            joystick?.touchMoved(touch, in: self)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGamePaused { return }
        for touch in touches {
            joystick?.touchEnded(touch)
            fireButton?.touchEnded(touch)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGamePaused { return }
        for touch in touches {
            joystick?.touchEnded(touch)
            fireButton?.touchEnded(touch)
        }
    }
    
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        frameCount += 1
        
        if frameCount == 1 {
            print("🎮 First update called - useAIController: \(useAIController), isGamePaused: \(isGamePaused)")
        }
        
        if isGamePaused { return }
        
        lastUpdateTime = currentTime  // Salva per usarlo in didBegin
        
        // Debug AI state
        if frameCount % 60 == 0 {  // Log ogni 60 frame (circa 1 secondo)
            print("🔍 AI State: useAI=\(useAIController), aiController=\(aiController != nil), player=\(player != nil), planet=\(planet != nil)")
        }
        
        // Aggiorna AI Controller se attivo
        if useAIController, let ai = aiController, player != nil, planet != nil {
            // Crea GameState per l'AI
            let asteroidInfos = asteroids.map { asteroid -> AsteroidInfo in
                let dx = asteroid.position.x - planet.position.x
                let dy = asteroid.position.y - planet.position.y
                let distance = sqrt(dx * dx + dy * dy)
                
                return AsteroidInfo(
                    position: asteroid.position,
                    velocity: asteroid.physicsBody?.velocity ?? .zero,
                    size: asteroid.frame.width / 2,
                    health: asteroid.userData?["health"] as? Int ?? 1,
                    distanceFromPlanet: distance
                )
            }
            
            let gameState = GameState(
                playerPosition: player.position,
                playerVelocity: player.physicsBody?.velocity ?? .zero,
                playerAngle: player.zRotation,
                planetPosition: planet.position,
                planetRadius: planetRadius,
                planetHealth: planetHealth,
                maxPlanetHealth: maxPlanetHealth,
                atmosphereRadius: atmosphereRadius,
                maxAtmosphereRadius: maxAtmosphereRadius,
                asteroids: asteroidInfos,
                currentWave: currentWave,
                score: score,
                isGrappledToOrbit: isGrappledToOrbit,
                orbitalRingRadius: currentOrbitalRing == 1 ? orbitalRing1Radius : (currentOrbitalRing == 2 ? orbitalRing2Radius : (currentOrbitalRing == 3 ? orbitalRing3Radius : nil))
            )
            
            // Ottieni input dall'AI
            let aiMovement = ai.desiredMovement(for: gameState)
            let aiShouldFire = ai.shouldFire(for: gameState)
            
            // Salva il target per orientare la nave
            aiTargetPosition = ai.currentTarget
            
            if frameCount % 120 == 0 {  // Log ogni 2 secondi
                print("🎯 AI Debug: asteroids=\(asteroidInfos.count), player pos=\(player.position), movement=\(aiMovement), fire=\(aiShouldFire), target=\(aiTargetPosition != nil)")
            }
            
            joystickDirection = aiMovement
            isFiring = aiShouldFire
            
            // FRENO INTELLIGENTE: attiva se vai troppo veloce VERSO il pianeta
            let toPlanet = CGVector(
                dx: planet.position.x - player.position.x,
                dy: planet.position.y - player.position.y
            )
            let toPlanetLength = sqrt(toPlanet.dx * toPlanet.dx + toPlanet.dy * toPlanet.dy)
            let velocityTowardPlanet = (player.physicsBody!.velocity.dx * toPlanet.dx + player.physicsBody!.velocity.dy * toPlanet.dy) / max(toPlanetLength, 1)
            
            // Frena se velocità verso pianeta > 200 e distanza < 350
            isBraking = velocityTowardPlanet > 200 && toPlanetLength < 350
            
            if isBraking && frameCount % 60 == 0 {
                print("🛑 AI BRAKING: velocity toward planet=\(velocityTowardPlanet), distance=\(toPlanetLength)")
            }
        } else if useAIController {
            print("⚠️ AI mode active but aiController=\(aiController != nil), player=\(player != nil), planet=\(planet != nil)")
        }
        
        applyGravity()
        applyRepulsorForces()  // Gestisce repulsione asteroidi repulsor sul player
        limitAsteroidSpeed()  // Limita velocità asteroidi
        updateOrbitalGrapple()  // Gestisce slingshot zones del player
        updateAsteroidSpiralForces(currentTime)  // NUOVO: Sistema a spirale discendente per asteroidi
        updateMissiles()  // Aggiorna inseguimento missili homing
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
            } else if gravityActive {
                powerupLabel.text = "Gravity \(remainingFormatted)s"
            } else if missileActive {
                powerupLabel.text = "Missile \(remainingFormatted)s"
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
        
        if useAIController && frameCount % 120 == 0 {
            print("⚡ Movement: joystick=\(joystickDirection), magnitude=\(magnitude)")
        }
        
        // Gestione frenata - FISICA CORRETTA: forza opposta nella direzione dove punta la nave
        if isBraking {
            // Calcola direzione opposta a dove punta la nave
            // player.zRotation è l'angolo della nave (con offset di -π/2 per l'orientamento)
            let shipAngle = player.zRotation + .pi / 2  // Riporta all'angolo effettivo
            
            // Direzione opposta: aggiungi π radianti (180°)
            let brakeAngle = shipAngle + .pi
            
            // Applica forza nella direzione opposta (come un retrojet) - AUMENTATO DEL 15%
            let brakePower: CGFloat = 69.0  // 60.0 * 1.15 = 69.0
            let brakeForceX = cos(brakeAngle) * brakePower
            let brakeForceY = sin(brakeAngle) * brakePower
            
            player.physicsBody?.applyForce(CGVector(dx: brakeForceX, dy: brakeForceY))
            
            // Attiva particelle di frenata
            if let emitter = brakeFlame as? SKEmitterNode {
                emitter.particleBirthRate = 150
            }
            
            // Spegni motore principale
            thrusterGlow.alpha = max(0, thrusterGlow.alpha - 0.1)
        } else {
            // Spegni particelle di frenata
            if let emitter = brakeFlame as? SKEmitterNode {
                emitter.particleBirthRate = 0
            }
            
            if magnitude > 0.1 {
                // FISICA: Applica forza proporzionale
                // In AI mode: motori MOLTO più potenti per contrastare la gravità planetaria
                let thrustPower: CGFloat = useAIController ? 500.0 : 116.0
                let forceX = joystickDirection.dx * thrustPower * magnitude
                let forceY = joystickDirection.dy * thrustPower * magnitude
                
                if let physics = player.physicsBody {
                    physics.applyForce(CGVector(dx: forceX, dy: forceY))
                    
                    if useAIController && frameCount % 120 == 0 {
                        print("🚀 Force applied: (\(forceX), \(forceY)), velocity: \(physics.velocity)")
                    }
                } else {
                    print("❌ ERROR: player.physicsBody is nil!")
                }
                
                // Orienta la nave: se AI con target, punta al target, altrimenti nella direzione del movimento
                if useAIController, let target = aiTargetPosition {
                    // AI: punta verso il target
                    let toTarget = CGVector(
                        dx: target.x - player.position.x,
                        dy: target.y - player.position.y
                    )
                    let angle = atan2(toTarget.dy, toTarget.dx) - .pi / 2
                    player.zRotation = angle
                } else {
                    // Controllo umano: punta nella direzione del movimento
                    let angle = atan2(joystickDirection.dy, joystickDirection.dx) - .pi / 2
                    player.zRotation = angle
                }
                
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
    }
    
    private func createBrakeFlame() {
        // Crea sistema particellare come "soffio d'aria" dalla punta della nave
        let particles = SKEmitterNode()
        
        // Posizione: davanti alla nave
        particles.position = CGPoint(x: 0, y: 12)
        
        // Particelle molto piccole e veloci - USA LA TEXTURE GENERATA
        particles.particleTexture = particleTexture
        particles.particleBirthRate = 150  // Molte particelle
        particles.numParticlesToEmit = 0  // Continuo
        
        // Dimensione piccola ma visibile
        particles.particleSize = CGSize(width: 4, height: 4)
        particles.particleScale = 0.5
        particles.particleScaleRange = 0.3
        particles.particleScaleSpeed = -1.0
        
        // Colore verde brillante (visibile)
        particles.particleColor = UIColor(red: 0.3, green: 1.0, blue: 0.5, alpha: 1.0)
        particles.particleColorBlendFactor = 1.0
        particles.particleColorSequence = nil
        
        // Direzione: verso l'alto (davanti alla nave) - RELATIVO alla rotazione della nave
        particles.emissionAngle = .pi / 2  // 90° (su in coordinate locali della nave)
        particles.emissionAngleRange = .pi / 6  // ±30° di spread (più concentrato)
        
        // Velocità MOLTO alta per spruzzare con forza
        particles.particleSpeed = 300  // Aumentato per effetto "alta pressione"
        particles.particleSpeedRange = 50
        
        // Vita breve
        particles.particleLifetime = 0.35
        particles.particleLifetimeRange = 0.1
        
        // Alpha decay rapido
        particles.particleAlpha = 1.0
        particles.particleAlphaRange = 0.0
        particles.particleAlphaSpeed = -3.5
        
        // Posizione iniziale concentrata (getto stretto)
        particles.particlePositionRange = CGVector(dx: 3, dy: 1)
        particles.xAcceleration = 0
        particles.yAcceleration = 0
        
        particles.zPosition = 1  // Sopra la nave
        // RIMANE nel sistema locale della nave (no targetNode)
        // Questo fa sì che le particelle seguano la rotazione della nave al momento dell'emissione
        
        // Inizialmente spento
        particles.particleBirthRate = 0
        
        brakeFlame = particles
        player.addChild(brakeFlame)
    }
    
    private func updatePlayerShooting(_ currentTime: TimeInterval) {
        guard isFiring else { return }
        
        if currentTime - lastFireTime >= currentFireRate {
            fireProjectile()
            lastFireTime = currentTime
        }
    }
    
    private func fireProjectile() {
        // Se missili attivi, crea un missile invece di un proiettile normale
        if missileActive {
            fireMissile()
            return
        }
        
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
        
        // Salva il moltiplicatore di danno E la dimensione originale nel userData
        projectile.userData = NSMutableDictionary()
        projectile.userData?["damageMultiplier"] = projectileDamageMultiplier
        projectile.userData?["originalSize"] = NSValue(cgSize: usedSize)
        
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
        let speed: CGFloat = 575  // Aumentato da 500 (+15%)
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
    
    // MARK: - Missile System
    private func fireMissile() {
        playShootSound()
        
        // Missile: più affusolato (3x larghezza, 3x altezza - ridotto da 4x)
        let missileWidth = projectileBaseSize.width * 3.0
        let missileHeight = projectileBaseSize.height * 3.0  // Ridotto da 4.0
        
        let missile = SKNode()
        missile.name = "missile"
        
        // Corpo principale affusolato (rettangolo viola/grigio con più corner radius)
        let body = SKShapeNode(rectOf: CGSize(width: missileWidth, height: missileHeight), cornerRadius: 2)
        body.fillColor = UIColor(red: 0.5, green: 0.4, blue: 0.6, alpha: 1.0)
        body.strokeColor = UIColor(red: 0.6, green: 0.5, blue: 0.7, alpha: 1.0)
        body.lineWidth = 1
        missile.addChild(body)
        
        // Punta affusolata davanti (triangolo)
        let nosePath = CGMutablePath()
        nosePath.move(to: CGPoint(x: 0, y: missileHeight/2))
        nosePath.addLine(to: CGPoint(x: -missileWidth/2, y: missileHeight/2 - 4))
        nosePath.addLine(to: CGPoint(x: missileWidth/2, y: missileHeight/2 - 4))
        nosePath.closeSubpath()
        
        let nose = SKShapeNode(path: nosePath)
        nose.fillColor = UIColor(red: 0.6, green: 0.5, blue: 0.7, alpha: 1.0)
        nose.strokeColor = .clear
        missile.addChild(nose)
        
        // Bandina rossa pulsante (reattore) - posizionata dietro
        let flagWidth: CGFloat = missileWidth * 0.7
        let flagHeight: CGFloat = 5
        let flag = SKShapeNode(rectOf: CGSize(width: flagWidth, height: flagHeight))
        flag.fillColor = .red
        flag.strokeColor = .clear
        flag.position = CGPoint(x: 0, y: -missileHeight/2 - flagHeight/2)  // Dietro il missile
        flag.name = "flag"
        missile.addChild(flag)
        
        // Animazione pulsazione della bandina
        let pulseUp = SKAction.scaleY(to: 1.5, duration: 0.15)
        let pulseDown = SKAction.scaleY(to: 1.0, duration: 0.15)
        let pulse = SKAction.sequence([pulseUp, pulseDown])
        flag.run(SKAction.repeatForever(pulse))
        
        // Physics body più grande per collisioni migliori
        let bodyRadius = max(missileWidth, missileHeight) / 2 * 1.2  // 20% più grande
        missile.physicsBody = SKPhysicsBody(circleOfRadius: bodyRadius)
        missile.physicsBody?.isDynamic = true
        missile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        missile.physicsBody?.contactTestBitMask = PhysicsCategory.atmosphere | PhysicsCategory.asteroid
        missile.physicsBody?.collisionBitMask = 0
        missile.physicsBody?.mass = 0.08  // Più pesante per inerzia maggiore
        missile.physicsBody?.linearDamping = 0.15  // Più damping per meno velocità
        missile.physicsBody?.affectedByGravity = false
        
        // Posizione davanti alla nave
        let angle = player.zRotation + .pi / 2
        let offset: CGFloat = 25
        missile.position = CGPoint(
            x: player.position.x + cos(angle) * offset,
            y: player.position.y + sin(angle) * offset
        )
        missile.zPosition = 8
        missile.zRotation = player.zRotation
        
        // Danno doppio
        missile.userData = NSMutableDictionary()
        missile.userData?["damageMultiplier"] = 2.0
        
        // Velocità iniziale più lenta
        let initialSpeed: CGFloat = 250  // Ridotta da 300
        missile.physicsBody?.velocity = CGVector(
            dx: cos(angle) * initialSpeed,
            dy: sin(angle) * initialSpeed
        )
        
        // Trova target più vicino
        if let target = findClosestAsteroid(to: missile.position) {
            missile.userData?["target"] = target
        }
        
        worldLayer.addChild(missile)
        missiles.append(missile)
        
        // Rimuovi dopo 10 secondi
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: 10.0),
            SKAction.removeFromParent()
        ])
        missile.run(removeAction)
        
        debugLog("🚀 Missile fired with homing capability")
    }
    
    private func findClosestAsteroid(to position: CGPoint) -> SKNode? {
        var closestAsteroid: SKNode? = nil
        var closestDistance: CGFloat = .greatestFiniteMagnitude
        
        for child in worldLayer.children {
            if child.name?.starts(with: "asteroid") == true,
               let physicsBody = child.physicsBody,
               physicsBody.isDynamic {
                let distance = hypot(child.position.x - position.x, child.position.y - position.y)
                if distance < closestDistance {
                    closestDistance = distance
                    closestAsteroid = child
                }
            }
        }
        
        return closestAsteroid
    }
    
    private func updateMissiles() {
        // Rimuovi missili senza parent
        missiles.removeAll { $0.parent == nil }
        
        for missile in missiles {
            guard let physicsBody = missile.physicsBody else { continue }
            
            // EVITA LA TERRA: se troppo vicino al pianeta, applica forza repulsiva
            let planetCenter = planet.position
            let distanceFromPlanet = hypot(missile.position.x - planetCenter.x, missile.position.y - planetCenter.y)
            let dangerZone: CGFloat = atmosphereRadius + 30  // Zona di sicurezza oltre atmosfera
            
            if distanceFromPlanet < dangerZone {
                // Forza repulsiva per allontanarsi dal pianeta
                let awayAngle = atan2(missile.position.y - planetCenter.y, missile.position.x - planetCenter.x)
                let repulsionForce: CGFloat = 250  // Forza forte per allontanamento rapido
                let repulsionX = cos(awayAngle) * repulsionForce
                let repulsionY = sin(awayAngle) * repulsionForce
                physicsBody.applyForce(CGVector(dx: repulsionX, dy: repulsionY))
                
                // Ruota missile nella direzione di allontanamento
                missile.zRotation = awayAngle - .pi / 2
                continue  // Salta l'inseguimento del target
            }
            
            // Verifica se il target è ancora valido
            var target = missile.userData?["target"] as? SKNode
            if target?.parent == nil {
                // Target distrutto, trova nuovo target
                target = findClosestAsteroid(to: missile.position)
                missile.userData?["target"] = target
            }
            
            guard let validTarget = target else { continue }
            
            // Calcola direzione verso il target
            let dx = validTarget.position.x - missile.position.x
            let dy = validTarget.position.y - missile.position.y
            let distance = hypot(dx, dy)
            
            guard distance > 1 else { continue }
            
            let targetAngle = atan2(dy, dx)
            
            // Forza di spinta ridotta per controllo migliore
            let thrustForce: CGFloat = 120  // Ridotta da 150
            let thrustX = cos(targetAngle) * thrustForce
            let thrustY = sin(targetAngle) * thrustForce
            
            physicsBody.applyForce(CGVector(dx: thrustX, dy: thrustY))
            
            // Ruota missile verso direzione di movimento (non target diretto)
            let velocityAngle = atan2(physicsBody.velocity.dy, physicsBody.velocity.dx)
            missile.zRotation = velocityAngle - .pi / 2  // Aggiusta per orientamento
            
            // Limita velocità massima (più lenta)
            let maxSpeed: CGFloat = 320  // Ridotta da 400
            let currentSpeed = hypot(physicsBody.velocity.dx, physicsBody.velocity.dy)
            if currentSpeed > maxSpeed {
                let scale = maxSpeed / currentSpeed
                physicsBody.velocity = CGVector(
                    dx: physicsBody.velocity.dx * scale,
                    dy: physicsBody.velocity.dy * scale
                )
            }
        }
    }
    
    // MARK: - Gravity System
    private func applyGravity() {
        // OTTIMIZZAZIONE: Calcola gravità solo per oggetti vicini al pianeta o al player
        let planetPos = planet.position
        let maxGravityDistance: CGFloat = 1500  // Oltre questa distanza, niente gravità
        
        // Se Gravity power-up è attivo, applica gravità VERSO IL PLAYER (5x più forte)
        if gravityActive {
            // NESSUNA gravità sul player verso il pianeta
            // Applica forte gravità verso il player SOLO per asteroidi (NON power-up)
            let playerPos = player.position
            for asteroid in asteroids {
                // OTTIMIZZAZIONE: Skip se troppo lontano dal player
                let dx = asteroid.position.x - playerPos.x
                let dy = asteroid.position.y - playerPos.y
                let distanceSquared = dx * dx + dy * dy
                if distanceSquared > maxGravityDistance * maxGravityDistance {
                    continue
                }
                
                if let asteroidBody = asteroid.physicsBody {
                    applyGravityToPlayer(node: asteroid, body: asteroidBody, multiplier: 5.0)
                }
            }
            
            // POWER-UP: NO gravità (fluttuano liberamente)
        } else {
            // Gravità NORMALE verso il pianeta
            // Applica gravità al player (ridotta del 5%)
            if let playerBody = player.physicsBody {
                applyGravityToNode(node: player, body: playerBody, multiplier: 0.95)
            }
            
            // Controllo debris cleanup: se ci sono pochi detriti piccoli, aumenta la gravità
            checkDebrisCleanup()
            
            // Applica gravità agli asteroidi (aumenta del 5% per ogni wave)
            // Se debris cleanup attivo, tripla gravità per detriti small
            for asteroid in asteroids {
                // OTTIMIZZAZIONE: Skip se troppo lontano dal pianeta
                let dx = asteroid.position.x - planetPos.x
                let dy = asteroid.position.y - planetPos.y
                let distanceSquared = dx * dx + dy * dy
                if distanceSquared > maxGravityDistance * maxGravityDistance {
                    continue
                }
                
                if let asteroidBody = asteroid.physicsBody {
                    var multiplier = asteroidGravityMultiplier
                    
                    // Se cleanup attivo e l'asteroide è SMALL, tripla la gravità
                    if debrisCleanupActive {
                        if let sizeString = asteroid.name?.split(separator: "_").last,
                           let sizeRaw = Int(String(sizeString)),
                           let size = AsteroidSize(rawValue: sizeRaw),
                           size == .small {
                            multiplier *= 3.0  // Tripla gravità per detriti piccoli
                        }
                    }
                    
                    applyGravityToNode(node: asteroid, body: asteroidBody, multiplier: multiplier)
                }
            }
            
            // POWER-UP: NO gravità (fluttuano liberamente)
        }
    }
    
    private func checkDebrisCleanup() {
        // Conta solo gli asteroidi SMALL
        let smallAsteroids = asteroids.filter { asteroid in
            if let sizeString = asteroid.name?.split(separator: "_").last,
               let sizeRaw = Int(String(sizeString)),
               let size = AsteroidSize(rawValue: sizeRaw) {
                return size == .small
            }
            return false
        }
        
        // Se ci sono SOLO detriti small e sono meno di 5, attiva cleanup
        let hasOnlySmallDebris = (asteroids.count == smallAsteroids.count) && smallAsteroids.count > 0
        let fewDebrisLeft = smallAsteroids.count < 5
        
        if hasOnlySmallDebris && fewDebrisLeft && !debrisCleanupActive {
            debrisCleanupActive = true
            debugLog("🧹 Debris cleanup activated - \(smallAsteroids.count) small asteroids, 3x gravity")
        } else if (!hasOnlySmallDebris || !fewDebrisLeft) && debrisCleanupActive {
            debrisCleanupActive = false
            debugLog("🧹 Debris cleanup deactivated")
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
    
    private func applyGravityToPlayer(node: SKNode, body: SKPhysicsBody, multiplier: CGFloat) {
        // Calcola distanza dal PLAYER invece che dal pianeta
        let dx = player.position.x - node.position.x
        let dy = player.position.y - node.position.y
        let distanceSquared = dx * dx + dy * dy
        let distance = sqrt(distanceSquared)
        
        // Evita divisione per zero e collisione col player
        guard distance > 30 else { return }  // Raggio minimo per evitare problemi
        
        // Forza gravitazionale F = G * M1 * M2 / d^2
        // Usa la massa del pianeta come base (effetto molto forte)
        let force = gravitationalConstant * planetMass * body.mass / distanceSquared * multiplier
        
        // Direzione normalizzata verso il PLAYER
        let forceX = (dx / distance) * force
        let forceY = (dy / distance) * force
        
        // Applica la forza
        body.applyForce(CGVector(dx: forceX, dy: forceY))
    }
    
    private func applyRepulsorForces() {
        // Applica forza di repulsione dal player per ogni asteroide repulsor
        guard let playerBody = player.physicsBody else { return }
        
        for asteroid in asteroids {
            // Controlla se è un repulsor
            guard let asteroidType = asteroid.userData?["type"] as? AsteroidType,
                  case .repulsor = asteroidType else { continue }
            
            // Calcola distanza tra player e asteroide repulsor
            let dx = player.position.x - asteroid.position.x
            let dy = player.position.y - asteroid.position.y
            let distanceSquared = dx * dx + dy * dy
            let distance = sqrt(distanceSquared)
            
            // Raggio di influenza: 3x il raggio dell'asteroide
            let influenceRadius = asteroidType.size.radius * 3.0
            
            // Applica repulsione solo se entro il raggio di influenza
            guard distance < influenceRadius && distance > 0 else { continue }
            
            // Forza di repulsione (più forte quando più vicino)
            // Inversamente proporzionale al quadrato della distanza
            let baseForce = asteroidType.repulsionForce
            let force = baseForce * (influenceRadius / distance)
            
            // Direzione: ALLONTANA il player dall'asteroide (opposta alla gravità)
            let normalX = dx / distance
            let normalY = dy / distance
            
            let repulsionX = normalX * force
            let repulsionY = normalY * force
            
            // Applica la forza al player
            playerBody.applyForce(CGVector(dx: repulsionX, dy: repulsionY))
            
            // Feedback visivo: flash delle particelle quando repulsa attivamente
            if let particles = asteroid.childNode(withName: "repulsorParticles") as? SKEmitterNode {
                particles.particleBirthRate = 50  // Aumenta temporaneamente
                
                // Ripristina dopo un breve delay
                let resetAction = SKAction.run {
                    particles.particleBirthRate = 30
                }
                particles.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.1),
                    resetAction
                ]))
            }
        }
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
    
    private func updateAsteroidSlingshotZones(_ currentTime: TimeInterval) {
        // SISTEMA DISATTIVATO - In fase di riprogettazione
        // TODO: Implementare movimento a spirale discendente
        return
        
        /* VECCHIO CODICE DISATTIVATO - Commentato per riprogettazione
        let planetCenter = planet.position
        
        // Check per giri completati ogni 0.1 secondi
        let shouldCheckOrbits = (currentTime - lastSlingshotCheck) >= 0.1
        if shouldCheckOrbits {
            lastSlingshotCheck = currentTime
        }
        
        for asteroid in asteroids {
            guard let asteroidBody = asteroid.physicsBody,
                  let userData = asteroid.userData else { continue }
            
            // Leggi stato slingshot corrente
            let inSlingshot = userData["inSlingshot"] as? Bool ?? false
            let slingshotRing = userData["slingshotRing"] as? Int ?? 0
            var slingshotOrbits = userData["slingshotOrbits"] as? Int ?? 0
            var slingshotStartAngle = userData["slingshotStartAngle"] as? CGFloat ?? 0.0
            var slingshotTargetRadius = userData["slingshotTargetRadius"] as? CGFloat ?? 0.0
            
            // Calcola distanza e angolo dal centro
            let dx = asteroid.position.x - planetCenter.x
            let dy = asteroid.position.y - planetCenter.y
            let distanceFromCenter = sqrt(dx * dx + dy * dy)
            let currentAngle = atan2(dy, dx)
            
            // Determina l'anello più vicino - SOLO TRA QUELLI ATTIVI
            var availableRings: [(distance: CGFloat, ring: Int, radius: CGFloat, velocity: CGFloat)] = []
            
            // Anello 1 disponibile dalla wave 2
            if currentWave >= 2 {
                availableRings.append((
                    distance: abs(distanceFromCenter - orbitalRing1Radius),
                    ring: 1,
                    radius: orbitalRing1Radius,
                    velocity: orbitalBaseAngularVelocity
                ))
            }
            
            // Anello 2 dalla wave 3
            if currentWave >= 3 {
                availableRings.append((
                    distance: abs(distanceFromCenter - orbitalRing2Radius),
                    ring: 2,
                    radius: orbitalRing2Radius,
                    velocity: orbitalBaseAngularVelocity * 1.33
                ))
            }
            
            // Anello 3 dalla wave 4
            if currentWave >= 4 {
                availableRings.append((
                    distance: abs(distanceFromCenter - orbitalRing3Radius),
                    ring: 3,
                    radius: orbitalRing3Radius,
                    velocity: orbitalBaseAngularVelocity * 1.77
                ))
            }
            
            // Se non ci sono anelli disponibili, salta questo asteroide
            guard !availableRings.isEmpty else { continue }
            
            // Trova il più vicino tra quelli disponibili
            let closest = availableRings.min(by: { $0.distance < $1.distance })!
            let minDistance = closest.distance
            let closestRing = closest.ring
            let closestRingRadius = closest.radius
            let closestRingVelocity = closest.velocity
            
            // ===== CAPTURE: Tentativo probabilistico di cattura =====
            if !inSlingshot && minDistance < slingshotCaptureThreshold {
                // Solo 30% di probabilità di aggancio (70% passa attraverso)
                if CGFloat.random(in: 0...1) < slingshotCaptureChance {
                    userData["inSlingshot"] = true
                    userData["slingshotRing"] = closestRing
                    userData["slingshotCaptureTime"] = currentTime
                    debugLog("🎯 Asteroid captured in ring \(closestRing) (30% chance)")
                }
                continue
            }
            
            // ===== SLINGSHOT ORBIT: Gestione realistica con gravità attiva =====
            if inSlingshot && slingshotRing > 0 {
                let captureTime = userData["slingshotCaptureTime"] as? TimeInterval ?? currentTime
                let timeInRing = currentTime - captureTime
                
                // SGANCIO FORZATO dopo 3 secondi
                if timeInRing > slingshotMaxDuration {
                    userData["inSlingshot"] = false
                    userData["slingshotRing"] = 0
                    asteroid.removeAction(forKey: "slingshotRotation")
                    debugLog("⏱️ Asteroid forced release (timeout)")
                    continue
                }
                
                // PROBABILITÀ CONTINUA DI SGANCIO verso interno (3% per frame)
                if CGFloat.random(in: 0...1) < slingshotReleaseChancePerFrame {
                    userData["inSlingshot"] = false
                    userData["slingshotRing"] = 0
                    asteroid.removeAction(forKey: "slingshotRotation")
                    
                    // Piccolo impulso radiale verso interno
                    let releaseForce: CGFloat = 30.0
                    asteroidBody.applyImpulse(CGVector(
                        dx: -(dx / distanceFromCenter) * releaseForce,
                        dy: -(dy / distanceFromCenter) * releaseForce
                    ))
                    debugLog("📉 Asteroid released inward from ring \(slingshotRing)")
                    continue
                }
                
                // PROBABILITÀ BASSA DI EIEZIONE verso esterno (8%)
                if CGFloat.random(in: 0...1) < slingshotEjectChance {
                    userData["inSlingshot"] = false
                    userData["slingshotRing"] = 0
                    asteroid.removeAction(forKey: "slingshotRotation")
                    
                    let ringVelocity = slingshotRing == 1 ? orbitalBaseAngularVelocity :
                                       slingshotRing == 2 ? orbitalBaseAngularVelocity * 1.33 :
                                       orbitalBaseAngularVelocity * 1.77
                    
                    let ejectSpeed = ringVelocity * closestRingRadius * 1.5
                    let ejectAngle = currentAngle + .pi / 4
                    asteroidBody.velocity = CGVector(
                        dx: cos(ejectAngle) * ejectSpeed,
                        dy: sin(ejectAngle) * ejectSpeed
                    )
                    debugLog("🚀 Asteroid ejected outward from ring \(slingshotRing)")
                    continue
                }
                
                // FORZA CENTRIPETA per mantenere l'asteroide sull'anello
                let radiusDiff = closestRingRadius - distanceFromCenter
                let centripetalForce: CGFloat = 80.0  // Forza forte per trattenere
                let forceX = (dx / distanceFromCenter) * radiusDiff * centripetalForce
                let forceY = (dy / distanceFromCenter) * radiusDiff * centripetalForce
                asteroidBody.applyForce(CGVector(dx: forceX, dy: forceY))
                
                // BOOST TANGENZIALE
                let ringVelocity = slingshotRing == 1 ? orbitalBaseAngularVelocity :
                                   slingshotRing == 2 ? orbitalBaseAngularVelocity * 1.33 :
                                   orbitalBaseAngularVelocity * 1.77
                
                // Determina se l'anello è un'ellisse
                let isEllipseRing = (slingshotRing == 1 && orbitalRing1IsEllipse) ||
                                   (slingshotRing == 2 && orbitalRing2IsEllipse) ||
                                   (slingshotRing == 3 && orbitalRing3IsEllipse)
                
                // Calcola il moltiplicatore di velocità per ellisse
                let speedMultiplier = getEllipseSpeedMultiplier(angle: currentAngle, baseRadius: closestRingRadius, isEllipse: isEllipseRing)
                
                let tangentialSpeed = ringVelocity * closestRingRadius * speedMultiplier
                let tangentialVx = -sin(currentAngle) * tangentialSpeed
                let tangentialVy = cos(currentAngle) * tangentialSpeed
                
                let currentVx = asteroidBody.velocity.dx
                let currentVy = asteroidBody.velocity.dy
                
                // Boost forte per sincronizzare con l'anello
                asteroidBody.velocity = CGVector(
                    dx: currentVx + (tangentialVx - currentVx) * slingshotBoostMultiplier,
                    dy: currentVy + (tangentialVy - currentVy) * slingshotBoostMultiplier
                )
                
                // ROTAZIONE
                let rotationSpeed = ringVelocity * 2.5
                if asteroid.action(forKey: "slingshotRotation") == nil {
                    let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 1.0 / Double(rotationSpeed))
                    asteroid.run(SKAction.repeatForever(rotateAction), withKey: "slingshotRotation")
                }
                continue  // Salta il resto per evitare controlli inutili
            }
            
            // Fuori dall'anello: rimuovi rotazione
            if asteroid.action(forKey: "slingshotRotation") != nil {
                asteroid.removeAction(forKey: "slingshotRotation")
            }
        }
        */
    }
    
    // MARK: - Spiral Descent System (Nuovo)
    /// Applica forze continue agli asteroidi vicino ai ring per creare movimento a spirale discendente
    private func updateAsteroidSpiralForces(_ currentTime: TimeInterval) {
        let ringRadii: [CGFloat] = [orbitalRing1Radius, orbitalRing2Radius, orbitalRing3Radius]
        var asteroidsInInfluence = 0  // Debug counter
        
        // Itera sugli asteroidi (array asteroids, non worldLayer.children!)
        for asteroid in asteroids {
            guard let asteroidBody = asteroid.physicsBody else {
                continue
            }
            
            // Calcola distanza dal centro
            let distanceFromCenter = sqrt(asteroid.position.x * asteroid.position.x + 
                                         asteroid.position.y * asteroid.position.y)
            
            // Trova il ring più vicino
            var minDistanceToRing: CGFloat = .infinity
            var nearestRingRadius: CGFloat = 0
            
            for ringRadius in ringRadii {
                let distToRing = abs(distanceFromCenter - ringRadius)
                if distToRing < minDistanceToRing {
                    minDistanceToRing = distToRing
                    nearestRingRadius = ringRadius
                }
            }
            
            // Se l'asteroide è nell'area di influenza di un ring
            if minDistanceToRing < spiralInfluenceDistance {
                // NUOVO: Calcola velocità radiale (verso centro = negativa, via dal centro = positiva)
                let radialVelocity = (asteroidBody.velocity.dx * asteroid.position.x + 
                                     asteroidBody.velocity.dy * asteroid.position.y) / distanceFromCenter
                
                // APPLICA FORZE SOLO SE ASTEROIDE STA AVVICINANDO AL CENTRO (velocità radiale < 0)
                // Questo evita che asteroidi rimbalzati restino intrappolati tra ring
                if radialVelocity < 0 {
                    asteroidsInInfluence += 1
                    
                    // Calcola l'intensità delle forze basata sulla vicinanza (quadratica per drop-off più naturale)
                    let influenceRatio = 1.0 - (minDistanceToRing / spiralInfluenceDistance)
                    let influenceSquared = influenceRatio * influenceRatio  // Drop-off quadratico
                    
                    // Calcola vettore tangenziale (perpendicolare al raggio, direzione orbita)
                    let angle = atan2(asteroid.position.y, asteroid.position.x)
                    let tangentialAngle = angle + .pi / 2  // 90° per direzione tangenziale
                    
                    let tangentialX = cos(tangentialAngle)
                    let tangentialY = sin(tangentialAngle)
                    
                    // Calcola vettore radiale (verso il centro)
                    let radialX = -asteroid.position.x / distanceFromCenter
                    let radialY = -asteroid.position.y / distanceFromCenter
                    
                    // FORZA TANGENZIALE: come piccolo reattore che cerca di seguire orbita
                    // Usa influenza quadratica per essere più debole a distanza
                    let tangentialForce = spiralTangentialForce * influenceSquared
                    asteroidBody.applyForce(CGVector(dx: tangentialX * tangentialForce,
                                                     dy: tangentialY * tangentialForce))
                    
                    // FORZA RADIALE: attrazione principale verso il centro (più forte)
                    let radialForce = spiralRadialForce * influenceRatio
                    asteroidBody.applyForce(CGVector(dx: radialX * radialForce,
                                                     dy: radialY * radialForce))
                    
                    // Damping leggero per fluidità
                    asteroidBody.velocity.dx *= spiralDamping
                    asteroidBody.velocity.dy *= spiralDamping
                    
                    // Visual feedback SOTTILE: rotazione lenta dell'asteroide su se stesso
                    if asteroid.action(forKey: "spiralRotation") == nil {
                        let rotationSpeed = 3.0 + Double(influenceRatio) * 2.0  // MOLTO più lento
                        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: rotationSpeed)
                        let repeatAction = SKAction.repeatForever(rotateAction)
                        asteroid.run(repeatAction, withKey: "spiralRotation")
                    }
                } else {
                    // Asteroide sta allontanando (rimbalzato) - nessuna forza, rimuovi rotazione
                    if asteroid.action(forKey: "spiralRotation") != nil {
                        asteroid.removeAction(forKey: "spiralRotation")
                    }
                }
            } else {
                // Fuori dall'area di influenza: rimuovi rotazione
                if asteroid.action(forKey: "spiralRotation") != nil {
                    asteroid.removeAction(forKey: "spiralRotation")
                }
            }
        }
        
        // Debug: mostra quanti asteroidi sono nell'area di influenza
        if asteroidsInInfluence > 0 {
            debugLog("🌀 Spiral Forces: \(asteroidsInInfluence) asteroids in ring influence")
        }
    }
    
    // VECCHIO CODICE COMMENTATO (non più usato)
    /*
    private func oldSlingshotCode() {
                if false {
                    let angleDiff = currentAngle - slingshotStartAngle
                    let normalizedDiff = atan2(sin(angleDiff), cos(angleDiff))
                    
                    // Se ha fatto un giro completo (tolleranza ±0.2 radianti)
                    if abs(normalizedDiff) < 0.2 && slingshotOrbits > 0 {
                        slingshotOrbits += 1
                        userData["slingshotOrbits"] = slingshotOrbits
                        userData["slingshotStartAngle"] = currentAngle
                        
                        debugLog("🔄 Asteroid completed orbit \(slingshotOrbits) in ring \(slingshotRing)")
                        
                        // Decay del raggio dopo ogni giro
                        slingshotTargetRadius -= slingshotDecayPerOrbit
                        userData["slingshotTargetRadius"] = slingshotTargetRadius
                        
                        // Check per eiezione
                        if slingshotOrbits >= slingshotOrbitsBeforeEject || CGFloat.random(in: 0...1) < slingshotEjectionChance {
                            // EIEZIONE verso l'anello interno!
                            let nextRing = slingshotRing - 1
                            if nextRing > 0 {
                                // Eject verso anello interno con boost
                                let ejectAngle = currentAngle + .pi / 2  // Perpendic to radial
                                let ejectSpeed: CGFloat = 100
                                asteroidBody.velocity = CGVector(
                                    dx: cos(ejectAngle) * ejectSpeed,
                                    dy: sin(ejectAngle) * ejectSpeed
                                )
                                
                                userData["inSlingshot"] = false
                                userData["slingshotRing"] = 0
                                userData["slingshotOrbits"] = 0
                                debugLog("� Asteroid ejected from ring \(slingshotRing) to ring \(nextRing)")
                                continue
                            } else {
                                // Eject verso il pianeta
                                userData["inSlingshot"] = false
                                userData["slingshotRing"] = 0
                                userData["slingshotOrbits"] = 0
                                debugLog("🚀 Asteroid ejected from ring 1 towards planet")
                                continue
                            }
                        }
                    } else if slingshotOrbits == 0 {
                        // Primo passaggio: marca che ha iniziato
                        slingshotOrbits = 1
                        userData["slingshotOrbits"] = slingshotOrbits
                    }
                }
                
                // Applica boost tangenziale per mantenere l'orbita
                let targetRadius = slingshotTargetRadius
                let ringVelocity = slingshotRing == 1 ? orbitalBaseAngularVelocity :
                                   slingshotRing == 2 ? orbitalBaseAngularVelocity * 1.33 :
                                   orbitalBaseAngularVelocity * 1.77
                
                // Forza centripeta per mantenere il raggio
                let radiusDiff = targetRadius - distanceFromCenter
                let centripetalForce: CGFloat = 50.0
                let forceX = (dx / distanceFromCenter) * radiusDiff * centripetalForce
                let forceY = (dy / distanceFromCenter) * radiusDiff * centripetalForce
                asteroidBody.applyForce(CGVector(dx: forceX, dy: forceY))
                
                // Boost tangenziale
                let tangentialSpeed = ringVelocity * targetRadius
                let tangentialVx = -sin(currentAngle) * tangentialSpeed
                let tangentialVy = cos(currentAngle) * tangentialSpeed
                
                // Correggi la velocità verso la tangente
                let currentVx = asteroidBody.velocity.dx
                let currentVy = asteroidBody.velocity.dy
                asteroidBody.velocity = CGVector(
                    dx: currentVx + (tangentialVx - currentVx) * 0.1,
                    dy: currentVy + (tangentialVy - currentVy) * 0.1
                )
                
                // ROTAZIONE REALISTICA: ruota l'asteroide in base alla velocità orbitale
                // Velocità angolare proporzionale alla velocità dell'anello
                let rotationSpeed = ringVelocity * 2.0  // Moltiplicatore per renderla visibile
                
                // Controlla se esiste già un'azione di rotazione
                if asteroid.action(forKey: "slingshotRotation") == nil {
                    let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 1.0 / Double(rotationSpeed))
                    asteroid.run(SKAction.repeatForever(rotateAction), withKey: "slingshotRotation")
                }
            }
    }
    */
    
    private func updateOrbitalGrapple() {
        guard let playerBody = player.physicsBody else { return }
        
        // Calcola distanza dal centro del pianeta
        let planetCenter = planet.position
        let dx = player.position.x - planetCenter.x
        let dy = player.position.y - planetCenter.y
        let distanceFromCenter = sqrt(dx * dx + dy * dy)
        
        // Trova l'anello più vicino - SOLO TRA QUELLI ATTIVI
        var availableRings: [(distance: CGFloat, ring: Int, radius: CGFloat, velocity: CGFloat, node: SKShapeNode?)] = []
        
        // Anello 1 disponibile dalla wave 2
        if currentWave >= 2 {
            let distance1 = distanceFromEllipse(point: player.position, center: planetCenter, baseRadius: orbitalRing1Radius, isEllipse: orbitalRing1IsEllipse)
            availableRings.append((
                distance: distance1,
                ring: 1,
                radius: orbitalRing1Radius,
                velocity: orbitalBaseAngularVelocity,
                node: orbitalRing1
            ))
        }
        
        // Anello 2 dalla wave 3
        if currentWave >= 3 {
            let distance2 = distanceFromEllipse(point: player.position, center: planetCenter, baseRadius: orbitalRing2Radius, isEllipse: orbitalRing2IsEllipse)
            availableRings.append((
                distance: distance2,
                ring: 2,
                radius: orbitalRing2Radius,
                velocity: orbitalBaseAngularVelocity * 1.33,
                node: orbitalRing2
            ))
        }
        
        // Anello 3 dalla wave 4
        if currentWave >= 4 {
            let distance3 = distanceFromEllipse(point: player.position, center: planetCenter, baseRadius: orbitalRing3Radius, isEllipse: orbitalRing3IsEllipse)
            availableRings.append((
                distance: distance3,
                ring: 3,
                radius: orbitalRing3Radius,
                velocity: orbitalBaseAngularVelocity * 1.77,
                node: orbitalRing3
            ))
        }
        
        // Se non ci sono anelli disponibili, esci
        guard !availableRings.isEmpty else { return }
        
        // Trova il più vicino tra quelli disponibili
        let closest = availableRings.min(by: { $0.distance < $1.distance })!
        let minDistance = closest.distance
        let closestRing = closest.ring
        let closestRingRadius = closest.radius
        let closestRingVelocity = closest.velocity
        let closestRingNode = closest.node
        
        let distanceFromRing = minDistance
        
        // Determina se l'anello più vicino è un'ellisse
        let isClosestEllipse = (closestRing == 1 && orbitalRing1IsEllipse) ||
                              (closestRing == 2 && orbitalRing2IsEllipse) ||
                              (closestRing == 3 && orbitalRing3IsEllipse)
        
        // AGGANCIO GRADUALE: più sei vicino, più sei attratto
        // Per ellissi: threshold e velocità più tolleranti (per gestire accelerazione)
        // Ring 3 (esterno): ancora più tollerante perché ha velocità base maggiore
        let currentSpeed = sqrt(playerBody.velocity.dx * playerBody.velocity.dx + 
                               playerBody.velocity.dy * playerBody.velocity.dy)
        
        // Velocità massima per aggancio - Ring 3 è il più veloce (sia ellisse che cerchio)
        let maxSpeedForGrapple: CGFloat
        if closestRing == 3 {
            maxSpeedForGrapple = 600  // Ring 3: molto tollerante (ellisse o cerchio)
        } else if isClosestEllipse {
            maxSpeedForGrapple = 400  // Ring 1-2 ellisse: tollerante
        } else {
            maxSpeedForGrapple = 150  // Ring 1-2 cerchi: normale
        }
        
        // Threshold diversi per ellissi vs cerchi
        // Ring 3 ha threshold maggiorati anche per i cerchi (più distante = più tolleranza)
        let grappleMultiplier: CGFloat
        let detachMultiplier: CGFloat
        
        if closestRing == 3 {
            // Ring 3: bonus per entrambi i tipi (ellisse e cerchio)
            grappleMultiplier = isClosestEllipse ? 2.0 : 1.8
            detachMultiplier = isClosestEllipse ? 3.0 : 2.5
        } else if isClosestEllipse {
            // Ring 1-2 ellisse
            grappleMultiplier = 1.5
            detachMultiplier = 2.0
        } else {
            // Ring 1-2 cerchi
            grappleMultiplier = 1.0
            detachMultiplier = 1.0
        }
        
        let grappleThreshold = orbitalGrappleThreshold * grappleMultiplier
        let detachThreshold = orbitalDetachThreshold * detachMultiplier
        let effectiveThreshold = isGrappledToOrbit ? detachThreshold : grappleThreshold
        
        // COOLDOWN: previeni ri-aggancio immediato dopo sgancio
        if justDetachedFromOrbit {
            detachCooldownFrames -= 1
            if detachCooldownFrames <= 0 {
                justDetachedFromOrbit = false
                detachCooldownFrames = 0
            }
            // Durante cooldown, NON permettere nuovo aggancio
            debugLog("⏱️ Detach cooldown: \(detachCooldownFrames) frames remaining")
        }
        
        if distanceFromRing < effectiveThreshold && currentSpeed < maxSpeedForGrapple && !justDetachedFromOrbit {
            if !isGrappledToOrbit || currentOrbitalRing != closestRing {
                isGrappledToOrbit = true
                currentOrbitalRing = closestRing
                let isEllipse = (closestRing == 1 && orbitalRing1IsEllipse) ||
                               (closestRing == 2 && orbitalRing2IsEllipse) ||
                               (closestRing == 3 && orbitalRing3IsEllipse)
                debugLog("🔗 Grappling to orbital ring \(closestRing), isEllipse: \(isEllipse), distance: \(Int(distanceFromRing))")
            }
            
            // Controlla se il giocatore sta spingendo forte (tentativo di sgancio)
            let thrustMagnitude = sqrt(joystickDirection.dx * joystickDirection.dx + joystickDirection.dy * joystickDirection.dy)
            let isThrusting = thrustMagnitude > 0.25
            
            // Aumenta gradualmente la forza di aggancio solo se NON sta spingendo
            if !isThrusting {
                // Normalizza rispetto alla soglia corrente
                let normalizedDistance = min(1.0, distanceFromRing / orbitalGrappleThreshold)
                let targetStrength: CGFloat = 1.0 - normalizedDistance
                let transitionSpeed: CGFloat = 0.05  // Ridotto da 0.08 - aggancio più lento
                orbitalGrappleStrength += (targetStrength - orbitalGrappleStrength) * transitionSpeed
            }
            // Se sta spingendo, l'aggancio non si rafforza (si indebolisce solo nella sezione sgancio manuale)
            
            // Feedback visivo graduale - solo sull'anello corrente
            let visualAlpha = 0.25 + (0.35 * orbitalGrappleStrength)  // Da 0.25 a 0.6
            let visualWidth = 1.0 + (1.0 * orbitalGrappleStrength)    // Da 1 a 2
            closestRingNode?.strokeColor = UIColor.cyan.withAlphaComponent(visualAlpha)
            closestRingNode?.lineWidth = visualWidth
            
            // Ripristina gli altri anelli (con safe unwrapping)
            if closestRing != 1, let ring1 = orbitalRing1 {
                ring1.strokeColor = UIColor.white.withAlphaComponent(0.25)
                ring1.lineWidth = 1
            }
            if closestRing != 2, let ring2 = orbitalRing2 {
                ring2.strokeColor = UIColor.white.withAlphaComponent(0.25)
                ring2.lineWidth = 1
            }
            if closestRing != 3, let ring3 = orbitalRing3 {
                ring3.strokeColor = UIColor.white.withAlphaComponent(0.25)
                ring3.lineWidth = 1
            }
            
        } else if isGrappledToOrbit {
            // Oltre la soglia di sgancio: diminuisci la forza gradualmente
            orbitalGrappleStrength -= 0.05
            
            debugLog("⚠️ Distance \(Int(distanceFromRing)) > threshold \(Int(orbitalDetachThreshold)), reducing grapple strength to \(String(format: "%.2f", orbitalGrappleStrength))")
            
            if orbitalGrappleStrength <= 0 {
                // Sgancio completo - CONSERVA la velocità orbitale + APPLICA velocità corrente
                guard let playerBody = player.physicsBody else { return }
                
                // COMBINA velocità orbitale + velocità corrente (per conservazione momentum completo)
                let finalVelocity = CGVector(
                    dx: lastOrbitalVelocity.dx + playerBody.velocity.dx * 0.3,
                    dy: lastOrbitalVelocity.dy + playerBody.velocity.dy * 0.3
                )
                playerBody.velocity = finalVelocity
                
                isGrappledToOrbit = false
                orbitalGrappleStrength = 0
                currentOrbitalRing = 0
                justDetachedFromOrbit = true      // Attiva cooldown
                detachCooldownFrames = 30         // 0.5 secondi di cooldown
                radialThrustAccumulator = 0.0     // Reset accumulo
                lastOrbitalVelocity = .zero
                
                // Ripristina tutti gli anelli (con safe unwrapping)
                orbitalRing1?.strokeColor = UIColor.white.withAlphaComponent(0.25)
                orbitalRing1?.lineWidth = 1
                orbitalRing2?.strokeColor = UIColor.white.withAlphaComponent(0.25)
                orbitalRing2?.lineWidth = 1
                orbitalRing3?.strokeColor = UIColor.white.withAlphaComponent(0.25)
                orbitalRing3?.lineWidth = 1
                
                debugLog("🔓 Detached from orbital ring (distance) - velocity conserved: \(lastOrbitalVelocity)")
                return
            }
        }
        
        // SGANCIO MANUALE: ACCUMULO GRADUALE per dare "attrito" e permettere manovre tangenziali
        if isGrappledToOrbit && orbitalGrappleStrength > 0.2 {
            let thrustDirection = joystickDirection
            let forceMagnitude = sqrt(thrustDirection.dx * thrustDirection.dx + thrustDirection.dy * thrustDirection.dy)
            
            // Normalizza direzione player rispetto al centro
            let playerAngle = atan2(dy, dx)
            let radialX = cos(playerAngle)  // Direzione verso esterno
            let radialY = sin(playerAngle)
            
            // Proiezione dot product: quanto la spinta è allineata con direzione radiale
            let thrustNormX = thrustDirection.dx / max(forceMagnitude, 0.001)  // Evita divisione per zero
            let thrustNormY = thrustDirection.dy / max(forceMagnitude, 0.001)
            let radialAlignment = abs(thrustNormX * radialX + thrustNormY * radialY)
            
            // SOGLIE PIÙ ALTE per più "attrito":
            // - Serve GAS MASSIMO (95%+)
            // - Serve allineamento radiale MOLTO forte (80%+)
            let minForce: CGFloat = 0.95       // Era 0.85 - ora serve gas quasi pieno
            let minAlignment: CGFloat = 0.80   // Era 0.65 - ora serve allineamento molto preciso
            
            if forceMagnitude > minForce && radialAlignment > minAlignment {
                // ACCUMULO GRADUALE: la spinta deve essere sostenuta per sganciarsi
                radialThrustAccumulator += 0.02  // Accumula gradualmente (serve ~25 frame = 0.4s di spinta sostenuta)
                
                if radialThrustAccumulator > 0.5 {
                    // SOGLIA ACCUMULO RAGGIUNTA: inizia sgancio veloce
                    orbitalGrappleStrength -= 0.4  // Sgancio rapido ma non istantaneo
                    
                    debugLog("⚡ Radial thrust accumulated: \(String(format: "%.2f", radialThrustAccumulator)) - detaching! (strength: \(String(format: "%.2f", orbitalGrappleStrength)))")
                    
                    if orbitalGrappleStrength <= 0 {
                        // Sgancio manuale - BOOST nella direzione della spinta!
                        
                        // Calcola boost direzionale: velocità orbitale + spinta joystick amplificata
                        let thrustBoost: CGFloat = 150.0  // Boost significativo
                        let boostedVelocity = CGVector(
                            dx: lastOrbitalVelocity.dx + thrustDirection.dx * thrustBoost,
                            dy: lastOrbitalVelocity.dy + thrustDirection.dy * thrustBoost
                        )
                        
                        playerBody.velocity = boostedVelocity
                        
                        isGrappledToOrbit = false
                        orbitalGrappleStrength = 0
                        currentOrbitalRing = 0
                        justDetachedFromOrbit = true      // Attiva cooldown
                        detachCooldownFrames = 30         // 0.5 secondi di cooldown
                        radialThrustAccumulator = 0.0     // Reset accumulo
                        
                        let detachSpeed = sqrt(boostedVelocity.dx * boostedVelocity.dx + 
                                              boostedVelocity.dy * boostedVelocity.dy)
                        lastOrbitalVelocity = .zero
                        
                        // Ripristina tutti gli anelli (con safe unwrapping)
                        orbitalRing1?.strokeColor = UIColor.white.withAlphaComponent(0.25)
                        orbitalRing1?.lineWidth = 1
                        orbitalRing2?.strokeColor = UIColor.white.withAlphaComponent(0.25)
                        orbitalRing2?.lineWidth = 1
                        orbitalRing3?.strokeColor = UIColor.white.withAlphaComponent(0.25)
                        orbitalRing3?.lineWidth = 1
                        
                        debugLog("🔓 Detached from orbital ring (radial thrust sustained) - velocity: \(Int(detachSpeed)), accumulator: reset")
                        return
                    }
                } else {
                    // Accumulo in corso ma non ancora alla soglia
                    debugLog("🔄 Accumulating radial thrust: \(String(format: "%.2f", radialThrustAccumulator))/0.5 (force: \(String(format: "%.2f", forceMagnitude)), align: \(String(format: "%.2f", radialAlignment)))")
                }
            } else {
                // NON stai spingendo abbastanza radialmente: DECADI l'accumulo rapidamente
                if radialThrustAccumulator > 0 {
                    radialThrustAccumulator -= 0.05  // Decade 2.5x più veloce di quanto accumula
                    if radialThrustAccumulator < 0 {
                        radialThrustAccumulator = 0
                    }
                    debugLog("⬇️ Radial thrust decay: \(String(format: "%.2f", radialThrustAccumulator)) (insufficient force/alignment)")
                }
            }
        } else if !isGrappledToOrbit {
            // Non agganciato: reset accumulo
            radialThrustAccumulator = 0.0
        }
        
        // APPLICA EFFETTO ORBITALE (se c'è aggancio)
        if isGrappledToOrbit && orbitalGrappleStrength > 0 {
            // Calcola l'angolo attuale del player rispetto al centro
            let currentAngle = atan2(dy, dx)
            
            // Determina se l'anello corrente è un'ellisse
            let isEllipseRing = (closestRing == 1 && orbitalRing1IsEllipse) ||
                               (closestRing == 2 && orbitalRing2IsEllipse) ||
                               (closestRing == 3 && orbitalRing3IsEllipse)
            
            // Calcola il moltiplicatore di velocità basato sulla posizione sull'ellisse
            let speedMultiplier = getEllipseSpeedMultiplier(angle: currentAngle, baseRadius: closestRingRadius, isEllipse: isEllipseRing)
            
            // Incrementa l'angolo in base alla velocità angolare dell'anello corrente, forza di aggancio e moltiplicatore ellittico
            let angularSpeed = closestRingVelocity * CGFloat(1.0/60.0) * orbitalGrappleStrength * speedMultiplier
            let newAngle = currentAngle + angularSpeed
            
            // Posizione target - per ellisse usa la formula parametrica
            var targetX: CGFloat
            var targetY: CGFloat
            
            if isEllipseRing {
                // Per ellisse: usa formula parametrica
                let a = closestRingRadius * ellipseRatio  // semiasse maggiore (orizzontale)
                let b = closestRingRadius                  // semiasse minore (verticale)
                targetX = planetCenter.x + cos(newAngle) * a
                targetY = planetCenter.y + sin(newAngle) * b
                
                // Debug per vedere se sta usando la formula ellisse
                if orbitalGrappleStrength > 0.5 {
                    debugLog("🔵 Ellipse grapple: ring \(closestRing), angle \(Int(newAngle * 180 / .pi))°, a=\(Int(a)), b=\(Int(b))")
                }
            } else {
                // Per cerchio: usa circonferenza normale
                targetX = planetCenter.x + cos(newAngle) * closestRingRadius
                targetY = planetCenter.y + sin(newAngle) * closestRingRadius
            }
            
            if isEllipseRing {
                // APPROCCIO B: Rail following con algoritmo Newton-Raphson preciso
                let a = closestRingRadius * ellipseRatio  // semiasse maggiore
                let b = closestRingRadius                  // semiasse minore
                
                // 1. Trova punto più vicino sull'ellisse con algoritmo preciso
                let (_, theta) = closestPointOnEllipse(
                    point: player.position,
                    center: planetCenter,
                    baseRadius: closestRingRadius,
                    isEllipse: true
                )
                
                // 2. FORZA posizione esattamente sul binario ellittico
                let railX = planetCenter.x + a * cos(theta)
                let railY = planetCenter.y + b * sin(theta)
                player.position = CGPoint(x: railX, y: railY)
                
                // 3. Calcola velocità tangenziale esatta (derivata parametrica dell'ellisse)
                // Tangente: (-a*sin(θ), b*cos(θ))
                let tangentDx = -a * sin(theta)
                let tangentDy = b * cos(theta)
                let tangentLength = sqrt(tangentDx * tangentDx + tangentDy * tangentDy)
                
                let normalizedTangentDx = tangentDx / tangentLength
                let normalizedTangentDy = tangentDy / tangentLength
                
                // 4. Applica moltiplicatore di velocità (4x al perielio, 1x all'afelio)
                let speedMultiplier = getEllipseSpeedMultiplier(angle: theta, baseRadius: closestRingRadius, isEllipse: true)
                let baseSpeed = closestRingVelocity * closestRingRadius
                let finalSpeed = baseSpeed * speedMultiplier
                
                // Debug: mostra velocità corrente
                let currentSpeed = sqrt(playerBody.velocity.dx * playerBody.velocity.dx + playerBody.velocity.dy * playerBody.velocity.dy)
                if Int(theta * 180 / .pi) % 30 == 0 {  // Log ogni 30 gradi
                    debugLog("🔵 Ellipse: θ=\(Int(theta * 180 / .pi))°, mult=\(String(format: "%.2f", speedMultiplier)), speed=\(Int(finalSpeed)) (was \(Int(currentSpeed)))")
                }
                
                // 5. Imposta velocità tangenziale diretta (no mixing, no grapple strength!)
                let tangentialVx = normalizedTangentDx * finalSpeed
                let tangentialVy = normalizedTangentDy * finalSpeed
                
                playerBody.velocity = CGVector(dx: tangentialVx, dy: tangentialVy)
                
                // 6. MEMORIZZA velocità per conservazione del moto allo sgancio
                lastOrbitalVelocity = CGVector(dx: tangentialVx, dy: tangentialVy)
                
                // 7. Blocca rotazione per movimento fluido
                playerBody.angularVelocity = 0
                playerBody.angularDamping = 0
                playerBody.linearDamping = 0
                
                return  // Skip resto del codice (cerchi)
            }
            
            // CERCHI: sistema originale
            let effectiveRadius = closestRingRadius
            let tangentialVelocity = closestRingVelocity * effectiveRadius
            let tangentialVx = -sin(newAngle) * tangentialVelocity
            let tangentialVy = cos(newAngle) * tangentialVelocity
            
            // MEMORIZZA la velocità orbitale pura per conservazione del moto allo sgancio
            lastOrbitalVelocity = CGVector(dx: tangentialVx, dy: tangentialVy)
            
            let currentX = player.position.x
            let currentY = player.position.y
            let positionInterpolation = orbitalGrappleStrength * 0.15
            let newX = currentX + (targetX - currentX) * positionInterpolation
            let newY = currentY + (targetY - currentY) * positionInterpolation
            
            player.position = CGPoint(x: newX, y: newY)
            
            // Mescola velocità per cerchi
            let currentVx = playerBody.velocity.dx
            let currentVy = playerBody.velocity.dy
            let mixedVx = currentVx + (tangentialVx - currentVx) * orbitalGrappleStrength * 0.15
            let mixedVy = currentVy + (tangentialVy - currentVy) * orbitalGrappleStrength * 0.15
            
            // LIMITA la velocità del player durante l'aggancio
            // Per ellissi, aumenta il limite proporzionalmente al moltiplicatore di velocità
            let maxOrbitalSpeed = tangentialVelocity * (isEllipseRing ? 1.0 : 0.85)
            let currentSpeed = sqrt(mixedVx * mixedVx + mixedVy * mixedVy)
            
            if currentSpeed > maxOrbitalSpeed {
                // Cap alla velocità massima dell'anello
                let scale = maxOrbitalSpeed / currentSpeed
                playerBody.velocity = CGVector(
                    dx: mixedVx * scale,
                    dy: mixedVy * scale
                )
            } else {
                playerBody.velocity = CGVector(
                    dx: mixedVx,
                    dy: mixedVy
                )
            }
        }
    }
    
    // MARK: - Wave System
    
    // Configura la wave specifica
    private func configureWave(_ wave: Int) -> WaveConfig {
        switch wave {
        case 1:
            // WAVE 1 - Solo meteoriti normali (facile)
            return WaveConfig(
                waveNumber: 1,
                asteroidSpawns: [
                    (.normal(.large), 8),      // 8 normali
                    (.normal(.medium), 2)      // 2 medium
                ],
                spawnInterval: 3.0
            )
            
        case 2:
            // WAVE 2 - Introduzione varietà (70% normali, 30% difficili)
            return WaveConfig(
                waveNumber: 2,
                asteroidSpawns: [
                    (.normal(.large), 5),      // 50%
                    (.normal(.medium), 2),     // 20%
                    (.fast(.large), 1),        // 10%
                    (.heavy(.large), 1),       // 10%
                    (.armored(.large), 1)      // 10%
                ],
                spawnInterval: 2.8
            )
            
        case 3:
            // WAVE 3 - Introduzione SQUARE (50% normali, 50% difficili)
            return WaveConfig(
                waveNumber: 3,
                asteroidSpawns: [
                    (.normal(.large), 4),      // 30%
                    (.normal(.medium), 2),     // 15%
                    (.fast(.large), 2),        // 15%
                    (.heavy(.large), 2),       // 15%
                    (.armored(.large), 2),     // 15%
                    (.square(.large), 2)       // 15% - SQUARE introdotti
                ],
                spawnInterval: 2.5
            )
            
        case 4:
            // WAVE 4 - Introduzione REPULSOR (40% normali, 60% difficili)
            return WaveConfig(
                waveNumber: 4,
                asteroidSpawns: [
                    (.normal(.large), 3),      // 23%
                    (.normal(.medium), 1),     // 8%
                    (.fast(.large), 2),        // 15%
                    (.heavy(.large), 2),       // 15%
                    (.armored(.large), 2),     // 15%
                    (.square(.large), 2),      // 15%
                    (.repulsor(.large), 2)     // 15% - REPULSOR introdotti
                ],
                spawnInterval: 2.3
            )
            
        case 5:
            // WAVE 5 - Bilanciamento (30% normali, 70% difficili)
            return WaveConfig(
                waveNumber: 5,
                asteroidSpawns: [
                    (.normal(.large), 2),      // 15%
                    (.normal(.medium), 2),     // 15%
                    (.fast(.large), 2),        // 15%
                    (.heavy(.large), 2),       // 15%
                    (.armored(.large), 2),     // 15%
                    (.square(.large), 3),      // 20%
                    (.repulsor(.large), 2)     // 15%
                ],
                spawnInterval: 2.0
            )
            
        case 6:
            // WAVE 6 - Difficoltà crescente (20% normali, 80% difficili)
            return WaveConfig(
                waveNumber: 6,
                asteroidSpawns: [
                    (.normal(.large), 1),      // 7%
                    (.normal(.medium), 2),     // 13%
                    (.fast(.large), 2),        // 13%
                    (.heavy(.large), 3),       // 20%
                    (.armored(.large), 3),     // 20%
                    (.square(.large), 2),      // 13%
                    (.repulsor(.large), 2)     // 13%
                ],
                spawnInterval: 1.8
            )
            
        case 7:
            // WAVE 7 - Molto difficile (10% normali, 90% difficili)
            return WaveConfig(
                waveNumber: 7,
                asteroidSpawns: [
                    (.normal(.medium), 1),     // 7%
                    (.fast(.large), 2),        // 13%
                    (.heavy(.large), 3),       // 20%
                    (.armored(.large), 3),     // 20%
                    (.square(.large), 3),      // 20%
                    (.repulsor(.large), 3)     // 20%
                ],
                spawnInterval: 1.6
            )
            
        case 8:
            // WAVE 8 - Inferno (0% normali, 100% difficili)
            return WaveConfig(
                waveNumber: 8,
                asteroidSpawns: [
                    (.fast(.large), 2),        // 13%
                    (.heavy(.large), 4),       // 27%
                    (.armored(.large), 3),     // 20%
                    (.square(.large), 3),      // 20%
                    (.repulsor(.large), 3)     // 20%
                ],
                spawnInterval: 1.5
            )
            
        default:
            // WAVE 9+ - Solo difficili, mix variabile
            return WaveConfig(
                waveNumber: wave,
                asteroidSpawns: [
                    (.fast(.large), 2),
                    (.heavy(.large), 4),
                    (.armored(.large), 3),
                    (.square(.large), 3),
                    (.repulsor(.large), 3)
                ],
                spawnInterval: max(1.2, 2.0 - CGFloat(wave - 8) * 0.1)
            )
        }
    }
    
    private func startWave(_ wave: Int) {
        currentWave = wave
        isWaveActive = false  // Disattiva il gioco durante il messaggio
        
        // Reset debris cleanup per il nuovo wave
        debrisCleanupActive = false
        
        // Aggiorna il wave label in alto
        waveLabel.text = "WAVE \(wave)"
        
        // Aumenta la gravità degli asteroidi del 5% per ogni wave (dopo la prima)
        if wave > 1 {
            asteroidGravityMultiplier *= 1.05
            debugLog("🌍 Asteroid gravity increased to \(asteroidGravityMultiplier) for wave \(wave)")
        }
        
        // Cambia ambiente spaziale in sequenza progressiva (convenzionale → wow)
        // Sequenza: deepSpace → nebula → voidSpace → redGiant → asteroidBelt → binaryStars → ionStorm
        let environments: [SpaceEnvironment] = [.deepSpace, .nebula, .voidSpace, .redGiant, .asteroidBelt, .binaryStars, .ionStorm]
        let environmentIndex = (wave - 1) % environments.count
        let newEnvironment = environments[environmentIndex]
        if newEnvironment != currentEnvironment {
            applyEnvironment(newEnvironment)
            debugLog("🌌 Environment changed to: \(newEnvironment.name)")
        }
        
        // Aggiorna gli anelli orbitali in base alla wave corrente
        updateOrbitalRingsForWave()
        
        // Avvia la musica per questa wave con crossfade
        // Randomizza tra tutte le tracce disponibili
        let musicFiles = ["wave1", "wave2", "wave3", "temp4a", "temp4b", "temp4c", "temp4d"]
        let musicFile = musicFiles.randomElement() ?? "wave1"
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
        
        // SPAWN INIZIALE RAPIDO: primi 5 asteroidi spawn immediato (0.3s tra uno e l'altro)
        // Poi variabilità: intervallo base ± 30%
        let baseInterval = currentWaveConfig?.spawnInterval ?? asteroidSpawnInterval
        var spawnInterval: TimeInterval
        
        if asteroidsSpawnedInWave < 5 {
            // Primi 5: spawn velocissimo (0.3 secondi)
            spawnInterval = 0.3
        } else {
            // Dopo i primi 5: intervallo base con variabilità ±30%
            let variation = Double.random(in: -0.3...0.3)
            spawnInterval = baseInterval * (1.0 + variation)
        }
        
        guard currentTime - lastAsteroidSpawnTime > spawnInterval else { return }
        lastAsteroidSpawnTime = currentTime
        
        // Prendi il prossimo tipo dalla coda
        let asteroidType = asteroidSpawnQueue.removeFirst()
        
        // Spawna l'asteroide con il tipo specificato
        spawnAsteroid(type: asteroidType, at: nil)
        asteroidsSpawnedInWave += 1
        
        debugLog("☄️ Spawned \(asteroidType) asteroid \(asteroidsSpawnedInWave)/\(asteroidsToSpawnInWave) - interval: \(String(format: "%.2f", spawnInterval))s")
    }
    
    private func checkWaveComplete() {
        // Controlla se la wave è completa
        guard isWaveActive else { return }
        guard asteroidsSpawnedInWave >= asteroidsToSpawnInWave else { return }
        guard asteroids.isEmpty else { return }
        
        // Wave completata! Ripristina la salute del pianeta E l'atmosfera
        debugLog("🎉 Wave \(currentWave) completed!")
        
        // Ripristina la salute del pianeta al massimo
        planetHealth = maxPlanetHealth
        updatePlanetHealthLabel()
        debugLog("💚 Planet health restored to \(maxPlanetHealth)")
        
        // Ripristina l'atmosfera al massimo
        atmosphereRadius = maxAtmosphereRadius
        atmosphere.alpha = 1.0  // Rendi visibile se era invisibile
        updateAtmosphereVisuals()
        debugLog("🌀 Atmosphere fully restored to \(maxAtmosphereRadius)")
        
        startWave(currentWave + 1)
    }
    
    // MARK: - Asteroid Management
    
    // Overload per spawnar asteroidi con tipo specifico
    private func spawnAsteroid(type asteroidType: AsteroidType, at position: CGPoint?) {
        let asteroidSize = asteroidType.size
        
        // Crea forma in base al tipo
        let asteroid: SKShapeNode
        if case .square = asteroidType {
            // QUADRATO pieno per square asteroids
            let sideLength = asteroidSize.radius * 2.0  // Usa diameter come lato
            asteroid = SKShapeNode(rectOf: CGSize(width: sideLength, height: sideLength))
            asteroid.fillColor = asteroidType.color  // Pieno arancione
            asteroid.strokeColor = UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)  // Bordo più chiaro
        } else if case .repulsor = asteroidType {
            // SFERA piena viola per repulsor asteroids
            asteroid = SKShapeNode(circleOfRadius: asteroidSize.radius)
            asteroid.fillColor = asteroidType.color  // Pieno viola
            asteroid.strokeColor = UIColor(red: 0.9, green: 0.6, blue: 1.0, alpha: 1.0)  // Bordo viola chiaro
            asteroid.glowWidth = 3.0  // Glow viola
        } else {
            // Forma a linee spezzate (stile Asteroids) per gli altri
            let path = createAsteroidPath(radius: asteroidSize.radius)
            asteroid = SKShapeNode(path: path)
            asteroid.fillColor = .clear
            asteroid.strokeColor = asteroidType.color
        }
        asteroid.lineWidth = asteroidType.lineWidth
        asteroid.zPosition = 5
        asteroid.name = "asteroid_\(asteroidSize.rawValue)"
        
        // Salva il tipo e la vita nell'userData
        asteroid.userData = NSMutableDictionary()
        asteroid.userData?["type"] = asteroidType
        asteroid.userData?["health"] = asteroidType.healthMultiplier
        asteroid.userData?["size"] = asteroidSize.rawValue
        // Slingshot state
        asteroid.userData?["inSlingshot"] = false
        asteroid.userData?["slingshotRing"] = 0         // 0 = libero, 1-3 = anello catturato
        asteroid.userData?["slingshotOrbits"] = 0       // Numero di giri completati
        asteroid.userData?["slingshotStartAngle"] = CGFloat(0.0)  // Angolo iniziale cattura
        asteroid.userData?["slingshotTargetRadius"] = CGFloat(0.0)  // Raggio target attuale
        
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
        
        // Physics body - rettangolare per square, circolare per gli altri
        // OTTIMIZZAZIONE: Per detriti small, usa physics body più semplice
        if case .square = asteroidType {
            let sideLength = asteroidSize.radius * 2.0
            asteroid.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: sideLength, height: sideLength))
        } else {
            asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroidSize.radius)
        }
        asteroid.physicsBody?.isDynamic = true
        asteroid.physicsBody?.mass = asteroidSize.mass
        asteroid.physicsBody?.linearDamping = 0
        asteroid.physicsBody?.angularDamping = 0
        
        // OTTIMIZZAZIONE: Per detriti small, riduci la precisione fisica
        if asteroidSize == .small {
            asteroid.physicsBody?.usesPreciseCollisionDetection = false  // Meno preciso ma più veloce
        }
        
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
        
        // Se è square, programma cambi di direzione random + effetto metallico
        if case .square = asteroidType {
            scheduleSquareAsteroidJets(for: asteroid)
            addMetallicShineEffect(to: asteroid)
        }
        
        // Se è repulsor, aggiungi particelle orbitanti viola
        if case .repulsor = asteroidType {
            addRepulsorParticles(to: asteroid, radius: asteroidSize.radius)
        }
        
        // NON creiamo più l'indicatore di grapple (anello)
        // Gli asteroidi ruoteranno quando agganciati per maggior realismo
        
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
    
    // MARK: - Square Asteroid Jet System
    
    private func scheduleSquareAsteroidJets(for asteroid: SKShapeNode) {
        let randomDelay = TimeInterval.random(in: Double(8)...Double(12))
        
        let wait = SKAction.wait(forDuration: randomDelay)
        let applyJet = SKAction.run { [weak self, weak asteroid] in
            guard let self = self, let asteroid = asteroid else { return }
            self.applySquareAsteroidJet(to: asteroid)
            
            // Riprogramma il prossimo jet
            self.scheduleSquareAsteroidJets(for: asteroid)
        }
        
        let sequence = SKAction.sequence([wait, applyJet])
        asteroid.run(sequence, withKey: "squareJet")
    }
    
    private func applySquareAsteroidJet(to asteroid: SKShapeNode) {
        guard let body = asteroid.physicsBody else { return }
        
        // Direzione casuale
        let angle = CGFloat.random(in: CGFloat(0)...(.pi * 2))
        
        // MODIFICA GRADUALE DELLA VELOCITÀ invece di impulso
        // Aggiungi velocità nella nuova direzione in modo smooth
        let jetSpeed: CGFloat = 80  // Velocità aggiunta (non forza)
        
        let currentVelocity = body.velocity
        let addedVelocity = CGVector(
            dx: cos(angle) * jetSpeed,
            dy: sin(angle) * jetSpeed
        )
        
        // Applica la nuova velocità in modo SMOOTH con animazione
        let newVelocity = CGVector(
            dx: currentVelocity.dx + addedVelocity.dx,
            dy: currentVelocity.dy + addedVelocity.dy
        )
        
        // Cambia velocità DIRETTAMENTE (no physics, no impulse)
        body.velocity = newVelocity
        
        // Effetto visivo: particelle nella direzione opposta
        createSquareJetParticles(at: asteroid, direction: angle + .pi)
    }
    
    private func createSquareJetParticles(at asteroid: SKShapeNode, direction: CGFloat) {
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
        emitter.position = .zero
        emitter.zPosition = -1
        emitter.targetNode = worldLayer
        
        asteroid.addChild(emitter)
        
        // Rimuovi dopo emissione
        let wait = SKAction.wait(forDuration: 1.0)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }
    
    // MARK: - Metallic Shine Effect
    
    private func addMetallicShineEffect(to asteroid: SKShapeNode) {
        // RIMUOVO il brutto glow pulse
        // Uso solo un effetto shimmer sottile + brightness pulse
        scheduleMetallicShine(for: asteroid)
    }
    
    private func scheduleMetallicShine(for asteroid: SKShapeNode) {
        let randomDelay = TimeInterval.random(in: 2.0...3.5)
        
        let wait = SKAction.wait(forDuration: randomDelay)
        let shine = SKAction.run { [weak self, weak asteroid] in
            guard let self = self, let asteroid = asteroid else { return }
            self.createShineEffect(on: asteroid)
            
            // Riprogramma il prossimo shine
            self.scheduleMetallicShine(for: asteroid)
        }
        
        let sequence = SKAction.sequence([wait, shine])
        asteroid.run(sequence, withKey: "metallicShine")
    }
    
    private func createShineEffect(on asteroid: SKShapeNode) {
        guard let asteroidSize = asteroid.userData?["size"] as? Int,
              let size = AsteroidSize(rawValue: asteroidSize) else { return }
        
        let sideLength = size.radius * 2.0
        
        // EDGE HIGHLIGHTING: Bordi che si illuminano progressivamente
        // Simula luce che attraversa un oggetto 3D illuminando i suoi spigoli
        
        // Container per gli effetti
        let effectContainer = SKNode()
        effectContainer.zPosition = 2
        asteroid.addChild(effectContainer)
        
        // 1. BORDI LUMINOSI (4 linee che formano il quadrato)
        let edgeWidth: CGFloat = 3.0
        let edgeColor = UIColor.white
        
        // Bordo SINISTRO
        let leftEdge = SKShapeNode(rectOf: CGSize(width: edgeWidth, height: sideLength))
        leftEdge.fillColor = edgeColor
        leftEdge.strokeColor = .clear
        leftEdge.position = CGPoint(x: -sideLength / 2, y: 0)
        leftEdge.alpha = 0
        leftEdge.blendMode = .add
        effectContainer.addChild(leftEdge)
        
        // Bordo SUPERIORE
        let topEdge = SKShapeNode(rectOf: CGSize(width: sideLength, height: edgeWidth))
        topEdge.fillColor = edgeColor
        topEdge.strokeColor = .clear
        topEdge.position = CGPoint(x: 0, y: sideLength / 2)
        topEdge.alpha = 0
        topEdge.blendMode = .add
        effectContainer.addChild(topEdge)
        
        // Bordo DESTRO
        let rightEdge = SKShapeNode(rectOf: CGSize(width: edgeWidth, height: sideLength))
        rightEdge.fillColor = edgeColor
        rightEdge.strokeColor = .clear
        rightEdge.position = CGPoint(x: sideLength / 2, y: 0)
        rightEdge.alpha = 0
        rightEdge.blendMode = .add
        effectContainer.addChild(rightEdge)
        
        // Bordo INFERIORE
        let bottomEdge = SKShapeNode(rectOf: CGSize(width: sideLength, height: edgeWidth))
        bottomEdge.fillColor = edgeColor
        bottomEdge.strokeColor = .clear
        bottomEdge.position = CGPoint(x: 0, y: -sideLength / 2)
        bottomEdge.alpha = 0
        bottomEdge.blendMode = .add
        effectContainer.addChild(bottomEdge)
        
        // 2. SEQUENZA ANIMAZIONE
        let duration: TimeInterval = 0.7
        let edgeDelay: TimeInterval = 0.12
        
        // Illumina i bordi in sequenza (sinistra → alto → destra → basso)
        let illuminateLeft = SKAction.fadeAlpha(to: 0.9, duration: 0.15)
        leftEdge.run(SKAction.sequence([
            SKAction.wait(forDuration: 0),
            illuminateLeft
        ]))
        
        topEdge.run(SKAction.sequence([
            SKAction.wait(forDuration: edgeDelay),
            illuminateLeft
        ]))
        
        rightEdge.run(SKAction.sequence([
            SKAction.wait(forDuration: edgeDelay * 2),
            illuminateLeft
        ]))
        
        bottomEdge.run(SKAction.sequence([
            SKAction.wait(forDuration: edgeDelay * 3),
            illuminateLeft
        ]))
        
        // Fade out tutti i bordi insieme
        let fadeOutDelay = edgeDelay * 3 + 0.3
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: fadeOutDelay),
            SKAction.fadeOut(withDuration: 0.2)
        ])
        leftEdge.run(fadeOut)
        topEdge.run(fadeOut)
        rightEdge.run(fadeOut)
        bottomEdge.run(fadeOut)
        
        // 4. Brightness pulse sul cubo stesso
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
        
        // 5. Cleanup
        let cleanup = SKAction.sequence([
            SKAction.wait(forDuration: duration + 0.3),
            SKAction.removeFromParent()
        ])
        effectContainer.run(cleanup)
    }
    
    private func addRepulsorParticles(to asteroid: SKShapeNode, radius: CGFloat) {
        // Sistema particellare che orbita attorno all'asteroide
        let particles = SKEmitterNode()
        particles.particleTexture = particleTexture
        particles.position = CGPoint.zero  // Centro dell'asteroide
        
        // Emissione continua in cerchio attorno all'asteroide
        particles.particleBirthRate = 30
        particles.numParticlesToEmit = 0  // Continuo
        
        // Dimensione particelle
        particles.particleSize = CGSize(width: 4, height: 4)
        particles.particleScale = 0.6
        particles.particleScaleRange = 0.3
        particles.particleScaleSpeed = -0.3
        
        // Colore viola luminoso
        particles.particleColor = UIColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1.0)
        particles.particleColorBlendFactor = 1.0
        
        // Emissione circolare uniforme
        particles.emissionAngle = 0
        particles.emissionAngleRange = .pi * 2
        
        // Velocità: orbita attorno all'asteroide
        particles.particleSpeed = 0  // Non si allontanano subito
        particles.particleSpeedRange = 0
        
        // Vita delle particelle
        particles.particleLifetime = 2.0
        particles.particleLifetimeRange = 0.5
        
        // Alpha
        particles.particleAlpha = 0.8
        particles.particleAlphaSpeed = -0.4
        
        // Posizione di spawn: sulla circonferenza dell'asteroide
        particles.particlePositionRange = CGVector(dx: radius * 2.2, dy: radius * 2.2)
        
        // Blend mode per effetto luminoso
        particles.particleBlendMode = .add
        particles.particleZPosition = -1
        
        // CRUCIALE: Le particelle rimangono nel sistema locale dell'asteroide
        // così orbitano con esso
        particles.name = "repulsorParticles"
        
        asteroid.addChild(particles)
        
        // Animazione di rotazione continua delle particelle per simulare orbita
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 3.0)
        particles.run(SKAction.repeatForever(rotate))
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
        starsLayer1?.position = CGPoint(
            x: centerX - offsetX * 0.1,
            y: centerY - offsetY * 0.1
        )
        
        // Layer 2: Stelle medie - movimento medio (20% della camera)
        starsLayer2?.position = CGPoint(
            x: centerX - offsetX * 0.2,
            y: centerY - offsetY * 0.2
        )
        
        // Layer 3: Stelle più vicine - movimento veloce (35% della camera)
        starsLayer3?.position = CGPoint(
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
        
        // Projectile + Atmosphere - Comportamento originale
        else if collision == (PhysicsCategory.projectile | PhysicsCategory.atmosphere) {
            let projectileBody = contact.bodyA.categoryBitMask == PhysicsCategory.projectile ? contact.bodyA : contact.bodyB
            
            if let projectile = projectileBody.node {
                // Particelle all'impatto
                createCollisionParticles(at: contact.contactPoint, color: .cyan)
                
                // Ricarica atmosfera leggermente
                rechargeAtmosphere(amount: 1.05)
                flashAtmosphere()
                
                // Rimuovi proiettile
                projectile.removeFromParent()
                
                debugLog("🛡️ Projectile stopped by atmosphere")
            }
        }
        
        // Asteroid + Atmosphere
        else if collision == (PhysicsCategory.asteroid | PhysicsCategory.atmosphere) {
            handleAsteroidAtmosphereBounce(contact: contact)
            
            // Identifica l'asteroide
            let asteroidBody = contact.bodyA.categoryBitMask == PhysicsCategory.asteroid ? contact.bodyA : contact.bodyB
            let asteroid = asteroidBody.node as? SKShapeNode
            
            // Calcola danno basato sul tipo di asteroide
            var damageAmount: CGFloat = 1.96  // Danno base ridotto ulteriormente (2.3 * 0.85 = 1.955 ≈ 1.96)
            
            if let asteroidNode = asteroid,
               let asteroidType = asteroidNode.userData?["type"] as? AsteroidType {
                damageAmount *= asteroidType.atmosphereDamageMultiplier
            }
            
            damageAtmosphere(amount: damageAmount)
            flashAtmosphere()
            
            // NUOVO: L'asteroide subisce danno come se fosse colpito da un proiettile
            // MA NON VENGONO ASSEGNATI PUNTI (givePoints: false)
            if let asteroid = asteroid {
                fragmentAsteroid(asteroid, damageMultiplier: 1.0, givePoints: false)
            }
            
            // Effetto particellare al punto di contatto con colore random
            createCollisionParticles(at: contact.contactPoint, color: randomExplosionColor())
            
            debugLog("☄️ Asteroid hit atmosphere - bounce + \(damageAmount) atmosphere damage + fragment")
        }
        
        // Asteroid + Planet
        else if collision == (PhysicsCategory.asteroid | PhysicsCategory.planet) {
            // Identifica l'asteroide
            let asteroid = contact.bodyA.categoryBitMask == PhysicsCategory.asteroid ? 
                          contact.bodyA.node as? SKShapeNode : 
                          contact.bodyB.node as? SKShapeNode
            
            // VIBRAZIONE: colpo sul pianeta (solo su iPhone, non su iPad)
            if UIDevice.current.userInterfaceIdiom == .phone {
                impactFeedback?.impactOccurred()
            }
            
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
                
                // NUOVO: L'asteroide subisce danno come se fosse colpito da un proiettile
                // Questo frammenta large/medium e distrugge small
                fragmentAsteroid(asteroid, damageMultiplier: 1.0)  // Danno da 1 colpo
                debugLog("💥 Asteroid hit planet - bounce + fragment damage")
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
            if let powerupNode = powerupBody.node, let powerupPhysics = powerupNode.physicsBody {
                // Rimbalzo sull'atmosfera (come per il pianeta)
                let dx = powerupNode.position.x - planet.position.x
                let dy = powerupNode.position.y - planet.position.y
                let distance = sqrt(dx * dx + dy * dy)
                
                guard distance > 0 else { return }
                
                let normalX = dx / distance
                let normalY = dy / distance
                
                let velocity = powerupPhysics.velocity
                let dotProduct = velocity.dx * normalX + velocity.dy * normalY
                
                guard dotProduct < 0 else { return }
                
                let reflectedVelocityX = velocity.dx - 2 * dotProduct * normalX
                let reflectedVelocityY = velocity.dy - 2 * dotProduct * normalY
                
                // Rimbalzo forte
                let bounceFactor: CGFloat = 6.5
                powerupPhysics.velocity = CGVector(
                    dx: reflectedVelocityX * bounceFactor,
                    dy: reflectedVelocityY * bounceFactor
                )
                
                // Flash leggero dell'atmosfera
                let originalAlpha = atmosphere.strokeColor.withAlphaComponent(0.6)
                atmosphere.strokeColor = .cyan
                let wait = SKAction.wait(forDuration: 0.05)
                let restore = SKAction.run { [weak self] in
                    self?.atmosphere.strokeColor = originalAlpha
                }
                atmosphere.run(SKAction.sequence([wait, restore]))
            }
            debugLog("✨ Power-up bounced off atmosphere")
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
                
                // Durante debris cleanup, aumenta il rimbalzo del 50%
                var bounceFactor: CGFloat = 6.5  // Rimbalzo MOLTO più forte per i power-up (aumentato del 30%)
                if debrisCleanupActive {
                    bounceFactor *= 1.5  // +50% durante cleanup
                }
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
            
            // Controlla se è un missile (esplosione ad area)
            let isMissile = projectile?.name == "missile"
            
            if isMissile {
                // ESPLOSIONE MISSILE: danno ad area (l'esplosione gestisce anche l'asteroide colpito)
                if let impactPoint = asteroid?.position {
                    createMissileExplosion(at: impactPoint, damageMultiplier: damageMultiplier)
                }
                // NON frammentare l'asteroide qui - lo fa l'esplosione con delay
            } else {
                // Proiettile normale: danno singolo
                if let asteroid = asteroid {
                    // Effetto particellare con colore random
                    createExplosionParticles(at: asteroid.position, color: randomExplosionColor())
                    fragmentAsteroid(asteroid, damageMultiplier: damageMultiplier)
                }
            }
            
            // Rimuovi il proiettile/missile
            projectile?.removeFromParent()
            
            debugLog("💥 \(isMissile ? "Missile" : "Projectile") hit asteroid (damage: \(damageMultiplier)x)")
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
        // Durante debris cleanup, aumenta il rimbalzo del 50%
        var bounceFactor: CGFloat = 1.3  // 30% più veloce dopo il rimbalzo
        if debrisCleanupActive {
            bounceFactor *= 1.5  // +50% durante cleanup
        }
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
        
        // Rimbalzo molto più forte per gli asteroidi - aumentato per evitare rimbalzi multipli
        // Durante debris cleanup, aumenta ulteriormente il rimbalzo
        var bounceFactor: CGFloat = 3.5  // Aumentato da 2.5 a 3.5 per rimbalzo più deciso
        if debrisCleanupActive {
            bounceFactor *= 2.0  // Durante cleanup (totale 7.0x)
        }
        asteroidBody.velocity = CGVector(
            dx: reflectedVelocityX * bounceFactor,
            dy: reflectedVelocityY * bounceFactor
        )
        
        // Sposta l'asteroide molto più lontano dall'atmosfera per evitare rimbalzi multipli
        let pushDistance: CGFloat = 25  // Aumentato da 10 a 25
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
        
        // Durante debris cleanup, aumenta ulteriormente il rimbalzo del 50%
        if debrisCleanupActive {
            bounceFactor *= 1.5  // +50% durante cleanup
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
    
    private func fragmentAsteroid(_ asteroid: SKShapeNode, damageMultiplier: CGFloat = 1.0, givePoints: Bool = true) {
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
            
            // Se è un quadrato, mostra anche effetto shine
            let isSquare = asteroid.name?.contains("square") ?? false
            if isSquare {
                createShineEffect(on: asteroid)
            }
            
            debugLog("💪 Armored asteroid hit! Health: \(newHealth)")
            return  // Non frammentare ancora
        }
        
        // Aggiungi punti SOLO se givePoints è true (non quando colpisce atmosfera)
        if givePoints {
            let basePoints: Int
            switch size {
            case .large: basePoints = 20
            case .medium: basePoints = 15
            case .small: basePoints = 10
            }
            
            // SQUARE asteroids valgono IL DOPPIO
            let isSquare = asteroid.name?.contains("square") ?? false
            let typeMultiplier: CGFloat = isSquare ? 2.0 : 1.0
            
            let points = Int(CGFloat(basePoints) * damageMultiplier * typeMultiplier)
            score += points
            scoreLabel.text = "\(score)"
            
            // Mostra label con i punti accanto all'asteroide
            showPointsLabel(points: points, at: asteroid.position)
        }
        
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
        
        // Suono esplosione
        playExplosionSound()
        
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
            
            // Determina il tipo dei frammenti (eredita da parent se heavy/armored/fast, square diventa normale)
            let fragmentType: AsteroidType
            let fragmentCount: Int
            
            if let parentType = asteroidType {
                switch parentType {
                case .heavy:
                    fragmentType = .heavy(nextSize)  // I frammenti heavy rimangono heavy
                    fragmentCount = Int.random(in: 2...3)
                case .armored:
                    fragmentType = .armored(nextSize)  // I frammenti armored rimangono armored
                    fragmentCount = Int.random(in: 2...3)
                case .fast:
                    fragmentType = .fast(nextSize)  // I frammenti fast rimangono fast
                    fragmentCount = Int.random(in: 2...3)
                case .square:
                    fragmentType = .square(nextSize)  // I frammenti square rimangono SQUARE
                    fragmentCount = 4  // SEMPRE 4 frammenti
                case .repulsor:
                    fragmentType = .repulsor(nextSize)  // I frammenti repulsor rimangono REPULSOR
                    fragmentCount = Int.random(in: 3...4)  // 3-4 frammenti repulsor
                default:
                    fragmentType = .normal(nextSize)  // Gli altri diventano normali
                    fragmentCount = Int.random(in: 2...3)
                }
            } else {
                fragmentType = .normal(nextSize)
                fragmentCount = Int.random(in: 2...3)
            }
            
            // OTTIMIZZAZIONE: Limita il numero di detriti small
            let smallDebrisCount = asteroids.filter { asteroid in
                if let sizeString = asteroid.name?.split(separator: "_").last,
                   let sizeRaw = Int(String(sizeString)),
                   let asteroidSize = AsteroidSize(rawValue: sizeRaw) {
                    return asteroidSize == .small
                }
                return false
            }.count
            
            // Se nextSize è small e abbiamo già troppi detriti, riduci i frammenti
            var actualFragmentCount = fragmentCount
            if nextSize == .small && smallDebrisCount >= maxSmallDebris {
                actualFragmentCount = max(1, fragmentCount - 1)  // Riduci di 1, minimo 1
                debugLog("⚠️ Debris limit reached (\(smallDebrisCount)/\(maxSmallDebris)), reducing fragments to \(actualFragmentCount)")
            }
            
            for i in 0..<actualFragmentCount {
                let angle = (CGFloat(i) / CGFloat(actualFragmentCount)) * 2 * .pi + CGFloat.random(in: -0.3...0.3)
                
                // Posizione offset dal centro
                let offset = CGPoint(
                    x: cos(angle) * size.radius * 0.5,
                    y: sin(angle) * size.radius * 0.5
                )
                
                let fragmentPosition = CGPoint(
                    x: position.x + offset.x,
                    y: position.y + offset.y
                )
                
                // OTTIMIZZAZIONE: Se siamo al limite, salta la creazione di detriti small
                if nextSize == .small && smallDebrisCount + i >= maxSmallDebris {
                    debugLog("⚠️ Skipping fragment creation - debris limit reached")
                    break
                }
                
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
        
        // Mostra label con i punti accanto all'asteroide
        showPointsLabel(points: points, at: asteroid.position)
        
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
            let fragmentCount: Int
            
            if let parentType = asteroidType {
                switch parentType {
                case .heavy:
                    fragmentType = .heavy(nextSize)  // Heavy rimane heavy
                    fragmentCount = 2
                case .armored:
                    fragmentType = .armored(nextSize)  // Armored rimane armored
                    fragmentCount = 2
                case .fast:
                    fragmentType = .fast(nextSize)  // Fast rimane fast
                    fragmentCount = 2
                case .square:
                    fragmentType = .square(nextSize)  // Square rimane SQUARE
                    fragmentCount = 4  // I quadrati fanno sempre 4 frammenti
                case .repulsor:
                    fragmentType = .repulsor(nextSize)  // Repulsor rimane REPULSOR
                    fragmentCount = 3  // 3 frammenti repulsor
                default:
                    fragmentType = .normal(nextSize)
                    fragmentCount = 2
                }
            } else {
                fragmentType = .normal(nextSize)
                fragmentCount = 2
            }
            
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
        
        // Coefficiente di restituzione (bounciness) - AUMENTATO per migliore rimbalzo giocatore
        var restitution: CGFloat = 0.8  // Aumentato da 0.7
        
        // Asteroidi più grandi hanno un rimbalzo ancora più forte
        if let asteroidName = asteroid.name {
            if asteroidName.contains("large") {
                restitution = 0.9  // Aumentato da 0.8
            } else if asteroidName.contains("medium") {
                restitution = 0.8  // Aumentato da 0.7
            } else if asteroidName.contains("small") {
                restitution = 0.7  // Aumentato da 0.6
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
    
    // MARK: - Points Label
    
    private func showPointsLabel(points: Int, at position: CGPoint) {
        // Crea label con i punti
        let pointsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        pointsLabel.text = "+\(points)"
        pointsLabel.fontSize = 24
        pointsLabel.fontColor = .yellow
        pointsLabel.position = position
        pointsLabel.zPosition = 1000
        pointsLabel.alpha = 0  // Inizia invisibile
        
        worldLayer.addChild(pointsLabel)
        
        // Animazione VELOCISSIMA: fade in + movimento su + fade out
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.05)  // 50ms fade in
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.2)  // Sale leggermente
        let wait = SKAction.wait(forDuration: 0.1)  // Resta visibile 100ms
        let fadeOut = SKAction.fadeOut(withDuration: 0.05)  // 50ms fade out
        let remove = SKAction.removeFromParent()
        
        // Fade in + movimento in parallelo
        let appear = SKAction.group([fadeIn, moveUp])
        let sequence = SKAction.sequence([appear, wait, fadeOut, remove])
        
        pointsLabel.run(sequence)
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
    
    private func createMissileExplosion(at position: CGPoint, damageMultiplier: CGFloat) {
        // Raggio esplosione: metà del raggio del pianeta
        let explosionRadius = planetRadius / 2.0
        
        // ESPLOSIONE SPETTACOLARE TIPO MINI-WAVE
        
        // 1. Nuvola di particelle MASSIVA (3 ondate successive)
        for waveIndex in 0..<3 {
            let delay = Double(waveIndex) * 0.08
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                let emitter = SKEmitterNode()
                emitter.position = position
                emitter.particleTexture = self.particleTexture
                emitter.particleBirthRate = 1200  // Molto denso
                emitter.numParticlesToEmit = 150  // Molte particelle
                emitter.particleLifetime = 1.5
                emitter.emissionAngle = 0
                emitter.emissionAngleRange = CGFloat.pi * 2
                emitter.particleSpeed = 180 + CGFloat(waveIndex * 40)  // Velocità crescente per ondate
                emitter.particleSpeedRange = 90
                emitter.particleScale = 0.8
                emitter.particleScaleRange = 0.4
                emitter.particleScaleSpeed = -0.6
                emitter.particleAlpha = 1.0
                emitter.particleAlphaSpeed = -0.8
                
                // Colori viola/rosso/magenta alternati
                let colors: [UIColor] = [
                    UIColor(red: 0.9, green: 0.2, blue: 0.7, alpha: 1.0),  // Magenta
                    UIColor(red: 0.8, green: 0.1, blue: 0.5, alpha: 1.0),  // Rosa scuro
                    UIColor(red: 0.6, green: 0.0, blue: 0.8, alpha: 1.0)   // Viola
                ]
                emitter.particleColor = colors[waveIndex % colors.count]
                emitter.particleColorBlendFactor = 1.0
                emitter.particleBlendMode = .add
                emitter.zPosition = 100 + CGFloat(waveIndex)
                
                self.worldLayer.addChild(emitter)
                
                let waitAction = SKAction.wait(forDuration: 1.8)
                let removeAction = SKAction.removeFromParent()
                emitter.run(SKAction.sequence([waitAction, removeAction]))
            }
        }
        
        // 2. Cerchi concentrici multipli che si espandono (tipo wave blast)
        for i in 0..<5 {
            let delay = Double(i) * 0.05
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                let ring = SKShapeNode(circleOfRadius: 8)
                ring.position = position
                ring.strokeColor = UIColor(red: 0.9, green: 0.3, blue: 0.7, alpha: 0.9 - CGFloat(i) * 0.15)
                ring.lineWidth = 4 - CGFloat(i) * 0.5
                ring.fillColor = UIColor(red: 0.8, green: 0.2, blue: 0.6, alpha: 0.2 - CGFloat(i) * 0.03)
                ring.glowWidth = 3
                ring.zPosition = 98 - CGFloat(i)
                
                self.worldLayer.addChild(ring)
                
                let finalScale = explosionRadius / 8.0
                let expandDuration = 0.5 + Double(i) * 0.08
                let expandAction = SKAction.scale(to: finalScale, duration: expandDuration)
                let fadeAction = SKAction.fadeOut(withDuration: expandDuration)
                let group = SKAction.group([expandAction, fadeAction])
                let removeAction = SKAction.removeFromParent()
                ring.run(SKAction.sequence([group, removeAction]))
            }
        }
        
        // 3. Flash centrale brillante
        let flash = SKShapeNode(circleOfRadius: 12)
        flash.position = position
        flash.fillColor = UIColor(red: 1.0, green: 0.8, blue: 0.9, alpha: 1.0)
        flash.strokeColor = .clear
        flash.glowWidth = 15
        flash.zPosition = 102
        
        worldLayer.addChild(flash)
        
        let flashExpand = SKAction.scale(to: 3.0, duration: 0.15)
        let flashFade = SKAction.fadeOut(withDuration: 0.15)
        let flashGroup = SKAction.group([flashExpand, flashFade])
        flash.run(SKAction.sequence([flashGroup, SKAction.removeFromParent()]))
        
        // 4. Danneggia tutti gli asteroidi nel raggio con effetto particellare
        var hitCount = 0
        for child in worldLayer.children {
            if child.name?.starts(with: "asteroid") == true,
               let asteroid = child as? SKShapeNode {
                let distance = hypot(asteroid.position.x - position.x, asteroid.position.y - position.y)
                if distance <= explosionRadius {
                    // Calcola ritardo basato sulla distanza (effetto onda)
                    let delay = distance / explosionRadius * 0.15
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        guard let self = self, asteroid.parent != nil else { return }
                        // Esplosione colorata su ogni asteroide
                        self.createExplosionParticles(at: asteroid.position, color: UIColor(red: 0.9, green: 0.3, blue: 0.7, alpha: 1.0))
                        self.fragmentAsteroid(asteroid, damageMultiplier: damageMultiplier)
                    }
                    
                    hitCount += 1
                }
            }
        }
        
        debugLog("💥🚀 Missile explosion at \(position) - radius: \(explosionRadius) - hit \(hitCount) asteroids")
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
                explosionPlayer = try AVAudioPlayer(contentsOf: url)
                explosionPlayer?.volume = 1.0
                explosionPlayer?.enableRate = true
                explosionPlayer?.rate = 0.75
                explosionPlayer?.play()
            } catch {
                debugLog("❌ Error loading explosion sound: \(error)")
            }
        }
    }

    // MARK: - Power-ups
    private func spawnPowerUp(at position: CGPoint) {
        // Probabilità di spawn: 25%
        let roll = Int.random(in: 0..<100)
        guard roll < 25 else { return }

        // DISTRIBUZIONE PROGRESSIVA power-up per wave
        // Wave 1: V (Vulcan), B (Bullet)
        // Wave 2: V, B, A (Atmosphere)
        // Wave 3: V, B, A, G (Gravity)
        // Wave 4+: V, B, A, G, W (Wave), M (Missile)
        // TUTTI CON PESO 1 = PROBABILITÀ PARIFICATE
        
        var weightedTypes: [(String, UIColor, Int)] = []
        
        // Power-up base (wave 1+) - sempre disponibili
        weightedTypes.append(("V", UIColor.orange, 1))  // Vulcan - fuoco rapido
        weightedTypes.append(("B", UIColor.green, 1))   // Bullet - munizioni potenziate
        
        // Wave 2+: aggiungi Atmosphere
        if currentWave >= 2 {
            weightedTypes.append(("A", UIColor.cyan, 1))    // Atmosphere - ricarica atmosfera
        }
        
        // Wave 3+: aggiungi Gravity
        if currentWave >= 3 {
            weightedTypes.append(("G", UIColor.gray, 1))  // Gravity - attira asteroidi
        }
        
        // Wave 4+: aggiungi Wave e Missile
        if currentWave >= 4 {
            weightedTypes.append(("W", UIColor.purple, 1))  // Wave - esplosione scudo
            weightedTypes.append(("M", UIColor(red: 0.6, green: 0.0, blue: 0.8, alpha: 1.0), 1))  // Missile - homing ad area
        }
        
        // Calcola il totale dei pesi
        let totalWeight = weightedTypes.reduce(0) { $0 + $1.2 }  // Somma tutti i pesi
        
        // Estrazione casuale pesata
        let randomValue = Int.random(in: 0..<totalWeight)
        var cumulativeWeight = 0
        var choice: (String, UIColor) = ("V", .red)
        
        for (type, color, weight) in weightedTypes {
            cumulativeWeight += weight
            if randomValue < cumulativeWeight {
                choice = (type, color)
                break
            }
        }

        let radius: CGFloat = 14
        let powerup = SKShapeNode(circleOfRadius: radius)
        powerup.fillColor = choice.1
        powerup.strokeColor = .white
        powerup.lineWidth = 2
        powerup.position = position
        powerup.zPosition = 50
        powerup.name = "powerup_\(choice.0)"
        
        // Log per debug della distribuzione
        let availableTypes = weightedTypes.map { $0.0 }.joined(separator: ", ")
        debugLog("🎁 Power-up spawned: \(choice.0) (wave \(currentWave), available: [\(availableTypes)])")

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
        // Se c'è già un power-up attivo (V, B, G, M), disattiva il precedente e attiva il nuovo
        // A (Atmosphere) e W (Wave) possono essere raccolti anche con altri power-up attivi
        if type != "A" && type != "W" && (vulcanActive || bigAmmoActive || gravityActive || missileActive) {
            debugLog("⚠️ Replacing active power-up with \(type)")
            // Disattiva il power-up precedente (ma mantieni activePowerupEndTime per resettarlo)
            deactivatePowerups()
        }
        
        // Attiva l'effetto e imposta timer a 10s (eccetto A e W)
        if type != "A" && type != "W" {
            activePowerupEndTime = currentTime + 10.0
        }
        
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
        } else if type == "G" {
            gravityActive = true
            powerupLabel.fontColor = UIColor.gray
            powerupLabel.text = "Gravity 10.00s"
            
            // Effetto pulsante vibrante sulla BARRIERA del player
            playerShield.removeAction(forKey: "gravityPulse")
            
            // Aumenta lineWidth e alpha per renderla visibile
            playerShield.lineWidth = 3
            playerShield.alpha = 1.0
            
            // Animazione complessa: scala + colori che cambiano velocemente
            let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
            let scaleDown = SKAction.scale(to: 0.9, duration: 0.15)
            let scaleNormal = SKAction.scale(to: 1.0, duration: 0.1)
            let scaleSequence = SKAction.sequence([scaleUp, scaleDown, scaleNormal])
            
            // Colori che cambiano: grigio → grigio scuro → grigio chiaro
            let color1 = SKAction.run { [weak self] in
                self?.playerShield.strokeColor = UIColor(white: 0.4, alpha: 1.0)  // Grigio scuro
            }
            let color2 = SKAction.run { [weak self] in
                self?.playerShield.strokeColor = UIColor(white: 0.7, alpha: 1.0)  // Grigio medio
            }
            let color3 = SKAction.run { [weak self] in
                self?.playerShield.strokeColor = UIColor(white: 0.9, alpha: 1.0)  // Grigio chiaro
            }
            let wait = SKAction.wait(forDuration: 0.13)
            let colorSequence = SKAction.sequence([color1, wait, color2, wait, color3, wait])
            
            // Combina scala e colore
            let combined = SKAction.group([scaleSequence, colorSequence])
            let repeatPulse = SKAction.repeatForever(combined)
            
            playerShield.run(repeatPulse, withKey: "gravityPulse")
            
            debugLog("🌑 Gravity power-up activated - asteroids attracted to player")
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
        } else if type == "W" {
            waveBlastActive = true
            powerupLabel.fontColor = UIColor.purple
            powerupLabel.text = "Wave"  // NO timer
            
            // Effetto bomba: espansione rapida della barriera
            triggerWaveBlast()
            
            debugLog("💥 Wave Blast activated - shield explosion")
        } else if type == "M" {
            missileActive = true
            // Frequenza metà normale: se baseFireRate è 0.2, missile sarà 0.4
            currentFireRate = baseFireRate * 2.0
            powerupLabel.fontColor = UIColor(red: 0.6, green: 0.0, blue: 0.8, alpha: 1.0)  // Viola
            powerupLabel.text = "Missile 10.00s"
            
            debugLog("🚀 Missile power-up activated - homing missiles")
        }
    }

    private func deactivatePowerups() {
        // Resetta gli stati
        vulcanActive = false
        bigAmmoActive = false
        atmosphereActive = false
        waveBlastActive = false
        missileActive = false
        
        // Disattiva gravity e ripristina barriera del player
        if gravityActive {
            gravityActive = false
            playerShield.removeAction(forKey: "gravityPulse")
            playerShield.removeAllActions()
            playerShield.setScale(1.0)
            playerShield.strokeColor = UIColor.white.withAlphaComponent(0.3)
            playerShield.lineWidth = 1
            playerShield.alpha = 1.0
            debugLog("🌍 Gravity power-up deactivated - planet gravity restored")
        }
        
        projectileWidthMultiplier = 1.0
        projectileHeightMultiplier = 1.0
        projectileDamageMultiplier = 1.0
        currentFireRate = baseFireRate
        activePowerupEndTime = 0
        powerupLabel.text = ""
    }
    
    private func triggerWaveBlast() {
        // Salva lo stato originale della barriera
        let originalRadius: CGFloat = 20
        let finalRadius: CGFloat = originalRadius * 30  // 30x più grande = 600 unità
        
        // Ferma eventuali animazioni in corso
        playerShield.removeAllActions()
        
        // Imposta stato iniziale
        playerShield.setScale(1.0)
        playerShield.strokeColor = UIColor.purple.withAlphaComponent(0.2)
        playerShield.fillColor = UIColor.purple.withAlphaComponent(0.1)
        playerShield.lineWidth = 3
        playerShield.alpha = 1.0
        
        // Animazione di espansione: scala da 1 a 30 in 0.5s
        let scaleUp = SKAction.scale(to: 30.0, duration: 0.5)
        
        // Animazione opacità: da 0.2 a 1.0 gradualmente
        let fadeIn = SKAction.customAction(withDuration: 0.5) { [weak self] node, elapsedTime in
            let progress = elapsedTime / 0.5
            let alpha = 0.2 + (0.8 * progress)  // Da 0.2 a 1.0
            self?.playerShield.strokeColor = UIColor.purple.withAlphaComponent(alpha)
            self?.playerShield.fillColor = UIColor.purple.withAlphaComponent(alpha * 0.5)
        }
        
        // Combina espansione e fade
        let expand = SKAction.group([scaleUp, fadeIn])
        
        // Dopo l'espansione, ripristina
        let restore = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // Resetta la barriera
            self.playerShield.setScale(1.0)
            self.playerShield.strokeColor = UIColor.white.withAlphaComponent(0.3)
            self.playerShield.fillColor = .clear
            self.playerShield.lineWidth = 1
            self.playerShield.alpha = 1.0
            
            // Disattiva il power-up
            self.waveBlastActive = false
            self.powerupLabel.text = ""
            
            self.debugLog("💥 Wave Blast completed")
        }
        
        // Sequenza completa
        let sequence = SKAction.sequence([expand, restore])
        playerShield.run(sequence, withKey: "waveBlast")
        
        // Durante l'espansione, danneggia tutti gli asteroidi nel raggio
        checkWaveBlastDamage()
    }
    
    private func checkWaveBlastDamage() {
        // Controlla ogni 0.05s durante i 0.5s di espansione (10 controlli totali)
        let checkInterval: TimeInterval = 0.05
        let totalChecks = 10
        var checksCompleted = 0
        
        func performCheck() {
            checksCompleted += 1
            
            // Calcola il raggio attuale della barriera in base al progresso
            let progress = CGFloat(checksCompleted) / CGFloat(totalChecks)
            let originalRadius: CGFloat = 20
            let currentRadius = originalRadius * (1.0 + 29.0 * progress)  // Da 20 a 600
            
            // Converti in coordinate world (la barriera è relativa al player)
            let blastCenterWorld = player.position
            
            // Danneggia asteroidi nel raggio
            var asteroidsToDestroy: [SKShapeNode] = []
            
            for asteroid in asteroids {
                let dx = asteroid.position.x - blastCenterWorld.x
                let dy = asteroid.position.y - blastCenterWorld.y
                let distance = sqrt(dx * dx + dy * dy)
                
                // Se l'asteroide è nel raggio dell'esplosione
                if distance <= currentRadius {
                    // Flash visivo viola
                    let flash = SKAction.sequence([
                        SKAction.colorize(with: .purple, colorBlendFactor: 0.8, duration: 0.05),
                        SKAction.colorize(withColorBlendFactor: 0, duration: 0.05)
                    ])
                    asteroid.run(flash)
                    
                    // Controlla se ha vita (armored)
                    if let health = asteroid.userData?["health"] as? Int, health > 1 {
                        // Riduci la vita di 2 (equivalente a 2 colpi normali)
                        let newHealth = max(0, health - 2)
                        asteroid.userData?["health"] = newHealth
                        
                        // Se la vita arriva a 0, distruggi
                        if newHealth <= 0 {
                            asteroidsToDestroy.append(asteroid)
                        }
                    } else {
                        // Asteroide normale o armored con 1 vita rimasta -> distruggi
                        asteroidsToDestroy.append(asteroid)
                    }
                }
            }
            
            // Distruggi gli asteroidi colpiti (usa fragmentAsteroid per gestire frammenti e punti)
            for asteroid in asteroidsToDestroy {
                fragmentAsteroid(asteroid, damageMultiplier: 2.0)
            }
            
            // Pianifica il prossimo controllo se non abbiamo finito
            if checksCompleted < totalChecks {
                DispatchQueue.main.asyncAfter(deadline: .now() + checkInterval) {
                    performCheck()
                }
            }
        }
        
        // Inizia i controlli
        performCheck()
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
        
        // PAUSA LA MUSICA (non stop, così riprende da dove era)
        musicPlayerCurrent?.pause()
        musicPlayerNext?.pause()
        
        debugLog("⏸️ Music paused")
        
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
        
        // RIPRENDI LA MUSICA da dove era
        musicPlayerCurrent?.play()
        musicPlayerNext?.play()
        
        debugLog("▶️ Music resumed")
        
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
        // FERMA TUTTA LA MUSICA prima di uscire
        crossfadeTimer?.invalidate()
        crossfadeTimer = nil
        
        // Stop completo e rimozione player
        musicPlayerCurrent?.stop()
        musicPlayerCurrent = nil
        musicPlayerNext?.stop()
        musicPlayerNext = nil
        
        // RIMUOVI tutti gli audio node dalla scena (fix sovrapposizione)
        self.removeAllActions()
        self.removeAllChildren()
        
        debugLog("🏠 Returning to main menu (all music stopped)")
        
        // Piccolo delay per assicurare che la musica sia completamente fermata
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            // Transizione al menu principale
            let transition = SKTransition.fade(withDuration: 0.5)
            let menuScene = MainMenuScene(size: self.size)
            menuScene.scaleMode = self.scaleMode
            self.view?.presentScene(menuScene, transition: transition)
        }
    }
    
    private func retryGame() {
        // FERMA TUTTA LA MUSICA prima di riavviare
        crossfadeTimer?.invalidate()
        crossfadeTimer = nil
        
        // Stop completo e rimozione player
        musicPlayerCurrent?.stop()
        musicPlayerCurrent = nil
        musicPlayerNext?.stop()
        musicPlayerNext = nil
        
        // RIMUOVI tutti gli audio node dalla scena (fix sovrapposizione)
        self.removeAllActions()
        self.removeAllChildren()
        
        debugLog("🔄 Restarting game (all music stopped)")
        
        // Piccolo delay per assicurare che la musica sia completamente fermata
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            // Riavvia il gioco
            let newGame = GameScene(size: self.size)
            newGame.scaleMode = self.scaleMode
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(newGame, transition: transition)
        }
    }
    
    // MARK: - Planet Health System
    private func updatePlanetHealthLabel() {
        planetHealthLabel.text = "\(planetHealth)/\(maxPlanetHealth)"
    }
    
    private func flashPlanet() {
        // Effetto flash rosso sul pianeta quando viene colpito
        planet.fillColor = .red
        
        let wait = SKAction.wait(forDuration: 0.1)
        let restore = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.planet.fillColor = self.planetOriginalColor  // Usa il colore originale memorizzato
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
        
        // Attendi 2 secondi per vedere l'esplosione completa prima di mostrare game over
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.checkIfTopTen()
        }
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
        // FERMA TUTTA LA MUSICA prima di cambiare scena
        crossfadeTimer?.invalidate()
        crossfadeTimer = nil
        musicPlayerCurrent?.stop()
        musicPlayerCurrent = nil
        musicPlayerNext?.stop()
        musicPlayerNext = nil
        
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
        
        // Testo GAME OVER - dimensione ridotta
        let fontName = "AvenirNext-Bold"
        let gameOverLabel = SKLabelNode(fontNamed: fontName)
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 56  // Ridotto da 72
        gameOverLabel.fontColor = .red
        gameOverLabel.horizontalAlignmentMode = .center
        gameOverLabel.position = CGPoint(x: 0, y: 70)  // Spostato più in alto
        overlay.addChild(gameOverLabel)
        
        // Score finale - ridotto
        let finalScoreLabel = SKLabelNode(fontNamed: fontName)
        finalScoreLabel.text = "FINAL SCORE: \(score)"
        finalScoreLabel.fontSize = 28  // Ridotto da 32
        finalScoreLabel.fontColor = .white
        finalScoreLabel.horizontalAlignmentMode = .center
        finalScoreLabel.position = CGPoint(x: 0, y: 10)  // Relativo al centro
        overlay.addChild(finalScoreLabel)
        
        // Wave raggiunta - ridotto
        let waveLabel = SKLabelNode(fontNamed: fontName)
        waveLabel.text = "WAVE \(currentWave)"
        waveLabel.fontSize = 20  // Ridotto da 24
        waveLabel.fontColor = UIColor.white.withAlphaComponent(0.7)
        waveLabel.horizontalAlignmentMode = .center
        waveLabel.position = CGPoint(x: 0, y: -20)  // Più vicino allo score
        overlay.addChild(waveLabel)
        
        // Pulsante SAVE SCORE - ridotto
        let saveScoreButton = SKShapeNode(rectOf: CGSize(width: 220, height: 50), cornerRadius: 10)
        saveScoreButton.fillColor = UIColor.yellow.withAlphaComponent(0.2)
        saveScoreButton.strokeColor = .yellow
        saveScoreButton.lineWidth = 3
        saveScoreButton.position = CGPoint(x: 0, y: -75)  // Più vicino alle scritte
        saveScoreButton.name = "saveScoreButton"
        
        let saveScoreLabel = SKLabelNode(fontNamed: fontName)
        saveScoreLabel.text = "SAVE SCORE"
        saveScoreLabel.fontSize = 20  // Ridotto da 24
        saveScoreLabel.fontColor = .yellow
        saveScoreLabel.verticalAlignmentMode = .center
        saveScoreButton.addChild(saveScoreLabel)
        overlay.addChild(saveScoreButton)
        
        // Pulsante RETRY - ridotto
        let retryButton = SKShapeNode(rectOf: CGSize(width: 170, height: 50), cornerRadius: 10)
        retryButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        retryButton.strokeColor = .white
        retryButton.lineWidth = 3
        retryButton.position = CGPoint(x: -95, y: -145)  // Più vicini
        retryButton.name = "retryButton"
        
        let retryLabel = SKLabelNode(fontNamed: fontName)
        retryLabel.text = "RETRY"
        retryLabel.fontSize = 20  // Ridotto da 24
        retryLabel.fontColor = .white
        retryLabel.verticalAlignmentMode = .center
        retryButton.addChild(retryLabel)
        overlay.addChild(retryButton)
        
        // Pulsante MENU - ridotto
        let menuButton = SKShapeNode(rectOf: CGSize(width: 170, height: 50), cornerRadius: 10)
        menuButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        menuButton.strokeColor = .white
        menuButton.lineWidth = 3
        menuButton.position = CGPoint(x: 95, y: -145)  // Più vicini
        menuButton.name = "menuButton"
        
        let menuLabel = SKLabelNode(fontNamed: fontName)
        menuLabel.text = "MENU"
        menuLabel.fontSize = 20  // Ridotto da 24
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

// MARK: - Brake Button Node
class BrakeButtonNode: SKNode {
    private var baseNode: SKShapeNode!
    private var isPressed = false
    private var touchId: UITouch?
    
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?
    
    init(radius: CGFloat) {
        super.init()
        
        // Base circolare verde - SENZA BORDO E SENZA ICONA
        baseNode = SKShapeNode(circleOfRadius: radius)
        baseNode.fillColor = UIColor.green.withAlphaComponent(0.3)
        baseNode.strokeColor = .clear  // Nessun bordo
        baseNode.lineWidth = 0
        baseNode.zPosition = 0
        addChild(baseNode)
        
        // Nessuna icona - solo il cerchio verde
        
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touchId == nil else { return }
        let location = touch.location(in: self)
        
        if baseNode.contains(location) {
            touchId = touch
            isPressed = true
            baseNode.fillColor = UIColor.green.withAlphaComponent(0.6)
            baseNode.setScale(0.9)
            onPress?()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touchId, touches.contains(touch) else { return }
        let location = touch.location(in: self)
        
        if !baseNode.contains(location) && isPressed {
            // Uscito dal pulsante
            isPressed = false
            baseNode.fillColor = UIColor.green.withAlphaComponent(0.3)
            baseNode.setScale(1.0)
            onRelease?()
            touchId = nil
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touchId, touches.contains(touch) else { return }
        
        if isPressed {
            isPressed = false
            baseNode.fillColor = UIColor.green.withAlphaComponent(0.3)
            baseNode.setScale(1.0)
            onRelease?()
        }
        touchId = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}

// MARK: - CGVector Extensions for Reflection
extension CGVector {
    // Normalizza il vettore
    func normalized() -> CGVector {
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return CGVector.zero }
        return CGVector(dx: dx / length, dy: dy / length)
    }
    
    // Prodotto scalare
    static func * (lhs: CGVector, rhs: CGVector) -> CGFloat {
        return lhs.dx * rhs.dx + lhs.dy * rhs.dy
    }
}

// MARK: - Enhanced Background System (New)

extension GameScene {
    
    /// Crea un emitter di stelle dinamico per starfield multi-layer
    /// Versione semplificata senza texture custom
    // Helper per creare texture particella stella
    func createStarParticleTexture() -> SKTexture {
        // Usa SKShapeNode per creare la texture - più affidabile in SpriteKit
        let size: CGFloat = 64
        let star = SKShapeNode(circleOfRadius: size / 4)
        star.fillColor = .white
        star.strokeColor = .clear
        star.glowWidth = size / 8  // Glow per effetto stella
        
        // Crea texture dalla view se disponibile, altrimenti fallback
        if let view = self.view {
            let texture = view.texture(from: star)
            texture?.filteringMode = .linear
            print("   🎨 Texture created from view: size=\(texture?.size() ?? .zero)")
            return texture ?? createFallbackTexture()
        } else {
            print("   ⚠️ View not available, using fallback texture")
            return createFallbackTexture()
        }
    }
    
    // Fallback texture se la view non è disponibile
    func createFallbackTexture() -> SKTexture {
        let size: CGFloat = 64
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            print("   ❌ Failed to create graphics context")
            return SKTexture()
        }
        
        // Cerchio bianco
        let center = CGPoint(x: size / 2, y: size / 2)
        let radius = size / 4
        
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, 
                                       width: radius * 2, height: radius * 2))
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            let texture = SKTexture(image: image)
            texture.filteringMode = .linear
            print("   🎨 Fallback texture created: size=\(texture.size())")
            return texture
        }
        
        print("   ❌ Failed to create fallback texture")
        return SKTexture()
    }
    

}

// MARK: - PROJECTILE REFLECTION FEATURE (DISABLED - WIP)
// Vedi REFLECTION_FEATURE_WIP.md per codice completo
// Disabilitato perché i proiettili trapassano l'atmosfera

// MARK: - CGVector Extension (per uso futuro)
extension CGVector {
    
    // Riflessione del vettore rispetto a una normale
    // Formula: v' = v - 2 * (v · n) * n
    func bounced(withNormal normal: CGVector) -> CGVector {
        let normalizedSelf = self.normalized()
        let normalizedNormal = normal.normalized()
        let dotProduct = normalizedSelf * normalizedNormal
        
        // Riflessione: v - 2(v·n)n
        let dx = self.dx - 2 * dotProduct * normalizedNormal.dx
        let dy = self.dy - 2 * dotProduct * normalizedNormal.dy
        
        return CGVector(dx: dx, dy: dy)
    }
    
    // Lunghezza del vettore
    var magnitude: CGFloat {
        return sqrt(dx * dx + dy * dy)
    }
}
