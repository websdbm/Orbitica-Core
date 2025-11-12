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
    
    // AI Controller per movimento intelligente
    private var aiController: AIController?
    
    // Parametri orbita desiderata
    private let desiredOrbitRadius: CGFloat = 170.0  // Orbita più stretta del player
    
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
        // FORMA ESAGONALE
        let radius: CGFloat = 12
        let hexagonPath = CGMutablePath()
        
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3.0  // 60 gradi per lato
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
        
        // Colore verde fluorescente brillante
        let neonGreen = UIColor(red: 0.2, green: 1.0, blue: 0.3, alpha: 1.0)
        self.fillColor = neonGreen
        self.strokeColor = UIColor(red: 0.5, green: 1.0, blue: 0.6, alpha: 1.0)
        self.lineWidth = 3
        self.glowWidth = 8
        
        self.name = "drone"
        self.zPosition = 100  // Alto per visibilità garantita
        self.alpha = 1.0  // Completamente visibile
        
        print("🔧 DroneNode created - fillColor: \(neonGreen), strokeColor: \(self.strokeColor), path points: 6")
        
        // Effetto glow pulsante
        let pulseUp = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        let pulseDown = SKAction.fadeAlpha(to: 0.7, duration: 0.5)
        let pulse = SKAction.sequence([pulseUp, pulseDown])
        run(SKAction.repeatForever(pulse))
    }
    
    private func setupPhysics() {
        // Physics body circolare per esagono (approssimazione)
        let body = SKPhysicsBody(circleOfRadius: 12)
        body.isDynamic = true
        body.mass = 0.4  // Più leggero per movimenti fluidi
        body.linearDamping = 0.2  // Damping maggiore per decelerazioni più morbide
        body.angularDamping = 0.0  // Permetti rotazione libera
        body.restitution = 0.8  // Rimbalzo elastico sull'atmosfera
        body.friction = 0.0  // Nessuna friction per movimento fluido
        
        // Categoria physics speciale per il drone
        // Lo impostiamo come "projectile" per rilevare collisioni con asteroidi
        body.categoryBitMask = PhysicsCategory.projectile
        body.contactTestBitMask = PhysicsCategory.asteroid | PhysicsCategory.atmosphere  // Rileva asteroidi E atmosfera
        body.collisionBitMask = PhysicsCategory.atmosphere  // Collide SOLO con atmosfera (rimbalza)
        
        self.physicsBody = body
    }
    
    private func setupRotation() {
        // Rotazione veloce (1 giro ogni 0.8 secondi)
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 0.8)
        run(SKAction.repeatForever(rotate))
    }
    
    // MARK: - Update Loop
    
    func update(deltaTime: TimeInterval, asteroids: [SKNode], orbitalRings: [SKNode]) {
        // Inizializza AI controller se necessario
        if aiController == nil {
            aiController = AIController()
            aiController?.difficulty = .hard  // Hard per reattività massima
            print("🤖 Drone AI Controller initialized with HARD difficulty")
        }
        
        // Usa AI per decidere movimento
        guard let ai = aiController, let body = physicsBody else { return }
        
        // Costruisci GameState per l'AI
        let asteroidInfos = asteroids.compactMap { node -> AsteroidInfo? in
            guard let asteroidBody = node.physicsBody else { return nil }
            let distToPlanet = sqrt(
                pow(node.position.x - planetPosition.x, 2) +
                pow(node.position.y - planetPosition.y, 2)
            )
            return AsteroidInfo(
                position: node.position,
                velocity: asteroidBody.velocity,
                size: 20,  // Stima
                health: 3,  // Stima
                distanceFromPlanet: distToPlanet
            )
        }
        
        let gameState = GameState(
            playerPosition: position,
            playerVelocity: body.velocity,
            playerAngle: zRotation,
            planetPosition: planetPosition,
            planetRadius: planetRadius,
            planetHealth: 100,
            maxPlanetHealth: 100,
            atmosphereRadius: 96,
            maxAtmosphereRadius: 144,
            atmosphereActive: false,
            asteroids: asteroidInfos,
            powerups: [],  // Drone ignora power-up
            currentWave: 1,
            score: 0,
            isGrappledToOrbit: false,
            orbitalRingRadius: nil
        )
        
        // Ottieni direzione movimento dall'AI
        let movement = ai.desiredMovement(for: gameState)
        
        // Scala movimento per orbita più stretta (70% del normale)
        let droneMovementScale: CGFloat = 0.7
        let scaledMovement = CGVector(
            dx: movement.dx * droneMovementScale,
            dy: movement.dy * droneMovementScale
        )
        
        applyAIMovement(scaledMovement, deltaTime: deltaTime)
        
        // Limita distanza massima dal pianeta (safety)
        maintainOrbitBounds()
    }
    
    private func applyAIMovement(_ movement: CGVector, deltaTime: TimeInterval) {
        guard let body = physicsBody else { return }
        
        // Calcola forza da applicare (come fa il player)
        let thrustForce: CGFloat = 220.0 * 0.7  // 70% della forza del player per orbita stretta
        let force = CGVector(
            dx: movement.dx * thrustForce,
            dy: movement.dy * thrustForce
        )
        
        body.applyForce(force)
        
        // Limita velocità massima (più bassa del player)
        let currentSpeed = sqrt(body.velocity.dx * body.velocity.dx + body.velocity.dy * body.velocity.dy)
        let maxSpeed: CGFloat = 200.0  // Più lento del player (che va a ~450)
        
        if currentSpeed > maxSpeed {
            let scale = maxSpeed / currentSpeed
            body.velocity = CGVector(
                dx: body.velocity.dx * scale,
                dy: body.velocity.dy * scale
            )
        }
    }
    
    private func maintainOrbitBounds() {
        guard let body = physicsBody else { return }
        
        let distance = sqrt(
            pow(position.x - planetPosition.x, 2) +
            pow(position.y - planetPosition.y, 2)
        )
        
        // Se troppo lontano, forza di richiamo
        let maxOrbitDistance: CGFloat = 250.0
        if distance > maxOrbitDistance {
            let toPlanet = CGVector(
                dx: planetPosition.x - position.x,
                dy: planetPosition.y - position.y
            )
            let pullStrength: CGFloat = 800.0
            body.applyForce(CGVector(
                dx: (toPlanet.dx / distance) * pullStrength,
                dy: (toPlanet.dy / distance) * pullStrength
            ))
        }
        
        // Se troppo vicino all'atmosfera, allontanati
        let minSafeDistance: CGFloat = 160.0
        if distance < minSafeDistance {
            let toPlanet = CGVector(
                dx: planetPosition.x - position.x,
                dy: planetPosition.y - position.y
            )
            let escapeStrength: CGFloat = 500.0
            body.applyForce(CGVector(
                dx: -(toPlanet.dx / distance) * escapeStrength,
                dy: -(toPlanet.dy / distance) * escapeStrength
            ))
        }
    }
    
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
