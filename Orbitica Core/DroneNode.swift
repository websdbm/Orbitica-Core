//
//  DroneNode.swift
//  Orbitica Core
//
//  Drone difensivo autonomo che orbita il pianeta e speroneggia asteroidi
//

import SpriteKit

class DroneNode: SKShapeNode {
    
    // Proprietà
    private(set) var currentHealth: Int = 10
    private let maxHealth: Int = 10
    private var planetPosition: CGPoint = .zero
    private var planetRadius: CGFloat = 40
    
    // AI Controller per movimento intelligente (come il player!)
    private var aiController: AIController?
    
    // Parametri movimento - simula player con inerzia
    private let thrustForce: CGFloat = 180.0  // 82% della forza del player (220)
    private let maxSpeed: CGFloat = 350.0  // Più lento del player (~450)
    
    // NO parametri orbita fissa - movimento libero ed elegante!
    private var joystickDirection: CGVector = .zero
    private var isBraking: Bool = false
    
    // Debug counter per log
    private var updateCount: Int = 0
    
    init(planetPosition: CGPoint, planetRadius: CGFloat) {
        self.planetPosition = planetPosition
        self.planetRadius = planetRadius
        
        super.init()
        
        setupVisuals()
        setupPhysics()
        setupRotation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupVisuals() {
        // Carica texture drone.png usando SKTexture (come earth.jpg)
        let droneTexture = SKTexture(imageNamed: "drone.png")
        
        // Verifica che la texture sia valida
        if droneTexture.size().width > 0 {
            let droneSprite = SKSpriteNode(texture: droneTexture)
            droneSprite.size = CGSize(width: 60, height: 60)  // Raddoppiato da 30 a 60
            droneSprite.name = "droneSprite"
            droneSprite.zPosition = 0
            addChild(droneSprite)
            
            print("✅ DroneNode created with drone.png texture (\(droneTexture.size().width)x\(droneTexture.size().height))")
        } else {
            print("⚠️ drone.png texture invalid, using fallback hexagon shape")
            // Fallback: forma esagonale se SVG non trovato
            let radius: CGFloat = 12
            let hexagonPath = CGMutablePath()
            
            for i in 0..<6 {
                let angle = CGFloat(i) * .pi / 3.0
                let x = radius * cos(angle)
                let y = radius * sin(angle)
                
                if i == 0 {
                    hexagonPath.move(to: CGPoint(x: x, y: y))
                } else {
                    hexagonPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            hexagonPath.closeSubpath()
            
            self.path = hexagonPath
            
            let neonGreen = UIColor(red: 0.2, green: 1.0, blue: 0.3, alpha: 1.0)
            self.fillColor = neonGreen
            self.strokeColor = UIColor(red: 0.5, green: 1.0, blue: 0.6, alpha: 1.0)
            self.lineWidth = 3
            self.glowWidth = 8
        }
        
        self.name = "drone"
        self.zPosition = 100  // Alto per visibilità garantita
        self.alpha = 1.0  // Completamente visibile
        
        // Effetto glow pulsante
        let pulseUp = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        let pulseDown = SKAction.fadeAlpha(to: 0.7, duration: 0.5)
        let pulse = SKAction.sequence([pulseUp, pulseDown])
        run(SKAction.repeatForever(pulse))
    }
    
    private func setupPhysics() {
        // Physics body identico al player - subisce inerzia!
        let body = SKPhysicsBody(circleOfRadius: 12)
        body.isDynamic = true
        body.mass = 0.5  // Stessa massa del player per inerzia realistica
        body.linearDamping = 0.3  // Stesso damping del player
        body.angularDamping = 0.5
        body.allowsRotation = false  // Come player
        body.restitution = 0.6  // Rimbalzo moderato
        body.friction = 0.0
        
        // Categoria physics come player (ma NON spara)
        body.categoryBitMask = PhysicsCategory.projectile  // Speroneggia asteroidi
        body.contactTestBitMask = PhysicsCategory.asteroid | PhysicsCategory.atmosphere
        body.collisionBitMask = 0  // NO collisioni auto - rimbalzo manuale
        
        self.physicsBody = body
        
        print("🤖 Drone physics: mass=\(body.mass), damping=\(body.linearDamping), same as player")
        
        self.physicsBody = body
    }
    
    private func setupRotation() {
        // Rotazione molto lenta del drone.png (1 giro ogni 6 secondi - metà velocità)
        if let droneSprite = childNode(withName: "droneSprite") {
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 6.0)
            droneSprite.run(SKAction.repeatForever(rotate))
            print("🔄 Drone sprite slow rotation active (6s per revolution)")
        }
    }
    
    // MARK: - Update Loop
    
    func update(deltaTime: TimeInterval, asteroids: [SKNode], orbitalRings: [SKNode], screenSize: CGSize) {
        // Debug entry point
        updateCount += 1
        if updateCount % 180 == 0 {
            print("🤖 Drone update called: frame \(updateCount), asteroids=\(asteroids.count)")
        }
        
        // Inizializza AI controller HARD (reattività massima + manovre eleganti)
        if aiController == nil {
            aiController = AIController()
            aiController?.difficulty = .hard
            print("🤖 Drone AI initialized: HARD difficulty, elegant maneuvers, ramming enabled")
        }
        
        guard let ai = aiController, let body = physicsBody else {
            print("⚠️ Drone update: AI or physics body missing!")
            return
        }
        
        // SCREEN WRAPPING - come il player
        wrapAroundScreen(screenSize: screenSize)
        
        // Costruisci GameState per l'AI (stesso formato del player)
        let asteroidInfos = asteroids.compactMap { node -> AsteroidInfo? in
            guard let asteroidBody = node.physicsBody else { return nil }
            let dx = node.position.x - planetPosition.x
            let dy = node.position.y - planetPosition.y
            let distToPlanet = sqrt(dx * dx + dy * dy)
            
            return AsteroidInfo(
                position: node.position,
                velocity: asteroidBody.velocity,
                size: node.frame.width / 2,
                health: node.userData?["health"] as? Int ?? 1,
                distanceFromPlanet: distToPlanet
            )
        }
        
        // Se NON ci sono asteroidi, orbita elegantemente intorno al pianeta
        if asteroidInfos.isEmpty {
            orbitAroundPlanet(deltaTime: deltaTime)
            return
        }
        
        // STRATEGIA: Orbita SEMPRE + insegui asteroidi vicini
        // 1. Calcola movimento orbitale base
        let dx = planetPosition.x - position.x
        let dy = planetPosition.y - position.y
        let distanceFromPlanet = sqrt(dx * dx + dy * dy)
        let targetOrbitRadius: CGFloat = 200
        
        var orbitalMovement = CGVector.zero
        
        // Mantieni distanza orbitale (soft constraint)
        if distanceFromPlanet > targetOrbitRadius + 100 {
            // Troppo lontano - muovi verso pianeta
            orbitalMovement = CGVector(dx: dx / distanceFromPlanet * 0.3, dy: dy / distanceFromPlanet * 0.3)
        } else if distanceFromPlanet < targetOrbitRadius - 100 {
            // Troppo vicino - allontanati
            orbitalMovement = CGVector(dx: -dx / distanceFromPlanet * 0.3, dy: -dy / distanceFromPlanet * 0.3)
        } else {
            // Movimento tangenziale (orbita)
            orbitalMovement = CGVector(dx: -dy / distanceFromPlanet * 0.2, dy: dx / distanceFromPlanet * 0.2)
        }
        
        // 2. Trova asteroide più vicino PERICOLOSO (entro 400px)
        let nearbyAsteroids = asteroidInfos.filter { asteroid in
            let dist = hypot(asteroid.position.x - position.x, asteroid.position.y - position.y)
            return dist < 400
        }
        
        var attackMovement = CGVector.zero
        
        if let nearestThreat = nearbyAsteroids.min(by: { a, b in
            let distA = hypot(a.position.x - position.x, a.position.y - position.y)
            let distB = hypot(b.position.x - position.x, b.position.y - position.y)
            return distA < distB
        }) {
            // Insegui l'asteroide più vicino
            let toAsteroid = CGVector(
                dx: nearestThreat.position.x - position.x,
                dy: nearestThreat.position.y - position.y
            )
            let dist = hypot(toAsteroid.dx, toAsteroid.dy)
            
            // Thrust proporzionale alla vicinanza (più vicino = più forte)
            let attackStrength = max(0.0, 1.0 - dist / 400.0)  // 1.0 a 0px, 0.0 a 400px
            attackMovement = CGVector(
                dx: toAsteroid.dx / dist * attackStrength * 0.6,
                dy: toAsteroid.dy / dist * attackStrength * 0.6
            )
        }
        
        // 3. COMBINA orbita + attacco (orbita ha priorità 40%, attacco 60%)
        joystickDirection = CGVector(
            dx: orbitalMovement.dx * 0.4 + attackMovement.dx * 0.6,
            dy: orbitalMovement.dy * 0.4 + attackMovement.dy * 0.6
        )
        isBraking = false
        
        // Debug AI decision ogni 3 secondi
        if updateCount % 180 == 0 {
            let nearestAsteroid = asteroidInfos.min(by: { a, b in
                let distA = hypot(a.position.x - position.x, a.position.y - position.y)
                let distB = hypot(b.position.x - position.x, b.position.y - position.y)
                return distA < distB
            })
            if let nearest = nearestAsteroid {
                let dist = hypot(nearest.position.x - position.x, nearest.position.y - position.y)
                print("🎯 Drone AI: joy=(\(String(format: "%.2f", joystickDirection.dx)), \(String(format: "%.2f", joystickDirection.dy))), nearest asteroid: \(Int(dist))px")
            }
        }
        
        // Applica movimento ESATTAMENTE come il player (con inerzia)
        applyPlayerLikeMovement(deltaTime: deltaTime)
        
        // NO rotation towards velocity - sprite rotates slowly on its own
    }
    
    private func applyPlayerLikeMovement(deltaTime: TimeInterval) {
        guard let body = physicsBody else { return }
        
        // Applica thrust se c'è input (come player)
        if joystickDirection.dx != 0 || joystickDirection.dy != 0 {
            let force = CGVector(
                dx: joystickDirection.dx * thrustForce,
                dy: joystickDirection.dy * thrustForce
            )
            body.applyForce(force)
        }
        
        // Limita velocità massima (come player)
        let currentSpeed = sqrt(body.velocity.dx * body.velocity.dx + 
                               body.velocity.dy * body.velocity.dy)
        
        if currentSpeed > maxSpeed {
            let scale = maxSpeed / currentSpeed
            body.velocity = CGVector(
                dx: body.velocity.dx * scale,
                dy: body.velocity.dy * scale
            )
        }
    }
    
    // MARK: - Screen Wrapping (come player - rispetta playFieldMultiplier 3x)
    
    private func wrapAroundScreen(screenSize: CGSize) {
        let playFieldMultiplier: CGFloat = 3.0
        let playFieldWidth = screenSize.width * playFieldMultiplier
        let playFieldHeight = screenSize.height * playFieldMultiplier
        let minX = screenSize.width / 2 - playFieldWidth / 2
        let maxX = screenSize.width / 2 + playFieldWidth / 2
        let minY = screenSize.height / 2 - playFieldHeight / 2
        let maxY = screenSize.height / 2 + playFieldHeight / 2
        
        // Wrapping orizzontale (solo ai bordi del PLAYFIELD, non dello schermo)
        if position.x < minX {
            position.x = maxX
        } else if position.x > maxX {
            position.x = minX
        }
        
        // Wrapping verticale
        if position.y < minY {
            position.y = maxY
        } else if position.y > maxY {
            position.y = minY
        }
    }
    
    // MARK: - Idle Behavior (quando non ci sono asteroidi)
    
    private func orbitAroundPlanet(deltaTime: TimeInterval) {
        guard let body = physicsBody else { return }
        
        // Calcola vettore verso il pianeta
        let dx = planetPosition.x - position.x
        let dy = planetPosition.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // Distanza orbitale target: 200px dal pianeta (safe zone)
        let targetOrbitRadius: CGFloat = 200
        
        // Se troppo lontano, muovi VERSO il pianeta
        if distance > targetOrbitRadius + 50 {
            joystickDirection = CGVector(dx: dx / distance * 0.6, dy: dy / distance * 0.6)
        }
        // Se troppo vicino, muovi VIA dal pianeta
        else if distance < targetOrbitRadius - 50 {
            joystickDirection = CGVector(dx: -dx / distance * 0.6, dy: -dy / distance * 0.6)
        }
        // Altrimenti orbita tangenzialmente (movimento circolare elegante)
        else {
            // Vettore tangente = perpendicolare al raggio
            joystickDirection = CGVector(dx: -dy / distance * 0.4, dy: dx / distance * 0.4)
        }
        
        // Applica movimento con inerzia
        applyPlayerLikeMovement(deltaTime: deltaTime)
    }
    
    // REMOVED: Old orbital movement methods - now uses elegant AI maneuvers
    // - applyAIMovement (sostituito da applyPlayerLikeMovement)
    // - maintainOrbitBounds (non più necessario - movimento libero)
    // - checkProximityToOrbitalRing (può usare orbital rings tramite AI)
    
    // MARK: - Damage System
    
    func takeDamage(amount: Int) -> Bool {
        currentHealth -= amount
        
        // Effetto visivo danno
        flashDamage()
        
        if currentHealth <= 0 {
            // Morto!
            return true
        }
        
        return false
    }
    
    private func flashDamage() {
        // Flash rosso quando colpito
        let originalColor = fillColor
        
        let flash = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.fillColor = .red
            },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in
                self?.fillColor = originalColor
            }
        ])
        
        run(flash)
    }
    
    func explode(completion: @escaping () -> Void) {
        // MINI-WAVE: esplosione ridotta (50% area normale)
        let waveRadius: CGFloat = 60  // Metà di wave normale (120)
        let explosionPosition = position
        
        // Crea onda espansiva verde
        let wave = SKShapeNode(circleOfRadius: 10)
        wave.strokeColor = UIColor(red: 0.2, green: 1.0, blue: 0.3, alpha: 0.9)
        wave.lineWidth = 4
        wave.fillColor = .clear
        wave.glowWidth = 8
        wave.position = explosionPosition
        wave.zPosition = 20
        wave.name = "droneWave"  // Identificatore per fisica
        
        if let parent = parent {
            parent.addChild(wave)
            
            // DANNO AREA: Trova e danneggia asteroidi nel raggio
            parent.enumerateChildNodes(withName: "asteroid") { node, _ in
                let dx = node.position.x - explosionPosition.x
                let dy = node.position.y - explosionPosition.y
                let distance = sqrt(dx * dx + dy * dy)
                
                // Asteroidi entro il raggio wave vengono danneggiati
                if distance < waveRadius {
                    // Notifica al parent che deve frammentare l'asteroide
                    node.userData?["droneWaveHit"] = true
                }
            }
        }
        
        // Animazione espansione + fade
        let expand = SKAction.scale(to: waveRadius / 10, duration: 0.4)
        let fade = SKAction.fadeOut(withDuration: 0.4)
        let remove = SKAction.removeFromParent()
        
        wave.run(SKAction.sequence([
            SKAction.group([expand, fade]),
            remove
        ]))
        
        // Particelle esplosione
        createExplosionParticles()
        
        // Rimuovi drone dopo breve delay
        let wait = SKAction.wait(forDuration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let removeSelf = SKAction.removeFromParent()
        
        run(SKAction.sequence([wait, fadeOut, removeSelf])) {
            completion()
        }
    }
    
    private func createExplosionParticles() {
        // Particelle verdi che esplodono
        for _ in 0..<12 {
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = UIColor(red: 0.2, green: 1.0, blue: 0.3, alpha: 1.0)
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 19
            
            if let parent = parent {
                parent.addChild(particle)
            }
            
            // Direzione casuale
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed: CGFloat = CGFloat.random(in: 100...200)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            
            let move = SKAction.move(by: CGVector(dx: dx, dy: dy), duration: 0.5)
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let scale = SKAction.scale(to: 0.1, duration: 0.5)
            let remove = SKAction.removeFromParent()
            
            particle.run(SKAction.sequence([
                SKAction.group([move, fade, scale]),
                remove
            ]))
        }
    }
    
    // MARK: - Getters
    
    func getHealthPercentage() -> CGFloat {
        return CGFloat(currentHealth) / CGFloat(maxHealth)
    }
    
    func getHealthString() -> String {
        return "\(currentHealth)/\(maxHealth)"
    }
}
