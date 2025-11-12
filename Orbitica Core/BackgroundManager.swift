//
//  BackgroundManager.swift
//  Orbitica Core
//
//  Sistema modulare per gestione background - unica fonte di verità
//  Usato sia in GameScene che in RegiaScene e DebugScene
//

import SpriteKit

// MARK: - Space Environment Enum

enum SpaceEnvironment: Int, CaseIterable {
    // AMBIENTI ENHANCED (★ = Featured)
    case cosmicNebula = 0       // Nebulosa Cosmica con nebula02 ★
    case nebulaGalaxy = 1       // Galassie/Nebulose animate con nebula01 ★
    case animatedCosmos = 2     // Sistema solare animato ★
    case deepSpaceEnhanced = 3  // Deep Space con starfield multi-layer ★
    
    // AMBIENTI CLASSICI
    case voidSpace = 4
    case redGiant = 5
    case asteroidBelt = 6
    case binaryStars = 7
    case ionStorm = 8
    case pulsarField = 9
    case planetarySystem = 10
    case cometTrail = 11
    case darkMatterCloud = 12
    case supernovaRemnant = 13
    case nebula = 14            // Nebula classica (non nebula01/02)
    case deepSpace = 15         // Deep Space classico
    
    var name: String {
        switch self {
        case .cosmicNebula: return "Cosmic Nebula ★"
        case .nebulaGalaxy: return "Nebula Galaxy ★"
        case .animatedCosmos: return "Animated Cosmos ★"
        case .deepSpaceEnhanced: return "Deep Space Enhanced ★"
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
        case .nebula: return "Nebula"
        case .deepSpace: return "Deep Space"
        }
    }
    
    var description: String {
        switch self {
        case .cosmicNebula: return "3-layer parallax nebula (nebula02.png)"
        case .nebulaGalaxy: return "Animated galaxies (nebula01.png)"
        case .animatedCosmos: return "6-planet solar system with realistic orbits"
        case .deepSpaceEnhanced: return "Multi-layer starfield with parallax"
        case .voidSpace: return "Dark gradient space"
        case .redGiant: return "Red giant star atmosphere"
        case .asteroidBelt: return "Distant asteroid field"
        case .binaryStars: return "Binary star system"
        case .ionStorm: return "Electric ion storm"
        case .pulsarField: return "Pulsing pulsar waves"
        case .planetarySystem: return "Planetary orbits"
        case .cometTrail: return "Luminous comet trails"
        case .darkMatterCloud: return "Dark matter particles"
        case .supernovaRemnant: return "Supernova gas expansion"
        case .nebula: return "Classic colored nebula"
        case .deepSpace: return "Classic deep space"
        }
    }
}

// MARK: - Background Manager

class BackgroundManager {
    
    // MARK: - Sequenza Wave per GameScene
    
    /// Sequenza background per modalità normale (cicla attraverso gli enhanced)
    static func environmentForWave(_ wave: Int) -> SpaceEnvironment {
        let enhancedEnvironments: [SpaceEnvironment] = [
            .cosmicNebula,      // Wave 1, 5, 9...
            .nebulaGalaxy,      // Wave 2, 6, 10...
            .animatedCosmos,    // Wave 3, 7, 11...
            .deepSpaceEnhanced  // Wave 4, 8, 12...
        ]
        
        let index = (wave - 1) % enhancedEnvironments.count
        return enhancedEnvironments[index]
    }
    
    // MARK: - Setup Methods (chiamati da GameScene/RegiaScene/DebugScene)
    
    /// Setup background - chiamata unica da qualsiasi scene
    static func setupBackground(_ environment: SpaceEnvironment, 
                               in scene: SKScene, 
                               worldLayer: SKNode, 
                               playFieldMultiplier: CGFloat) {
        
        // Cleanup precedente
        cleanupPreviousEnvironment(in: worldLayer)
        
        // Setup nuovo ambiente
        switch environment {
        case .cosmicNebula:
            setupCosmicNebula(in: scene, worldLayer: worldLayer, playFieldMultiplier: playFieldMultiplier)
        case .nebulaGalaxy:
            setupNebulaGalaxy(in: scene, worldLayer: worldLayer, playFieldMultiplier: playFieldMultiplier)
        case .animatedCosmos:
            setupAnimatedCosmos(in: scene, worldLayer: worldLayer, playFieldMultiplier: playFieldMultiplier)
        case .deepSpaceEnhanced:
            setupDeepSpaceEnhanced(in: scene, worldLayer: worldLayer, playFieldMultiplier: playFieldMultiplier)
        default:
            setupClassicEnvironment(environment, in: scene, worldLayer: worldLayer, playFieldMultiplier: playFieldMultiplier)
        }
    }
    
    // MARK: - Cleanup
    
    private static func cleanupPreviousEnvironment(in worldLayer: SKNode) {
        print("🧹 Cleaning up previous environment effects...")
        
        // 1. Rimuovi tutti gli emitter
        worldLayer.children.forEach { node in
            if node is SKEmitterNode {
                print("   ❌ Removing emitter: \(node.name ?? "unnamed")")
                node.removeFromParent()
            }
        }
        
        // 2. Rimuovi nodi specifici per nome
        let environmentNodes = [
            "backgroundStars", "cosmicNebulaLayer1", "cosmicNebulaLayer2", "cosmicNebulaLayer3",
            "cosmiNebulaOverlay", "mainNebula", "mainSolarSystem", "parallaxStarfield",
            "nebula", "starfield"
        ]
        
        for nodeName in environmentNodes {
            if let node = worldLayer.childNode(withName: nodeName) {
                print("   ❌ Removing: \(nodeName)")
                node.removeFromParent()
            }
        }
        
        // 3. Rimuovi nodi con keyword ambiente (proteggi nodi gioco)
        let protectedNames = ["planet", "atmosphere", "player", "asteroid", "bullet", "powerup", "orbital", "drone"]
        let environmentKeywords = ["dust", "nebula", "solar", "cosmic", "star", "galaxy"]
        
        worldLayer.children.forEach { node in
            if let nodeName = node.name?.lowercased() {
                let isProtected = protectedNames.contains { nodeName.contains($0.lowercased()) }
                
                if !isProtected {
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
    
    // MARK: - Cosmic Nebula (nebula02.png - 3 layer parallax)
    
    private static func setupCosmicNebula(in scene: SKScene, worldLayer: SKNode, playFieldMultiplier: CGFloat) {
        scene.backgroundColor = .black
        print("🌌 Creating Cosmic Nebula environment")
        
        let playAreaWidth = scene.size.width * playFieldMultiplier
        let playAreaHeight = scene.size.height * playFieldMultiplier
        
        // 1. Stelle di sfondo
        let backgroundStars = SKNode()
        backgroundStars.name = "backgroundStars"
        backgroundStars.zPosition = -1000
        backgroundStars.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        
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
        
        // 2. Nebulosa tripla layer con nebula02
        let nebulaTexture = SKTexture(imageNamed: "nebula02")
        let positions: [(x: CGFloat, y: CGFloat)] = [
            (scene.size.width * 0.30, scene.size.height * 0.70),
            (scene.size.width * 0.70, scene.size.height * 0.30),
            (scene.size.width * 0.25, scene.size.height * 0.40),
            (scene.size.width * 0.75, scene.size.height * 0.60)
        ]
        let sharedPosition = positions.randomElement()!
        let nebulaPosition = CGPoint(x: sharedPosition.x, y: sharedPosition.y)
        let sharedScale = CGFloat.random(in: 2.5...3.5)
        
        // Layer 1 (fondo - lento) - Alpha ridotto per evitare troppa luminosità
        let nebulaLayer1 = SKSpriteNode(texture: nebulaTexture)
        nebulaLayer1.name = "cosmicNebulaLayer1"
        nebulaLayer1.position = nebulaPosition
        nebulaLayer1.setScale(sharedScale)
        nebulaLayer1.alpha = 0.25  // Ridotto da 0.60
        nebulaLayer1.blendMode = .alpha  // ⚠️ Cambiato da .add
        nebulaLayer1.zPosition = -920
        worldLayer.addChild(nebulaLayer1)
        
        // Layer 2 (medio)
        let nebulaLayer2 = SKSpriteNode(texture: nebulaTexture)
        nebulaLayer2.name = "cosmicNebulaLayer2"
        nebulaLayer2.position = nebulaPosition
        nebulaLayer2.setScale(sharedScale)
        nebulaLayer2.alpha = 0.35  // Ridotto da 0.80
        nebulaLayer2.blendMode = .alpha  // ⚠️ Cambiato da .add
        nebulaLayer2.zPosition = -910
        nebulaLayer2.zRotation = .pi * 2 / 3
        worldLayer.addChild(nebulaLayer2)
        
        // Layer 3 (fronte - veloce)
        let nebulaLayer3 = SKSpriteNode(texture: nebulaTexture)
        nebulaLayer3.name = "cosmicNebulaLayer3"
        nebulaLayer3.position = nebulaPosition
        nebulaLayer3.setScale(sharedScale)
        nebulaLayer3.alpha = 0.45  // Ridotto da 1.0
        nebulaLayer3.blendMode = .alpha  // ⚠️ Cambiato da .add
        nebulaLayer3.zPosition = -900
        nebulaLayer3.zRotation = .pi * 4 / 3
        worldLayer.addChild(nebulaLayer3)
        
        // Rotazioni parallax
        nebulaLayer1.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 240)))
        nebulaLayer2.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 160)))
        nebulaLayer3.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 100)))
        
        // Pulsazioni
        let pulse1 = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.42, duration: 12),
            SKAction.fadeAlpha(to: 0.60, duration: 12)
        ])
        nebulaLayer1.run(SKAction.repeatForever(pulse1))
        
        let pulse2 = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.64, duration: 10),
            SKAction.fadeAlpha(to: 0.80, duration: 10)
        ])
        nebulaLayer2.run(SKAction.repeatForever(pulse2))
        
        let pulse3 = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.90, duration: 8),
            SKAction.fadeAlpha(to: 1.0, duration: 8)
        ])
        nebulaLayer3.run(SKAction.repeatForever(pulse3))
        
        print("✨ Cosmic Nebula created with 3-layer parallax")
    }
    
    // MARK: - Animated Cosmos (Sistema Solare)
    
    private static func setupAnimatedCosmos(in scene: SKScene, worldLayer: SKNode, playFieldMultiplier: CGFloat) {
        scene.backgroundColor = .black
        print("🌌 Creating Animated Cosmos (Solar System)")
        
        let playAreaWidth = scene.size.width * playFieldMultiplier
        let playAreaHeight = scene.size.height * playFieldMultiplier
        
        // 1. Stelle di sfondo
        let backgroundStars = SKNode()
        backgroundStars.name = "backgroundStars"
        backgroundStars.zPosition = -1000
        backgroundStars.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        
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
        
        // 2. Nebulosa distante
        let nebula = SKShapeNode(circleOfRadius: 450)
        nebula.fillColor = UIColor(red: 0.35, green: 0.25, blue: 0.65, alpha: 0.08)
        nebula.strokeColor = .clear
        nebula.glowWidth = 120
        nebula.zPosition = -950
        nebula.position = CGPoint(
            x: scene.size.width/2 - 400,
            y: scene.size.height/2 + 300
        )
        worldLayer.addChild(nebula)
        
        let nebulaRotate = SKAction.rotate(byAngle: .pi * 2, duration: 180)
        nebula.run(SKAction.repeatForever(nebulaRotate))
        
        // 3. Sistema solare realistico
        createRealisticSolarSystem(in: scene, worldLayer: worldLayer, playFieldMultiplier: playFieldMultiplier)
        
        print("✨ Animated Cosmos created with realistic solar system")
    }
    
    private static func createRealisticSolarSystem(in scene: SKScene, worldLayer: SKNode, playFieldMultiplier: CGFloat) {
        let systemNode = SKNode()
        systemNode.name = "mainSolarSystem"
        systemNode.zPosition = -800
        
        // Posizione casuale nei quadranti
        let quadrants: [(x: CGFloat, y: CGFloat)] = [
            (scene.size.width * 0.20, scene.size.height * 0.75),
            (scene.size.width * 0.80, scene.size.height * 0.75),
            (scene.size.width * 0.20, scene.size.height * 0.25),
            (scene.size.width * 0.80, scene.size.height * 0.25)
        ]
        
        let chosenQuadrant = quadrants.randomElement()!
        systemNode.position = CGPoint(x: chosenQuadrant.x, y: chosenQuadrant.y)
        systemNode.setScale(6.8)  // Ridotto da 8.0 (-15%)
        systemNode.alpha = 1.0
        
        // Sole - più visibile
        let sunSize: CGFloat = 40
        let sun = SKShapeNode(circleOfRadius: sunSize)
        sun.fillColor = UIColor(red: 0.25, green: 0.20, blue: 0.15, alpha: 1.0)  // Più chiaro
        sun.strokeColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 0.6)
        sun.lineWidth = 2
        sun.glowWidth = sunSize * 0.3
        systemNode.addChild(sun)
        
        // Corona
        let corona = SKShapeNode(circleOfRadius: sunSize * 1.25)
        corona.fillColor = UIColor(red: 0.20, green: 0.15, blue: 0.10, alpha: 0.4)
        corona.strokeColor = .clear
        corona.glowWidth = 6
        systemNode.addChild(corona)
        
        // Pulsazione sole
        let sunPulse = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.08, duration: 7.0),
                SKAction.fadeAlpha(to: 0.85, duration: 7.0)
            ]),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 7.0),
                SKAction.fadeAlpha(to: 1.0, duration: 7.0)
            ])
        ])
        sun.run(SKAction.repeatForever(sunPulse))
        corona.run(SKAction.repeatForever(sunPulse))
        
        // Pianeti - colori più visibili
        let planets: [(name: String, distance: CGFloat, size: CGFloat, color: UIColor, speed: Double, hasRings: Bool, hasMoon: Bool, startAngle: CGFloat)] = [
            ("Mercury", 80, 4, UIColor(red: 0.35, green: 0.32, blue: 0.28, alpha: 1.0), 45, false, false, 0),
            ("Venus", 120, 6, UIColor(red: 0.40, green: 0.36, blue: 0.28, alpha: 1.0), 66, false, false, .pi / 3),
            ("Earth", 170, 6.5, UIColor(red: 0.20, green: 0.28, blue: 0.42, alpha: 1.0), 90, false, true, .pi * 2 / 3),
            ("Mars", 220, 5, UIColor(red: 0.42, green: 0.22, blue: 0.18, alpha: 1.0), 126, false, false, .pi),
            ("Jupiter", 300, 14, UIColor(red: 0.38, green: 0.34, blue: 0.28, alpha: 1.0), 195, false, false, .pi * 4 / 3),
            ("Saturn", 380, 12, UIColor(red: 0.42, green: 0.38, blue: 0.30, alpha: 1.0), 255, true, false, .pi * 5 / 3)
        ]
        
        for planet in planets {
            let orbitContainer = SKNode()
            orbitContainer.name = "\(planet.name)Orbit"
            orbitContainer.zRotation = planet.startAngle
            systemNode.addChild(orbitContainer)
            
            // Orbita - più visibile
            let orbitCircle = SKShapeNode(circleOfRadius: planet.distance)
            orbitCircle.strokeColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 0.5)
            orbitCircle.lineWidth = 1.0
            orbitCircle.fillColor = .clear
            systemNode.addChild(orbitCircle)
            
            // Pianeta
            let planetNode = SKShapeNode(circleOfRadius: planet.size)
            planetNode.fillColor = planet.color
            planetNode.strokeColor = planet.color.withAlphaComponent(0.6)
            planetNode.lineWidth = 0.8
            planetNode.glowWidth = planet.size * 0.15
            planetNode.position = CGPoint(x: planet.distance, y: 0)
            orbitContainer.addChild(planetNode)
            
            // Anelli Saturno - più visibili
            if planet.hasRings {
                let ringRadius = planet.size * 2.2
                let ring = SKShapeNode(circleOfRadius: ringRadius)
                ring.strokeColor = planet.color.withAlphaComponent(0.7)
                ring.lineWidth = planet.size * 0.6
                ring.fillColor = .clear
                ring.glowWidth = 2
                planetNode.addChild(ring)
            }
            
            // Luna Terra - più visibile
            if planet.hasMoon {
                let moonContainer = SKNode()
                planetNode.addChild(moonContainer)
                
                let moon = SKShapeNode(circleOfRadius: planet.size * 0.35)
                moon.fillColor = UIColor(red: 0.38, green: 0.38, blue: 0.38, alpha: 1.0)
                moon.strokeColor = .clear
                moon.glowWidth = 1.0
                moon.position = CGPoint(x: planet.size * 2.5, y: 0)
                moonContainer.addChild(moon)
                
                moonContainer.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: planet.speed / 10)))
            }
            
            // Orbita e rotazione pianeta
            orbitContainer.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: planet.speed)))
            planetNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: planet.speed / 20)))
        }
        
        worldLayer.addChild(systemNode)
    }
    
    // MARK: - Placeholder per altri ambienti
    
    private static func setupNebulaGalaxy(in scene: SKScene, worldLayer: SKNode, playFieldMultiplier: CGFloat) {
        scene.backgroundColor = .black
        print("🌌 Creating Nebula Galaxy environment")
        
        let playAreaWidth = scene.size.width * playFieldMultiplier
        let playAreaHeight = scene.size.height * playFieldMultiplier
        
        // 1. Stelle di sfondo
        let backgroundStars = SKNode()
        backgroundStars.name = "backgroundStars"
        backgroundStars.zPosition = -1000
        backgroundStars.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        
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
        
        // 2. Nebulosa animata (nebula01)
        let nebulaTexture = SKTexture(imageNamed: "nebula01")
        let nebula = SKSpriteNode(texture: nebulaTexture)
        nebula.name = "mainNebula"
        nebula.zPosition = -900
        
        let positions: [(x: CGFloat, y: CGFloat)] = [
            (scene.size.width * 0.30, scene.size.height * 0.70),
            (scene.size.width * 0.70, scene.size.height * 0.30)
        ]
        let chosenPos = positions.randomElement()!
        nebula.position = CGPoint(x: chosenPos.x, y: chosenPos.y)
        nebula.setScale(CGFloat.random(in: 2.5...3.5))
        nebula.alpha = 0.25
        nebula.blendMode = .alpha  // ⚠️ Cambiato da .add
        worldLayer.addChild(nebula)
        
        // Rotazione lenta
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: Double.random(in: 120...180))
        nebula.run(SKAction.repeatForever(rotate))
        
        // Pulsazione
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.18, duration: 10),
            SKAction.fadeAlpha(to: 0.32, duration: 10)
        ])
        nebula.run(SKAction.repeatForever(pulse))
        
        print("✨ Nebula Galaxy created")
    }
    
    private static func setupDeepSpaceEnhanced(in scene: SKScene, worldLayer: SKNode, playFieldMultiplier: CGFloat) {
        scene.backgroundColor = .black
        print("🌌 Creating Deep Space Enhanced with parallax scrolling")
        
        let playAreaWidth = scene.size.width * playFieldMultiplier
        let playAreaHeight = scene.size.height * playFieldMultiplier
        
        // Starfield con parallasse scrolling (destra → sinistra)
        let starfieldContainer = SKNode()
        starfieldContainer.name = "parallaxStarfield"
        starfieldContainer.zPosition = -1000
        starfieldContainer.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        
        // Layer 1: stelle lontane - lente
        let distantLayer = createParallaxStarEmitter(
            speed: 10,
            scale: 0.12,
            birthRate: 1.2,
            color: UIColor.white.withAlphaComponent(0.6),
            playAreaWidth: playAreaWidth,
            playAreaHeight: playAreaHeight
        )
        starfieldContainer.addChild(distantLayer)
        
        // Layer 2: stelle medie
        let midLayer = createParallaxStarEmitter(
            speed: 18,
            scale: 0.16,
            birthRate: 1.8,
            color: UIColor.white.withAlphaComponent(0.7),
            playAreaWidth: playAreaWidth,
            playAreaHeight: playAreaHeight
        )
        starfieldContainer.addChild(midLayer)
        
        // Layer 3: stelle vicine - veloci
        let nearLayer = createParallaxStarEmitter(
            speed: 28,
            scale: 0.22,
            birthRate: 2.5,
            color: UIColor.cyan.withAlphaComponent(0.6),
            playAreaWidth: playAreaWidth,
            playAreaHeight: playAreaHeight
        )
        starfieldContainer.addChild(nearLayer)
        
        worldLayer.addChild(starfieldContainer)
        print("✨ Deep Space Enhanced created with 3-layer parallax (→←)")
    }
    
    // Helper: crea emitter per parallasse scrolling
    private static func createParallaxStarEmitter(speed: CGFloat, scale: CGFloat, birthRate: CGFloat, color: UIColor, playAreaWidth: CGFloat, playAreaHeight: CGFloat) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        
        // Crea texture stella programmaticamente
        let texture = createStarTexture()
        emitter.particleTexture = texture
        
        emitter.particleBirthRate = birthRate
        emitter.particleColor = color
        
        // Lifetime lungo per coprire area ampia
        emitter.particleLifetime = playAreaWidth / speed
        emitter.particleSpeed = speed
        emitter.particleScale = scale
        emitter.particleColorBlendFactor = 1
        emitter.particleScaleRange = scale * 0.3
        
        // Spawn da destra
        emitter.position = CGPoint(x: playAreaWidth / 2, y: 0)
        emitter.particlePositionRange = CGVector(dx: playAreaWidth, dy: playAreaHeight)
        emitter.particleSpeedRange = 0
        
        // Emissione verso SINISTRA (da destra a sinistra)
        emitter.emissionAngle = .pi  // 180°
        emitter.emissionAngleRange = 0
        
        emitter.particleAlpha = 0.7
        emitter.particleAlphaRange = 0.3
        emitter.particleBlendMode = .alpha
        
        return emitter
    }
    
    // Helper: crea texture stella semplice
    private static func createStarTexture() -> SKTexture {
        let size: CGFloat = 32
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        let image = renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            
            // Cerchio bianco con gradiente radiale
            let center = CGPoint(x: size/2, y: size/2)
            let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            
            context.cgContext.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: size/2,
                options: []
            )
        }
        
        return SKTexture(image: image)
    }
    
    private static func setupClassicEnvironment(_ environment: SpaceEnvironment, in scene: SKScene, worldLayer: SKNode, playFieldMultiplier: CGFloat) {
        let playAreaWidth = scene.size.width * playFieldMultiplier
        let playAreaHeight = scene.size.height * playFieldMultiplier
        
        switch environment {
        case .voidSpace:
            scene.backgroundColor = UIColor(red: 0.0, green: 0.02, blue: 0.08, alpha: 1.0)
            addStarfield(to: worldLayer, count: 100, color: .white, playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
            
        case .redGiant:
            scene.backgroundColor = UIColor(red: 0.12, green: 0.0, blue: 0.0, alpha: 1.0)
            addStarfield(to: worldLayer, count: 80, color: UIColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0), playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
            addGlowingSphere(to: worldLayer, radius: 300, color: UIColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 0.25), position: CGPoint(x: scene.size.width * 0.3, y: scene.size.height * 0.7))
            
        case .asteroidBelt:
            scene.backgroundColor = UIColor(red: 0.08, green: 0.06, blue: 0.05, alpha: 1.0)
            addStarfield(to: worldLayer, count: 60, color: .white, playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
            
        case .binaryStars:
            scene.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.05, alpha: 1.0)
            addStarfield(to: worldLayer, count: 80, color: .white, playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
            addGlowingSphere(to: worldLayer, radius: 180, color: UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 0.3), position: CGPoint(x: scene.size.width * 0.25, y: scene.size.height * 0.65))
            addGlowingSphere(to: worldLayer, radius: 150, color: UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.3), position: CGPoint(x: scene.size.width * 0.75, y: scene.size.height * 0.35))
            
        case .ionStorm:
            scene.backgroundColor = UIColor(red: 0.0, green: 0.08, blue: 0.12, alpha: 1.0)
            addStarfield(to: worldLayer, count: 70, color: UIColor.cyan, playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
            
        case .pulsarField:
            scene.backgroundColor = UIColor(red: 0.05, green: 0.1, blue: 0.08, alpha: 1.0)
            addStarfield(to: worldLayer, count: 90, color: UIColor(red: 0.4, green: 1.0, blue: 0.6, alpha: 1.0), playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
            
        case .planetarySystem:
            scene.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0)
            addStarfield(to: worldLayer, count: 100, color: .white, playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
            
        case .cometTrail:
            scene.backgroundColor = UIColor(red: 0.08, green: 0.12, blue: 0.15, alpha: 1.0)
            addStarfield(to: worldLayer, count: 80, color: UIColor.cyan, playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
            
        case .darkMatterCloud:
            scene.backgroundColor = UIColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1.0)
            addStarfield(to: worldLayer, count: 60, color: UIColor(red: 0.6, green: 0.5, blue: 0.7, alpha: 1.0), playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
            
        case .supernovaRemnant:
            scene.backgroundColor = UIColor(red: 0.15, green: 0.08, blue: 0.0, alpha: 1.0)
            addStarfield(to: worldLayer, count: 70, color: UIColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 1.0), playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
            addGlowingSphere(to: worldLayer, radius: 400, color: UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.15), position: CGPoint(x: scene.size.width * 0.5, y: scene.size.height * 0.5))
            
        case .nebula:
            scene.backgroundColor = UIColor(red: 0.08, green: 0.0, blue: 0.12, alpha: 1.0)
            addStarfield(to: worldLayer, count: 90, color: UIColor(red: 0.8, green: 0.4, blue: 0.9, alpha: 1.0), playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
            
        case .deepSpace:
            scene.backgroundColor = UIColor(red: 0.0, green: 0.01, blue: 0.05, alpha: 1.0)
            addStarfield(to: worldLayer, count: 120, color: .white, playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
            
        default:
            scene.backgroundColor = .black
            addStarfield(to: worldLayer, count: 80, color: .white, playAreaWidth: playAreaWidth, playAreaHeight: playAreaHeight, centerX: scene.size.width/2, centerY: scene.size.height/2)
        }
        
        print("✨ Classic environment: \(environment.name) created")
    }
    
    // MARK: - Helper Functions
    
    private static func addStarfield(to worldLayer: SKNode, count: Int, color: UIColor, playAreaWidth: CGFloat, playAreaHeight: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        let stars = SKNode()
        stars.name = "backgroundStars"
        stars.zPosition = -1000
        stars.position = CGPoint(x: centerX, y: centerY)
        
        for _ in 0..<count {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.8))
            star.fillColor = color
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.4...0.8)
            star.position = CGPoint(
                x: CGFloat.random(in: -playAreaWidth/2...playAreaWidth/2),
                y: CGFloat.random(in: -playAreaHeight/2...playAreaHeight/2)
            )
            stars.addChild(star)
            
            // Twinkle
            let fade1 = SKAction.fadeAlpha(to: 0.2, duration: Double.random(in: 1.0...2.5))
            let fade2 = SKAction.fadeAlpha(to: 0.8, duration: Double.random(in: 1.0...2.5))
            star.run(SKAction.repeatForever(SKAction.sequence([fade1, fade2])))
        }
        
        worldLayer.addChild(stars)
    }
    
    private static func addGlowingSphere(to worldLayer: SKNode, radius: CGFloat, color: UIColor, position: CGPoint) {
        let sphere = SKShapeNode(circleOfRadius: radius)
        sphere.fillColor = color
        sphere.strokeColor = .clear
        sphere.glowWidth = radius * 0.4
        sphere.position = position
        sphere.zPosition = -950
        worldLayer.addChild(sphere)
        
        // Pulsazione
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 5.0),
            SKAction.scale(to: 1.0, duration: 5.0)
        ])
        sphere.run(SKAction.repeatForever(pulse))
    }
}
