//
//  PlanetVisuals.swift
//  Orbitica Core
//
//  Sistema di rendering avanzato per Terra e Atmosfera
//  Tre stili visuali intercambiabili
//

import SpriteKit

// MARK: - Visual Style Enum

enum PlanetVisualStyle {
    case realistic      // Opzione 1: Terra realistica con texture e nuvole
    case neonCyber      // Opzione 2: Stile neon/cyber con griglia
    case procedural     // Opzione 3: Terra procedurale "viva"
}

// MARK: - Enhanced Planet Node

class EnhancedPlanetNode: SKNode {
    
    // Componenti visuali
    private var baseLayer: SKNode!          // Layer base della terra
    private var cloudsLayer: SKNode?        // Layer nuvole (opzionale)
    private var glowLayer: SKSpriteNode?    // Glow esterno
    private var cityLightsLayer: SKNode?    // Luci città (lato notturno)
    private var healthFilterNode: SKEffectNode? // Filtro colore per salute
    
    // Proprietà
    private let radius: CGFloat
    private var currentStyle: PlanetVisualStyle
    private var currentHealth: CGFloat = 100.0
    private var maxHealth: CGFloat = 100.0
    
    // MARK: - Initialization
    
    init(radius: CGFloat, style: PlanetVisualStyle = .realistic) {
        self.radius = radius
        self.currentStyle = style
        super.init()
        
        setupVisuals(for: style)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupVisuals(for style: PlanetVisualStyle) {
        removeAllChildren()
        
        switch style {
        case .realistic:
            setupRealisticEarth()
        case .neonCyber:
            setupNeonCyberEarth()
        case .procedural:
            setupProceduralEarth()
        }
    }
    
    // MARK: - Opzione 1: Terra Realistica
    
    private func setupRealisticEarth() {
        // Base: Terra con colori oceano/continenti
        baseLayer = SKNode()
        
        // Corpo principale della Terra
        let earthCore = SKShapeNode(circleOfRadius: radius)
        earthCore.fillColor = UIColor(red: 0.13, green: 0.29, blue: 0.53, alpha: 1.0) // Oceani blu scuro
        earthCore.strokeColor = .clear
        earthCore.name = "earthCore"
        baseLayer.addChild(earthCore)
        
        // Aggiungi "continenti" come forme irregolari
        addContinents(to: baseLayer)
        
        // Rotazione lenta della Terra
        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 120.0) // 2 minuti per rotazione completa
        baseLayer.run(SKAction.repeatForever(rotateAction))
        
        addChild(baseLayer)
        
        // Layer nuvole semi-trasparenti
        setupCloudsLayer()
        
        // Glow blu attorno al pianeta
        setupPlanetGlow(color: UIColor.cyan)
        
        // Filtro salute
        setupHealthFilter()
    }
    
    private func addContinents(to layer: SKNode) {
        // Continente 1 (Nord America style)
        let continent1 = createContinentShape(
            centerAngle: 0.3,
            angularSpread: 1.2,
            radialSpread: 0.4
        )
        continent1.fillColor = UIColor(red: 0.25, green: 0.5, blue: 0.25, alpha: 1.0) // Verde terra
        continent1.strokeColor = .clear
        layer.addChild(continent1)
        
        // Continente 2 (Europa/Africa style)
        let continent2 = createContinentShape(
            centerAngle: 1.8,
            angularSpread: 1.5,
            radialSpread: 0.5
        )
        continent2.fillColor = UIColor(red: 0.30, green: 0.48, blue: 0.23, alpha: 1.0)
        continent2.strokeColor = .clear
        layer.addChild(continent2)
        
        // Continente 3 (Asia style)
        let continent3 = createContinentShape(
            centerAngle: 3.5,
            angularSpread: 1.8,
            radialSpread: 0.45
        )
        continent3.fillColor = UIColor(red: 0.28, green: 0.52, blue: 0.27, alpha: 1.0)
        continent3.strokeColor = .clear
        layer.addChild(continent3)
        
        // Calotte polari bianche
        let northPole = SKShapeNode(circleOfRadius: radius * 0.15)
        northPole.position = CGPoint(x: 0, y: radius * 0.8)
        northPole.fillColor = .white
        northPole.strokeColor = .clear
        layer.addChild(northPole)
        
        let southPole = SKShapeNode(circleOfRadius: radius * 0.15)
        southPole.position = CGPoint(x: 0, y: -radius * 0.8)
        southPole.fillColor = .white
        southPole.strokeColor = .clear
        layer.addChild(southPole)
    }
    
    private func createContinentShape(centerAngle: CGFloat, angularSpread: CGFloat, radialSpread: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        let segments = 20
        let startAngle = centerAngle - angularSpread / 2
        
        var points: [CGPoint] = []
        
        for i in 0...segments {
            let angle = startAngle + (angularSpread * CGFloat(i) / CGFloat(segments))
            // Raggio variabile per forma irregolare
            let variation = CGFloat.random(in: 0.7...1.0)
            let r = radius * radialSpread * variation
            let x = cos(angle) * r
            let y = sin(angle) * r
            points.append(CGPoint(x: x, y: y))
        }
        
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        
        return SKShapeNode(path: path)
    }
    
    private func setupCloudsLayer() {
        cloudsLayer = SKNode()
        
        // Crea 8-12 nuvole sparse
        for _ in 0..<10 {
            let cloud = createCloudSprite()
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = radius * CGFloat.random(in: 0.5...0.9)
            cloud.position = CGPoint(
                x: cos(angle) * distance,
                y: sin(angle) * distance
            )
            cloudsLayer?.addChild(cloud)
        }
        
        // Rotazione nuvole leggermente più veloce della Terra
        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 90.0)
        cloudsLayer?.run(SKAction.repeatForever(rotateAction))
        
        if let clouds = cloudsLayer {
            addChild(clouds)
        }
    }
    
    private func createCloudSprite() -> SKShapeNode {
        let cloudSize = radius * CGFloat.random(in: 0.1...0.2)
        let cloud = SKShapeNode(circleOfRadius: cloudSize)
        cloud.fillColor = UIColor.white.withAlphaComponent(0.4)
        cloud.strokeColor = .clear
        return cloud
    }
    
    private func setupPlanetGlow(color: UIColor) {
        // Crea un glow usando SKSpriteNode con texture generata
        let glowSize = radius * 2.4
        let glowTexture = createRadialGradientTexture(size: CGSize(width: glowSize, height: glowSize), color: color)
        
        glowLayer = SKSpriteNode(texture: glowTexture)
        glowLayer?.size = CGSize(width: glowSize, height: glowSize)
        glowLayer?.zPosition = -1
        glowLayer?.alpha = 0.6
        
        // Pulse effect sul glow
        let pulseUp = SKAction.scale(to: 1.1, duration: 2.0)
        let pulseDown = SKAction.scale(to: 1.0, duration: 2.0)
        let pulse = SKAction.sequence([pulseUp, pulseDown])
        glowLayer?.run(SKAction.repeatForever(pulse))
        
        if let glow = glowLayer {
            addChild(glow)
        }
    }
    
    private func createRadialGradientTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            
            // Disegna cerchi concentrici con alpha decrescente
            for i in stride(from: 1.0, to: 0.0, by: -0.05) {
                let currentRadius = (size.width / 2) * i
                let alpha = (1.0 - i) * 0.3 // Alpha massimo 0.3 al centro
                
                color.withAlphaComponent(alpha).setFill()
                let circlePath = UIBezierPath(
                    arcCenter: center,
                    radius: currentRadius,
                    startAngle: 0,
                    endAngle: .pi * 2,
                    clockwise: true
                )
                circlePath.fill()
            }
        }
        
        return SKTexture(image: image)
    }
    
    private func setupHealthFilter() {
        // SKEffectNode per applicare filtri colore basati sulla salute
        healthFilterNode = SKEffectNode()
        healthFilterNode?.shouldEnableEffects = true
        // Inizialmente nessun filtro (salute piena)
        updateHealthFilter(healthPercentage: 1.0)
    }
    
    // MARK: - Opzione 2: Neon Cyber (Placeholder)
    
    private func setupNeonCyberEarth() {
        // TODO: Implementare nella prossima fase
        print("🔷 Neon Cyber Earth style - Coming soon")
    }
    
    // MARK: - Opzione 3: Procedurale (Placeholder)
    
    private func setupProceduralEarth() {
        // TODO: Implementare nella prossima fase
        print("🌿 Procedural Earth style - Coming soon")
    }
    
    // MARK: - Update Methods
    
    func updateHealth(current: CGFloat, max: CGFloat) {
        self.currentHealth = current
        self.maxHealth = max
        let percentage = current / max
        
        updateHealthFilter(healthPercentage: percentage)
        updateGlowIntensity(healthPercentage: percentage)
    }
    
    private func updateHealthFilter(healthPercentage: CGFloat) {
        guard let filterNode = healthFilterNode else { return }
        
        // Cambia il tint in base alla salute
        if healthPercentage > 0.75 {
            // Salute alta: nessun filtro
            filterNode.filter = nil
        } else if healthPercentage > 0.50 {
            // Salute media-alta: leggero giallo
            let colorize = CIFilter(name: "CIColorMonochrome")
            colorize?.setValue(CIColor(red: 1.0, green: 0.9, blue: 0.7), forKey: "inputColor")
            colorize?.setValue(0.2, forKey: "inputIntensity")
            filterNode.filter = colorize
        } else if healthPercentage > 0.25 {
            // Salute media-bassa: arancione
            let colorize = CIFilter(name: "CIColorMonochrome")
            colorize?.setValue(CIColor(red: 1.0, green: 0.6, blue: 0.3), forKey: "inputColor")
            colorize?.setValue(0.4, forKey: "inputIntensity")
            filterNode.filter = colorize
        } else {
            // Salute critica: rosso + desaturazione
            let colorize = CIFilter(name: "CIColorMonochrome")
            colorize?.setValue(CIColor(red: 1.0, green: 0.2, blue: 0.2), forKey: "inputColor")
            colorize?.setValue(0.6, forKey: "inputIntensity")
            filterNode.filter = colorize
        }
    }
    
    private func updateGlowIntensity(healthPercentage: CGFloat) {
        // Glow più debole con salute bassa
        glowLayer?.alpha = 0.3 + (healthPercentage * 0.3)
    }
    
    func switchStyle(to style: PlanetVisualStyle) {
        currentStyle = style
        setupVisuals(for: style)
        updateHealth(current: currentHealth, max: maxHealth)
    }
}

// MARK: - Enhanced Atmosphere System

class EnhancedAtmosphereNode: SKNode {
    
    // Layer multipli dell'atmosfera
    private var innerLayer: SKShapeNode!
    private var middleLayer: SKShapeNode!
    private var outerLayer: SKShapeNode!
    private var particleEmitters: [SKEmitterNode] = []
    
    private let radius: CGFloat
    private var currentEnergy: CGFloat = 100.0
    private var maxEnergy: CGFloat = 100.0
    
    // MARK: - Initialization
    
    init(radius: CGFloat) {
        self.radius = radius
        super.init()
        
        setupAtmosphereLayers()
        setupParticleEffects()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupAtmosphereLayers() {
        // Layer esterno (più grande, più trasparente)
        outerLayer = SKShapeNode(circleOfRadius: radius * 1.15)
        outerLayer.fillColor = .clear
        outerLayer.strokeColor = UIColor.cyan.withAlphaComponent(0.4)
        outerLayer.lineWidth = 3
        outerLayer.glowWidth = 8
        outerLayer.zPosition = -1
        addChild(outerLayer)
        
        // Layer medio
        middleLayer = SKShapeNode(circleOfRadius: radius * 1.08)
        middleLayer.fillColor = UIColor.cyan.withAlphaComponent(0.08)
        middleLayer.strokeColor = UIColor.cyan.withAlphaComponent(0.6)
        middleLayer.lineWidth = 2
        middleLayer.glowWidth = 5
        middleLayer.zPosition = 0
        addChild(middleLayer)
        
        // Layer interno (più denso)
        innerLayer = SKShapeNode(circleOfRadius: radius * 1.02)
        innerLayer.fillColor = UIColor.cyan.withAlphaComponent(0.15)
        innerLayer.strokeColor = UIColor.cyan.withAlphaComponent(0.8)
        innerLayer.lineWidth = 2
        innerLayer.glowWidth = 3
        innerLayer.zPosition = 1
        addChild(innerLayer)
        
        // Animazioni pulse differenziate
        let outerPulse = createPulseAnimation(scale: 1.05, duration: 2.5)
        let middlePulse = createPulseAnimation(scale: 1.03, duration: 2.0)
        let innerPulse = createPulseAnimation(scale: 1.02, duration: 1.5)
        
        outerLayer.run(outerPulse)
        middleLayer.run(middlePulse)
        innerLayer.run(innerPulse)
    }
    
    private func createPulseAnimation(scale: CGFloat, duration: TimeInterval) -> SKAction {
        let up = SKAction.scale(to: scale, duration: duration)
        let down = SKAction.scale(to: 1.0, duration: duration)
        return SKAction.repeatForever(SKAction.sequence([up, down]))
    }
    
    private func setupParticleEffects() {
        // Particelle energetiche che orbitano nell'atmosfera
        for i in 0..<12 {
            let emitter = SKEmitterNode()
            emitter.particleTexture = SKTexture(imageNamed: "spark") // Fallback a pixel bianco
            emitter.particleBirthRate = 5
            emitter.particleLifetime = 3.0
            emitter.particleColor = .cyan
            emitter.particleColorBlendFactor = 1.0
            emitter.particleAlpha = 0.8
            emitter.particleScale = 0.3
            emitter.particleScaleSpeed = -0.1
            emitter.emissionAngle = CGFloat(i) * (.pi * 2 / 12)
            emitter.emissionAngleRange = .pi / 12
            
            // Posiziona sulla circonferenza
            let angle = CGFloat(i) * (.pi * 2 / 12)
            emitter.position = CGPoint(
                x: cos(angle) * radius * 1.1,
                y: sin(angle) * radius * 1.1
            )
            
            addChild(emitter)
            particleEmitters.append(emitter)
        }
        
        // Rotazione degli emitter
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 10.0)
        run(SKAction.repeatForever(rotate))
    }
    
    // MARK: - Update Methods
    
    func updateEnergy(current: CGFloat, max: CGFloat) {
        self.currentEnergy = current
        self.maxEnergy = max
        let percentage = current / max
        
        updateLayersAppearance(energyPercentage: percentage)
        updateParticleEffects(energyPercentage: percentage)
    }
    
    private func updateLayersAppearance(energyPercentage: CGFloat) {
        if energyPercentage > 1.0 {
            // OLTRE 100%: Overcharge effect
            let overchargeAmount = min((energyPercentage - 1.0) * 2, 0.5)
            
            innerLayer.strokeColor = UIColor.white.withAlphaComponent(0.8 + overchargeAmount)
            middleLayer.strokeColor = UIColor.cyan.withAlphaComponent(0.6 + overchargeAmount)
            outerLayer.strokeColor = UIColor.cyan.withAlphaComponent(0.4 + overchargeAmount)
            
            innerLayer.glowWidth = 3 + overchargeAmount * 5
            
        } else if energyPercentage > 0.75 {
            // 100-75%: Stato ottimale - Blu brillante
            innerLayer.strokeColor = UIColor.cyan.withAlphaComponent(0.8)
            innerLayer.fillColor = UIColor.cyan.withAlphaComponent(0.15)
            middleLayer.strokeColor = UIColor.cyan.withAlphaComponent(0.6)
            outerLayer.strokeColor = UIColor.cyan.withAlphaComponent(0.4)
            
        } else if energyPercentage > 0.50 {
            // 75-50%: Degradazione iniziale - Ciano con flickering
            innerLayer.strokeColor = UIColor(red: 0.3, green: 0.9, blue: 0.9, alpha: 0.7)
            innerLayer.fillColor = UIColor.cyan.withAlphaComponent(0.10)
            middleLayer.strokeColor = UIColor.cyan.withAlphaComponent(0.5)
            outerLayer.strokeColor = UIColor.cyan.withAlphaComponent(0.3)
            
            // Aggiungi flickering
            addFlickerEffect(to: innerLayer, intensity: 0.2)
            
        } else if energyPercentage > 0.25 {
            // 50-25%: Critico - Arancione con settori spenti
            innerLayer.strokeColor = UIColor.orange.withAlphaComponent(0.7)
            innerLayer.fillColor = UIColor.orange.withAlphaComponent(0.08)
            middleLayer.strokeColor = UIColor.orange.withAlphaComponent(0.4)
            outerLayer.strokeColor = UIColor.orange.withAlphaComponent(0.2)
            
            addFlickerEffect(to: innerLayer, intensity: 0.4)
            addFlickerEffect(to: middleLayer, intensity: 0.3)
            
        } else {
            // 25-0%: Collasso imminente - Rosso pulsante
            innerLayer.strokeColor = UIColor.red.withAlphaComponent(0.9)
            innerLayer.fillColor = UIColor.red.withAlphaComponent(0.1)
            middleLayer.strokeColor = UIColor.red.withAlphaComponent(0.5)
            outerLayer.strokeColor = UIColor.red.withAlphaComponent(0.2)
            
            // Warning pulse pesante
            addCriticalPulse()
        }
    }
    
    private func addFlickerEffect(to node: SKShapeNode, intensity: CGFloat) {
        node.removeAction(forKey: "flicker")
        
        let fadeOut = SKAction.fadeAlpha(to: 1.0 - intensity, duration: 0.1)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        let flicker = SKAction.sequence([fadeOut, fadeIn])
        
        node.run(SKAction.repeatForever(flicker), withKey: "flicker")
    }
    
    private func addCriticalPulse() {
        innerLayer.removeAction(forKey: "criticalPulse")
        
        let expand = SKAction.scale(to: 1.1, duration: 0.3)
        let shrink = SKAction.scale(to: 1.0, duration: 0.3)
        let wait = SKAction.wait(forDuration: 1.4)
        let pulse = SKAction.sequence([expand, shrink, wait])
        
        innerLayer.run(SKAction.repeatForever(pulse), withKey: "criticalPulse")
    }
    
    private func updateParticleEffects(energyPercentage: CGFloat) {
        for emitter in particleEmitters {
            if energyPercentage > 1.0 {
                // Overcharge: particelle bianche intense
                emitter.particleColor = .white
                emitter.particleBirthRate = 10
                emitter.particleAlpha = 1.0
            } else if energyPercentage > 0.75 {
                emitter.particleColor = .cyan
                emitter.particleBirthRate = 5
                emitter.particleAlpha = 0.8
            } else if energyPercentage > 0.50 {
                emitter.particleColor = UIColor(red: 0.3, green: 0.9, blue: 0.9, alpha: 1.0)
                emitter.particleBirthRate = 3
                emitter.particleAlpha = 0.6
            } else if energyPercentage > 0.25 {
                emitter.particleColor = .orange
                emitter.particleBirthRate = 2
                emitter.particleAlpha = 0.5
            } else {
                emitter.particleColor = .red
                emitter.particleBirthRate = 1
                emitter.particleAlpha = 0.4
            }
        }
    }
    
    // MARK: - Special Effects
    
    func playRechargeEffect() {
        // Effetto visivo quando si raccoglie powerup atmosfera
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.1),
            SKAction.fadeAlpha(to: 0.7, duration: 0.2)
        ])
        
        innerLayer.run(flash)
        
        // Onda espansiva
        let wave = SKShapeNode(circleOfRadius: radius)
        wave.strokeColor = .cyan
        wave.lineWidth = 4
        wave.fillColor = .clear
        wave.alpha = 0.8
        wave.zPosition = 10
        addChild(wave)
        
        let expand = SKAction.scale(to: 1.3, duration: 0.5)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        
        wave.run(SKAction.sequence([
            SKAction.group([expand, fade]),
            remove
        ]))
    }
    
    func playImpactEffect(at angle: CGFloat) {
        // Effetto quando un asteroide colpisce l'atmosfera
        let impact = SKShapeNode(circleOfRadius: 20)
        impact.position = CGPoint(
            x: cos(angle) * radius,
            y: sin(angle) * radius
        )
        impact.fillColor = .white
        impact.strokeColor = .clear
        impact.alpha = 0.9
        addChild(impact)
        
        let expand = SKAction.scale(to: 3.0, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        impact.run(SKAction.sequence([
            SKAction.group([expand, fade]),
            remove
        ]))
    }
}
