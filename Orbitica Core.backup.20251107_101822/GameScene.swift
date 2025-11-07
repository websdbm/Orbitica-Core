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
        case .large: return 40
        case .medium: return 25
        case .small: return 15
        }
    }
    
    var points: Int {
        switch self {
        case .large: return 20
        case .medium: return 15
        case .small: return 10
        }
    }
    
    var mass: CGFloat {
        switch self {
        case .large: return 100
        case .medium: return 50
        case .small: return 20
        }
    }
}

// MARK: - Game Scene
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game entities
    private var planet: SKShapeNode!
    private var atmosphere: SKShapeNode!
    private var player: SKShapeNode!
    private var playerShield: SKShapeNode!
    
    // Game state
    private var asteroids: [SKShapeNode] = []
    private var projectiles: [SKShapeNode] = []
    private var currentWave = 1
    private var score = 0
    private var planetHealth = 3
    private var atmosphereRadius: CGFloat = 80
    private var maxAtmosphereRadius: CGFloat = 80
    private var minAtmosphereRadius: CGFloat = 40
    
    // UI
    private var scoreLabel: SKLabelNode!
    private var waveLabel: SKLabelNode!
    private var healthLabel: SKLabelNode!
    
    // Camera
    private var gameCamera: SKCameraNode!
    private var baseZoom: CGFloat = 1.0
    private var currentZoom: CGFloat = 1.0
    private var maxZoom: CGFloat = 3.0
    
    // Physics
    private let planetRadius: CGFloat = 40
    private let planetMass: CGFloat = 10000
    private let gravitationalConstant: CGFloat = 80 // Ridotta ulteriormente da 150
    
    // Controls
    private var joystick: JoystickNode!
    private var fireButton: FireButtonNode!
    private var joystickDirection = CGVector.zero
    private var isFiring = false
    private var lastFireTime: TimeInterval = 0
    private let fireRate: TimeInterval = 0.2
    
    // Colors (monocromatico retrò)
    private let bgColor = SKColor.black
    private let planetColor = SKColor.white
    private let atmosphereColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.6)
    private let playerColor = SKColor.white
    private let asteroidColor = SKColor.white
    private let projectileColor = SKColor.white
    
    // MARK: - Setup
    override func didMove(to view: SKView) {
        backgroundColor = bgColor
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        print("=== SCENE SETUP ===")
        print("Scene size: \(size)")
        print("Scene frame: \(frame)")
        print("View bounds: \(view.bounds)")
        print("Scene anchor point: \(anchorPoint)")
        
        setupCamera()
        setupPlanet()
        setupAtmosphere()
        setupPlayer()
        setupUI()
        setupControls()
        
        startWave(1)
    }
    
    private func setupCamera() {
        gameCamera = SKCameraNode()
        camera = gameCamera
        addChild(gameCamera)
        
        // IMPORTANTE: i controlli NON devono essere figli della camera
        // così rimangono fissi sullo schermo
    }
    
    private func setupPlanet() {
        planet = SKShapeNode(circleOfRadius: planetRadius)
        planet.fillColor = planetColor
        planet.strokeColor = planetColor
        planet.lineWidth = 2
        planet.position = .zero
        planet.zPosition = 1
        
        // Physics
        planet.physicsBody = SKPhysicsBody(circleOfRadius: planetRadius)
        planet.physicsBody?.isDynamic = false
        planet.physicsBody?.categoryBitMask = PhysicsCategory.planet
        planet.physicsBody?.contactTestBitMask = PhysicsCategory.asteroid
        planet.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        addChild(planet)
    }
    
    private func setupAtmosphere() {
        atmosphere = SKShapeNode(circleOfRadius: atmosphereRadius)
        atmosphere.fillColor = .clear
        atmosphere.strokeColor = atmosphereColor
        atmosphere.lineWidth = 3
        atmosphere.position = .zero
        atmosphere.zPosition = 2
        atmosphere.glowWidth = 2
        
        // Physics
        atmosphere.physicsBody = SKPhysicsBody(circleOfRadius: atmosphereRadius)
        atmosphere.physicsBody?.isDynamic = false
        atmosphere.physicsBody?.categoryBitMask = PhysicsCategory.atmosphere
        atmosphere.physicsBody?.contactTestBitMask = PhysicsCategory.asteroid | PhysicsCategory.player | PhysicsCategory.projectile
        atmosphere.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        addChild(atmosphere)
        
        // Pulsazione atmosfera
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 2.0),
            SKAction.scale(to: 1.0, duration: 2.0)
        ])
        atmosphere.run(SKAction.repeatForever(pulse))
    }
    
    private func setupPlayer() {
        // Nave triangolare
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 15))
        path.addLine(to: CGPoint(x: -8, y: -10))
        path.addLine(to: CGPoint(x: 8, y: -10))
        path.closeSubpath()
        
        player = SKShapeNode(path: path)
        player.fillColor = .clear
        player.strokeColor = playerColor
        player.lineWidth = 2
        
        // Posizione random a distanza fissa dal pianeta
        let randomAngle = CGFloat.random(in: 0...(2 * .pi))
        let spawnDistance: CGFloat = 200
        player.position = CGPoint(
            x: cos(randomAngle) * spawnDistance,
            y: sin(randomAngle) * spawnDistance
        )
        player.zPosition = 10
        
        // Barriera circolare
        playerShield = SKShapeNode(circleOfRadius: 20)
        playerShield.fillColor = .clear
        playerShield.strokeColor = playerColor.withAlphaComponent(0.3)
        playerShield.lineWidth = 1
        playerShield.zPosition = -1
        player.addChild(playerShield)
        
        // Physics
        player.physicsBody = SKPhysicsBody(circleOfRadius: 15)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.mass = 10
        player.physicsBody?.linearDamping = 0.3 // Aumentato per movimento più controllato
        player.physicsBody?.angularDamping = 0.5
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.asteroid | PhysicsCategory.atmosphere
        player.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        addChild(player)
    }
    
    private func setupUI() {
        // Score
        scoreLabel = SKLabelNode(fontNamed: "Courier-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.text = "SCORE: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: -size.width/2 + 20, y: size.height/2 - 40)
        scoreLabel.zPosition = 100
        gameCamera.addChild(scoreLabel)
        
        // Wave
        waveLabel = SKLabelNode(fontNamed: "Courier-Bold")
        waveLabel.fontSize = 24
        waveLabel.fontColor = .white
        waveLabel.text = "WAVE: 1"
        waveLabel.horizontalAlignmentMode = .right
        waveLabel.position = CGPoint(x: size.width/2 - 20, y: size.height/2 - 40)
        waveLabel.zPosition = 100
        gameCamera.addChild(waveLabel)
        
        // Health
        healthLabel = SKLabelNode(fontNamed: "Courier-Bold")
        healthLabel.fontSize = 24
        healthLabel.fontColor = .white
        healthLabel.text = "PLANET: ❤️❤️❤️"
        healthLabel.horizontalAlignmentMode = .center
        healthLabel.position = CGPoint(x: 0, y: size.height/2 - 40)
        healthLabel.zPosition = 100
        gameCamera.addChild(healthLabel)
    }
    
    private func setupControls() {
        // I controlli devono essere posizionati in coordinate della scena
        // Con anchor point (0,0) in basso a sinistra
        
        guard let view = self.view else { return }
        
        print("=== CONTROLS SETUP ===")
        print("Scene size: \(size)")
        print("View bounds: \(view.bounds)")
        
        // Joystick - angolo in basso a sinistra (coordinate assolute della scena)
        joystick = JoystickNode(baseRadius: 60, thumbRadius: 25)
        joystick.position = CGPoint(x: 100, y: 100)
        joystick.zPosition = 10000
        joystick.onMove = { [weak self] direction in
            self?.joystickDirection = direction
            print("Joystick direction: \(direction)")
        }
        joystick.onEnd = { [weak self] in
            self?.joystickDirection = .zero
            print("Joystick released")
        }
        addChild(joystick)
        
        // Fire button - angolo in basso a destra (coordinate assolute della scena)
        // La scena è 926x428 in landscape, quindi il fire button deve essere vicino al bordo destro
        fireButton = FireButtonNode(radius: 50)
        fireButton.position = CGPoint(x: size.width - 100, y: 100)
        fireButton.zPosition = 10000
        fireButton.onPress = { [weak self] in
            self?.isFiring = true
            print("🔥 Fire!")
        }
        fireButton.onRelease = { [weak self] in
            self?.isFiring = false
        }
        addChild(fireButton)
        
        print("Joystick positioned at: \(joystick.position)")
        print("Fire button positioned at: \(fireButton.position)")
        print("Scene is landscape: \(size.width) x \(size.height)")
        print("==================")
    }
    
    // MARK: - Wave System
    private func startWave(_ wave: Int) {
        currentWave = wave
        waveLabel.text = "WAVE: \(wave)"
        
        // Mostra messaggio wave
        let message = SKLabelNode(fontNamed: "Courier-Bold")
        message.fontSize = 48
        message.fontColor = atmosphereColor
        message.text = "WAVE \(wave)"
        message.position = .zero
        message.zPosition = 200
        message.alpha = 0
        gameCamera.addChild(message)
        
        let appear = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        message.run(appear)
        
        // Genera asteroidi
        let asteroidCount = 3 + (wave * 2)
        for i in 0..<asteroidCount {
            let delay = Double(i) * 0.5
            run(SKAction.wait(forDuration: delay)) { [weak self] in
                self?.spawnAsteroid(size: .large)
            }
        }
    }
    
    private func spawnAsteroid(size: AsteroidSize, at position: CGPoint? = nil) {
        // Crea forma a linee spezzate (stile Asteroids)
        let path = createAsteroidPath(radius: size.radius)
        let asteroid = SKShapeNode(path: path)
        asteroid.fillColor = .clear
        asteroid.strokeColor = asteroidColor
        asteroid.lineWidth = 2
        asteroid.zPosition = 5
        asteroid.name = "asteroid_\(size.rawValue)"
        
        // Posizione ai margini
        if let pos = position {
            asteroid.position = pos
        } else {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = frame.width
            asteroid.position = CGPoint(
                x: cos(angle) * distance,
                y: sin(angle) * distance
            )
        }
        
        // Physics
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: size.radius)
        asteroid.physicsBody?.isDynamic = true
        asteroid.physicsBody?.mass = size.mass
        asteroid.physicsBody?.linearDamping = 0.0
        asteroid.physicsBody?.angularDamping = 0.0
        asteroid.physicsBody?.categoryBitMask = PhysicsCategory.asteroid
        asteroid.physicsBody?.contactTestBitMask = PhysicsCategory.planet | PhysicsCategory.atmosphere | PhysicsCategory.player | PhysicsCategory.projectile | PhysicsCategory.asteroid
        asteroid.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        // Velocità orbitale iniziale
        let toCenter = CGPoint(x: -asteroid.position.x, y: -asteroid.position.y)
        let distance = hypot(toCenter.x, toCenter.y)
        let normalizedDirection = CGPoint(x: toCenter.x / distance, y: toCenter.y / distance)
        let perpendicular = CGPoint(x: -normalizedDirection.y, y: normalizedDirection.x)
        
        let orbitalSpeed = CGFloat.random(in: 50...100)
        let radialSpeed = CGFloat.random(in: -20...(-5))
        
        asteroid.physicsBody?.velocity = CGVector(
            dx: perpendicular.x * orbitalSpeed + normalizedDirection.x * radialSpeed,
            dy: perpendicular.y * orbitalSpeed + normalizedDirection.y * radialSpeed
        )
        
        addChild(asteroid)
        asteroids.append(asteroid)
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
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            // Passa il touch ai controlli
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
        // TEMPORANEAMENTE DISABILITATO per debug
        // updateControlsPosition() // Mantieni controlli fissi
        updatePlayerMovement()
        updatePlayerShooting(currentTime)
        applyGravity()
        wrapObjects()
        updateCamera()
        checkWaveCompletion()
        cleanupProjectiles()
    }
    
    private func updateControlsPosition() {
        // Mantieni i controlli negli angoli dello schermo
        guard let cam = camera, let view = self.view else { return }
        
        let camPos = cam.position
        let zoom = cam.xScale
        let viewWidth = view.bounds.width * zoom
        let viewHeight = view.bounds.height * zoom
        
        // Joystick sempre in basso a sinistra
        joystick.position = CGPoint(
            x: camPos.x - viewWidth/2 + 100,
            y: camPos.y - viewHeight/2 + 100
        )
        
        // Fire button sempre in basso a destra
        fireButton.position = CGPoint(
            x: camPos.x + viewWidth/2 - 100,
            y: camPos.y - viewHeight/2 + 100
        )
    }
    
    private func updatePlayerMovement() {
        let magnitude = hypot(joystickDirection.dx, joystickDirection.dy)
        
        if magnitude > 0.1 {
            // Normalizza la direzione
            let normalizedDx = joystickDirection.dx / magnitude
            let normalizedDy = joystickDirection.dy / magnitude
            
            // Thrust proporzionale allo spostamento del joystick
            let maxThrust: CGFloat = 400 // Aumentato!
            let thrust = maxThrust * magnitude
            
            // IMPORTANTE: verifica che il player abbia un physicsBody
            guard let body = player.physicsBody else {
                print("⚠️ Player has no physics body!")
                return
            }
            
            body.applyForce(CGVector(
                dx: normalizedDx * thrust,
                dy: normalizedDy * thrust
            ))
            
            // Orienta la nave nella direzione del joystick
            let angle = atan2(joystickDirection.dy, joystickDirection.dx) + .pi / 2
            player.zRotation = angle
            
            // Debug
            print("🚀 Applying force: \(thrust), velocity: \(body.velocity)")
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
        let projectile = SKShapeNode(circleOfRadius: 3)
        projectile.fillColor = projectileColor
        projectile.strokeColor = projectileColor
        
        // Posizione davanti alla nave (nella direzione di movimento)
        let angle = player.zRotation - .pi / 2
        let offset: CGFloat = 20
        projectile.position = CGPoint(
            x: player.position.x + cos(angle) * offset,
            y: player.position.y + sin(angle) * offset
        )
        projectile.zPosition = 8
        projectile.name = "projectile"
        
        // Physics - NO GRAVITÀ
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: 3)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.mass = 0.1
        projectile.physicsBody?.linearDamping = 0.0
        projectile.physicsBody?.affectedByGravity = false
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.asteroid | PhysicsCategory.atmosphere
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        // Velocità in linea retta nella direzione della nave
        let speed: CGFloat = 500
        let velocity = CGVector(
            dx: cos(angle) * speed,
            dy: sin(angle) * speed
        )
        projectile.physicsBody?.velocity = velocity
        
        addChild(projectile)
        projectiles.append(projectile)
        
        // Auto-distruzione dopo 3 secondi
        projectile.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.removeFromParent()
        ]))
    }
    
    private func applyGravity() {
        // Applica gravità a player
        applyGravityToNode(player)
        
        // NON applicare gravità ai proiettili - rimosso completamente
        
        // Applica gravità agli asteroidi
        for asteroid in asteroids {
            applyGravityToNode(asteroid)
            
            // Gravità locale da asteroidi grandi
            if asteroid.name?.contains("3") == true {
                applyLocalGravityFrom(asteroid)
            }
        }
    }
    
    private func applyGravityToNode(_ node: SKShapeNode) {
        guard let body = node.physicsBody else { return }
        
        let dx = planet.position.x - node.position.x
        let dy = planet.position.y - node.position.y
        let distanceSquared = dx * dx + dy * dy
        let distance = sqrt(distanceSquared)
        
        if distance > 1 {
            let forceMagnitude = (gravitationalConstant * planetMass * body.mass) / distanceSquared
            let forceX = (dx / distance) * forceMagnitude
            let forceY = (dy / distance) * forceMagnitude
            
            body.applyForce(CGVector(dx: forceX, dy: forceY))
        }
    }
    
    private func applyLocalGravityFrom(_ largeAsteroid: SKShapeNode) {
        guard let asteroidBody = largeAsteroid.physicsBody else { return }
        let localGravity: CGFloat = 50
        
        for asteroid in asteroids where asteroid != largeAsteroid {
            guard let body = asteroid.physicsBody else { continue }
            
            let dx = largeAsteroid.position.x - asteroid.position.x
            let dy = largeAsteroid.position.y - asteroid.position.y
            let distanceSquared = dx * dx + dy * dy
            let distance = sqrt(distanceSquared)
            
            if distance > 1 && distance < 200 {
                let forceMagnitude = (localGravity * asteroidBody.mass * body.mass) / distanceSquared
                let forceX = (dx / distance) * forceMagnitude
                let forceY = (dy / distance) * forceMagnitude
                
                body.applyForce(CGVector(dx: forceX, dy: forceY))
            }
        }
    }
    
    private func wrapObjects() {
        let margin: CGFloat = 100
        let maxDistance = frame.width * maxZoom
        
        wrapNode(player, maxDistance: maxDistance, margin: margin)
        
        for asteroid in asteroids {
            wrapNode(asteroid, maxDistance: maxDistance, margin: margin)
        }
    }
    
    private func wrapNode(_ node: SKShapeNode, maxDistance: CGFloat, margin: CGFloat) {
        let pos = node.position
        var wrapped = false
        var newX = pos.x
        var newY = pos.y
        
        if pos.x > maxDistance + margin {
            newX = -maxDistance - margin
            wrapped = true
        } else if pos.x < -maxDistance - margin {
            newX = maxDistance + margin
            wrapped = true
        }
        
        if pos.y > maxDistance + margin {
            newY = -maxDistance - margin
            wrapped = true
        } else if pos.y < -maxDistance - margin {
            newY = maxDistance + margin
            wrapped = true
        }
        
        if wrapped {
            node.position = CGPoint(x: newX, y: newY)
        }
    }
    
    private func updateCamera() {
        // Segui il player
        let playerDistance = hypot(player.position.x, player.position.y)
        // Zoom OUT quando si allontana, zoom IN quando si avvicina
        let targetZoom = max(1.0, min(maxZoom, 1.0 + (playerDistance / 300)))
        currentZoom = currentZoom * 0.95 + targetZoom * 0.05
        
        gameCamera.setScale(currentZoom)
        
        // Posiziona camera sul player (con smoothing)
        let targetX = player.position.x * 0.3
        let targetY = player.position.y * 0.3
        gameCamera.position.x = gameCamera.position.x * 0.9 + targetX * 0.1
        gameCamera.position.y = gameCamera.position.y * 0.9 + targetY * 0.1
    }
    
    private func checkWaveCompletion() {
        if asteroids.isEmpty {
            currentWave += 1
            startWave(currentWave)
        }
    }
    
    private func cleanupProjectiles() {
        projectiles.removeAll { $0.parent == nil }
    }
    
    // MARK: - Physics Contact
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        // Projectile hits asteroid
        if (bodyA.categoryBitMask == PhysicsCategory.projectile && bodyB.categoryBitMask == PhysicsCategory.asteroid) ||
           (bodyB.categoryBitMask == PhysicsCategory.projectile && bodyA.categoryBitMask == PhysicsCategory.asteroid) {
            
            let projectile = bodyA.categoryBitMask == PhysicsCategory.projectile ? bodyA.node : bodyB.node
            let asteroid = bodyA.categoryBitMask == PhysicsCategory.asteroid ? bodyA.node : bodyB.node
            
            if let proj = projectile as? SKShapeNode, let ast = asteroid as? SKShapeNode {
                handleProjectileHitAsteroid(proj, asteroid: ast)
            }
        }
        
        // Asteroid hits planet
        if (bodyA.categoryBitMask == PhysicsCategory.asteroid && bodyB.categoryBitMask == PhysicsCategory.planet) ||
           (bodyB.categoryBitMask == PhysicsCategory.asteroid && bodyA.categoryBitMask == PhysicsCategory.planet) {
            
            let asteroid = bodyA.categoryBitMask == PhysicsCategory.asteroid ? bodyA.node : bodyB.node
            if let ast = asteroid as? SKShapeNode {
                handleAsteroidHitPlanet(ast)
            }
        }
        
        // Asteroid/Player/Projectile hits atmosphere
        if bodyA.categoryBitMask == PhysicsCategory.atmosphere || bodyB.categoryBitMask == PhysicsCategory.atmosphere {
            let other = bodyA.categoryBitMask == PhysicsCategory.atmosphere ? bodyB : bodyA
            
            if other.categoryBitMask == PhysicsCategory.asteroid ||
               other.categoryBitMask == PhysicsCategory.player ||
               other.categoryBitMask == PhysicsCategory.projectile {
                handleAtmosphereBounce(other.node as? SKShapeNode)
            }
        }
        
        // Asteroid hits asteroid
        if bodyA.categoryBitMask == PhysicsCategory.asteroid && bodyB.categoryBitMask == PhysicsCategory.asteroid {
            if let ast1 = bodyA.node as? SKShapeNode, let ast2 = bodyB.node as? SKShapeNode {
                handleAsteroidCollision(ast1, asteroid2: ast2)
            }
        }
    }
    
    private func handleProjectileHitAsteroid(_ projectile: SKShapeNode, asteroid: SKShapeNode) {
        // Rimuovi proiettile
        projectile.removeFromParent()
        projectiles.removeAll { $0 == projectile }
        
        // Frammenta asteroide
        fragmentAsteroid(asteroid)
        
        // Effetto visivo
        createExplosion(at: asteroid.position, color: asteroidColor)
    }
    
    private func fragmentAsteroid(_ asteroid: SKShapeNode) {
        guard let sizeString = asteroid.name?.split(separator: "_").last,
              let sizeRaw = Int(sizeString),
              let size = AsteroidSize(rawValue: sizeRaw) else { return }
        
        // Aggiungi punti
        score += size.points
        scoreLabel.text = "SCORE: \(score)"
        
        let position = asteroid.position
        let velocity = asteroid.physicsBody?.velocity ?? .zero
        
        asteroid.removeFromParent()
        asteroids.removeAll { $0 == asteroid }
        
        // Crea frammenti
        if size != .small {
            let nextSize: AsteroidSize = size == .large ? .medium : .small
            let fragmentCount = Int.random(in: 2...3)
            
            for i in 0..<fragmentCount {
                let angle = (CGFloat(i) / CGFloat(fragmentCount)) * 2 * .pi
                let offset = CGPoint(
                    x: cos(angle) * size.radius,
                    y: sin(angle) * size.radius
                )
                
                let fragmentPosition = CGPoint(
                    x: position.x + offset.x,
                    y: position.y + offset.y
                )
                
                spawnAsteroid(size: nextSize, at: fragmentPosition)
                
                // Applica velocità ereditata + esplosione
                if let fragment = asteroids.last {
                    let explosionForce: CGFloat = 150
                    fragment.physicsBody?.velocity = CGVector(
                        dx: velocity.dx + cos(angle) * explosionForce,
                        dy: velocity.dy + sin(angle) * explosionForce
                    )
                }
            }
        }
    }
    
    private func handleAsteroidHitPlanet(_ asteroid: SKShapeNode) {
        asteroid.removeFromParent()
        asteroids.removeAll { $0 == asteroid }
        
        // Danno al pianeta solo se atmosfera è debole
        if atmosphereRadius <= minAtmosphereRadius {
            planetHealth -= 1
            updateHealthDisplay()
            
            createExplosion(at: planet.position, color: .red)
            
            if planetHealth <= 0 {
                gameOver()
            }
        }
    }
    
    private func handleAtmosphereBounce(_ node: SKShapeNode?) {
        guard let node = node, let body = node.physicsBody else { return }
        
        // Rimbalzo sull'atmosfera
        let dx = node.position.x - planet.position.x
        let dy = node.position.y - planet.position.y
        let distance = hypot(dx, dy)
        
        if distance > 1 {
            let normal = CGPoint(x: dx / distance, y: dy / distance)
            let velocity = body.velocity
            let dotProduct = velocity.dx * normal.x + velocity.dy * normal.y
            
            let reflection = CGVector(
                dx: velocity.dx - 2 * dotProduct * normal.x,
                dy: velocity.dy - 2 * dotProduct * normal.y
            )
            
            body.velocity = reflection
            
            // Riduce atmosfera
            atmosphereRadius = max(minAtmosphereRadius, atmosphereRadius - 2)
            updateAtmosphere()
            
            // Bonus punti
            if node.name?.contains("asteroid") == true {
                score += 5
                scoreLabel.text = "SCORE: \(score)"
            }
            
            // Rigenera atmosfera se è player o projectile
            if node == player || node.name == "projectile" {
                atmosphereRadius = min(maxAtmosphereRadius, atmosphereRadius + 3)
                updateAtmosphere()
            }
            
            // Effetto visivo
            createImpactEffect(at: node.position)
        }
    }
    
    private func handleAsteroidCollision(_ asteroid1: SKShapeNode, asteroid2: SKShapeNode) {
        // Calcola velocità relativa
        guard let body1 = asteroid1.physicsBody, let body2 = asteroid2.physicsBody else { return }
        
        let relativeVelocity = hypot(body1.velocity.dx - body2.velocity.dx, body1.velocity.dy - body2.velocity.dy)
        
        // Effetto visivo se impatto forte
        if relativeVelocity > 100 {
            let midPoint = CGPoint(
                x: (asteroid1.position.x + asteroid2.position.x) / 2,
                y: (asteroid1.position.y + asteroid2.position.y) / 2
            )
            createImpactEffect(at: midPoint)
        }
        
        // Defletti traiettorie
        let dx = asteroid2.position.x - asteroid1.position.x
        let dy = asteroid2.position.y - asteroid1.position.y
        let distance = hypot(dx, dy)
        
        if distance > 1 {
            let normal = CGPoint(x: dx / distance, y: dy / distance)
            let pushForce: CGFloat = 50
            
            body1.applyImpulse(CGVector(dx: -normal.x * pushForce, dy: -normal.y * pushForce))
            body2.applyImpulse(CGVector(dx: normal.x * pushForce, dy: normal.y * pushForce))
        }
    }
    
    private func updateAtmosphere() {
        atmosphere.removeFromParent()
        setupAtmosphere()
        
        // Update physics radius
        atmosphere.physicsBody = SKPhysicsBody(circleOfRadius: atmosphereRadius)
        atmosphere.physicsBody?.isDynamic = false
        atmosphere.physicsBody?.categoryBitMask = PhysicsCategory.atmosphere
        atmosphere.physicsBody?.contactTestBitMask = PhysicsCategory.asteroid | PhysicsCategory.player | PhysicsCategory.projectile
        atmosphere.physicsBody?.collisionBitMask = PhysicsCategory.none
    }
    
    private func updateHealthDisplay() {
        let hearts = String(repeating: "❤️", count: planetHealth)
        healthLabel.text = "PLANET: \(hearts)"
    }
    
    // MARK: - Visual Effects
    private func createExplosion(at position: CGPoint, color: SKColor) {
        for _ in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = color
            particle.strokeColor = color
            particle.position = position
            particle.zPosition = 50
            addChild(particle)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 20...40)
            let targetPos = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let move = SKAction.move(to: targetPos, duration: 0.5)
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            
            particle.run(SKAction.sequence([SKAction.group([move, fade]), remove]))
        }
    }
    
    private func createImpactEffect(at position: CGPoint) {
        let flash = SKShapeNode(circleOfRadius: 10)
        flash.fillColor = atmosphereColor
        flash.strokeColor = .clear
        flash.position = position
        flash.zPosition = 20
        flash.alpha = 0.8
        addChild(flash)
        
        let expand = SKAction.scale(to: 2.0, duration: 0.2)
        let fade = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        
        flash.run(SKAction.sequence([SKAction.group([expand, fade]), remove]))
    }
    
    private func gameOver() {
        // Ferma tutto
        isPaused = true
        
        let gameOverLabel = SKLabelNode(fontNamed: "Courier-Bold")
        gameOverLabel.fontSize = 64
        gameOverLabel.fontColor = .red
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.position = .zero
        gameOverLabel.zPosition = 300
        gameCamera.addChild(gameOverLabel)
        
        let finalScore = SKLabelNode(fontNamed: "Courier-Bold")
        finalScore.fontSize = 32
        finalScore.fontColor = .white
        finalScore.text = "Final Score: \(score)"
        finalScore.position = CGPoint(x: 0, y: -50)
        finalScore.zPosition = 300
        gameCamera.addChild(finalScore)
        
        let restart = SKLabelNode(fontNamed: "Courier-Bold")
        restart.fontSize = 24
        restart.fontColor = atmosphereColor
        restart.text = "Tap to Restart"
        restart.position = CGPoint(x: 0, y: -100)
        restart.zPosition = 300
        restart.name = "restart"
        gameCamera.addChild(restart)
        
        // Blink effect
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        restart.run(SKAction.repeatForever(blink))
    }
}
