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
    
    // Target tracking
    private var targetAsteroid: SKNode?
    
    // Parametri movimento
    private let orbitSpeed: CGFloat = 140.0  // Velocità orbitale
    private let detectionRadius: CGFloat = 250.0  // Raggio rilevamento asteroidi più ampio
    private let desiredOrbitRadius: CGFloat = 170.0  // Orbita più ampia ed elegante
    
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
    
    func update(deltaTime: TimeInterval, asteroids: [SKNode]) {
        // 1. Applica gravità verso il pianeta (orbita naturale)
        applyGravity()
        
        // 2. Trova e insegui asteroide più vicino/pericoloso
        if let target = findTargetAsteroid(from: asteroids) {
            targetAsteroid = target
            moveTowardsTarget(target)
        } else {
            targetAsteroid = nil
            maintainOrbit()
        }
    }
    
    private func applyGravity() {
        guard let body = physicsBody else { return }
        
        // Vettore verso il pianeta
        let toPlanet = CGVector(
            dx: planetPosition.x - position.x,
            dy: planetPosition.y - position.y
        )
        let distance = sqrt(toPlanet.dx * toPlanet.dx + toPlanet.dy * toPlanet.dy)
        
        // Gravità bilanciata per orbita elegante
        let gravityStrength: CGFloat = 35000.0  // Ridotto per orbita più ampia
        let forceMagnitude = gravityStrength / max(distance * distance, 100)
        
        let forceVector = CGVector(
            dx: (toPlanet.dx / distance) * forceMagnitude,
            dy: (toPlanet.dy / distance) * forceMagnitude
        )
        
        body.applyForce(forceVector)
        
        // Limita velocità massima
        let currentSpeed = sqrt(body.velocity.dx * body.velocity.dx + body.velocity.dy * body.velocity.dy)
        let maxSpeed: CGFloat = 250.0  // Aumentato per movimento più fluido
        
        if currentSpeed > maxSpeed {
            let scale = maxSpeed / currentSpeed
            body.velocity = CGVector(
                dx: body.velocity.dx * scale,
                dy: body.velocity.dy * scale
            )
        }
        
        // Correzione gentile se troppo lontano
        if distance > desiredOrbitRadius + 80 {
            // Forza di richiamo moderata
            let pullBackStrength: CGFloat = 600.0
            body.applyForce(CGVector(
                dx: (toPlanet.dx / distance) * pullBackStrength,
                dy: (toPlanet.dy / distance) * pullBackStrength
            ))
        }
    }
    
    private func findTargetAsteroid(from asteroids: [SKNode]) -> SKNode? {
        // Trova asteroide più vicino entro detection radius
        var closest: (node: SKNode, distance: CGFloat)?
        
        for asteroid in asteroids {
            let dx = asteroid.position.x - position.x
            let dy = asteroid.position.y - position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance < detectionRadius {
                if closest == nil || distance < closest!.distance {
                    closest = (asteroid, distance)
                }
            }
        }
        
        return closest?.node
    }
    
    private func moveTowardsTarget(_ target: SKNode) {
        guard let body = physicsBody else { return }
        
        // Verifica distanza dal pianeta del target
        let targetToPlanet = sqrt(
            pow(target.position.x - planetPosition.x, 2) +
            pow(target.position.y - planetPosition.y, 2)
        )
        
        // NON inseguire asteroidi troppo vicini all'atmosfera (< 155px)
        if targetToPlanet < 155 {
            // Target pericoloso, rimani in orbita
            maintainOrbit()
            return
        }
        
        // Calcola direzione verso target
        let toTarget = CGVector(
            dx: target.position.x - position.x,
            dy: target.position.y - position.y
        )
        let distance = sqrt(toTarget.dx * toTarget.dx + toTarget.dy * toTarget.dy)
        
        // Thrust bilanciato per inseguimento aggressivo ma controllato
        let thrustStrength: CGFloat = 450.0  // Aumentato per inseguimento più deciso
        let thrust = CGVector(
            dx: (toTarget.dx / distance) * thrustStrength,
            dy: (toTarget.dy / distance) * thrustStrength
        )
        
        body.applyForce(thrust)
    }
    
    private func maintainOrbit() {
        guard let body = physicsBody else { return }
        
        // Mantieni orbita elegante e circolare
        let toPlanet = CGVector(
            dx: planetPosition.x - position.x,
            dy: planetPosition.y - position.y
        )
        let currentDistance = sqrt(toPlanet.dx * toPlanet.dx + toPlanet.dy * toPlanet.dy)
        
        // DISTANZA DI SICUREZZA DALL'ATMOSFERA
        // Atmosfera max = ~144px, quindi mantieni almeno 160px
        let minSafeDistance: CGFloat = 160.0
        if currentDistance < minSafeDistance {
            // Troppo vicino all'atmosfera! Allontanati
            let escapeStrength: CGFloat = 400.0
            let escapeForce = CGVector(
                dx: -(toPlanet.dx / currentDistance) * escapeStrength,
                dy: -(toPlanet.dy / currentDistance) * escapeStrength
            )
            body.applyForce(escapeForce)
            return  // Non fare altre correzioni
        }
        
        // Direzione tangenziale (perpendicolare al raggio) per movimento circolare
        let tangent = CGVector(dx: -toPlanet.dy, dy: toPlanet.dx)
        let tangentMagnitude = sqrt(tangent.dx * tangent.dx + tangent.dy * tangent.dy)
        
        // Velocità attuale
        let currentSpeed = sqrt(body.velocity.dx * body.velocity.dx + body.velocity.dy * body.velocity.dy)
        
        // Correzione radiale GENTILE per orbita fluida
        let radiusError = currentDistance - desiredOrbitRadius
        if abs(radiusError) > 30 {  // Tolleranza più ampia
            // Forza radiale proporzionale e gentile
            let correctionStrength: CGFloat = radiusError > 0 ? -150.0 : 150.0
            let radialForce = CGVector(
                dx: (toPlanet.dx / currentDistance) * correctionStrength,
                dy: (toPlanet.dy / currentDistance) * correctionStrength
            )
            body.applyForce(radialForce)
        }
        
        // Mantieni velocità orbitale con boost tangenziale
        if currentSpeed < orbitSpeed * 0.75 {
            let boostStrength: CGFloat = 350.0
            let boost = CGVector(
                dx: (tangent.dx / tangentMagnitude) * boostStrength,
                dy: (tangent.dy / tangentMagnitude) * boostStrength
            )
            body.applyForce(boost)
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
