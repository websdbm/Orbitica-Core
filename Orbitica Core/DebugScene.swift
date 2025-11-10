//
//  DebugScene.swift
//  Orbitica Core
//
//  Debug scene per selezionare la wave di partenza
//

import SpriteKit
import AVFoundation

class DebugScene: SKScene {
    
    // Wave selector
    private var selectedWave: Int = 1
    private var waveLabel: SKLabelNode!
    private var playButton: SKShapeNode!
    
    // Background selector
    private var selectedBackgroundIndex: Int = 0
    private var backgroundLabel: SKLabelNode!
    private var allEnvironments: [SpaceEnvironment] = []
    
    // Debouncing per evitare tap multipli
    private var lastTouchTime: TimeInterval = 0
    private let touchDebounceInterval: TimeInterval = 0.2  // 200ms tra tap
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // FERMA la musica del menu principale
        stopMenuMusic()
        
        // Titolo
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "WAVE SELECTOR"
        title.fontSize = 32
        title.fontColor = .cyan
        title.position = CGPoint(x: size.width / 2, y: size.height - 100)
        title.zPosition = 100
        addChild(title)
        
        // Istruzioni
        let instructions = SKLabelNode(fontNamed: "Courier")
        instructions.text = "Select starting wave"
        instructions.fontSize = 18
        instructions.fontColor = .white
        instructions.alpha = 0.7
        instructions.position = CGPoint(x: size.width / 2, y: size.height - 150)
        instructions.zPosition = 100
        addChild(instructions)
        
        // Wave selector UI
        createWaveSelector()
        
        // Background selector UI
        createBackgroundSelector()
        
        // Play button
        createPlayButton()
        
        // Close button
        createCloseButton()
    }
    
    private func createWaveSelector() {
        // Titolo WAVE
        let waveTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        waveTitle.text = "WAVE"
        waveTitle.fontSize = 18
        waveTitle.fontColor = .cyan
        waveTitle.position = CGPoint(x: size.width / 4, y: size.height - 200)
        waveTitle.zPosition = 100
        addChild(waveTitle)
        
        // Pulsante decrement (-) - LATO SINISTRO
        let decrementButton = SKShapeNode(rectOf: CGSize(width: 45, height: 45), cornerRadius: 8)
        decrementButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        decrementButton.strokeColor = .white
        decrementButton.lineWidth = 2
        decrementButton.position = CGPoint(x: size.width / 4 - 70, y: size.height - 260)
        decrementButton.name = "decrement"
        decrementButton.zPosition = 100
        addChild(decrementButton)
        
        let minusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        minusLabel.text = "-"
        minusLabel.fontSize = 28
        minusLabel.fontColor = .white
        minusLabel.verticalAlignmentMode = .center
        decrementButton.addChild(minusLabel)
        
        // Wave number display - LATO SINISTRO
        waveLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        waveLabel.text = "\(selectedWave)"
        waveLabel.fontSize = 48
        waveLabel.fontColor = .cyan
        waveLabel.position = CGPoint(x: size.width / 4, y: size.height - 260)
        waveLabel.verticalAlignmentMode = .center
        waveLabel.zPosition = 100
        addChild(waveLabel)
        
        // Pulsante increment (+) - LATO SINISTRO
        let incrementButton = SKShapeNode(rectOf: CGSize(width: 45, height: 45), cornerRadius: 8)
        incrementButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        incrementButton.strokeColor = .white
        incrementButton.lineWidth = 2
        incrementButton.position = CGPoint(x: size.width / 4 + 70, y: size.height - 260)
        incrementButton.name = "increment"
        incrementButton.zPosition = 100
        addChild(incrementButton)
        
        let plusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        plusLabel.text = "+"
        plusLabel.fontSize = 28
        plusLabel.fontColor = .white
        plusLabel.verticalAlignmentMode = .center
        incrementButton.addChild(plusLabel)
    }
    
    private func createBackgroundSelector() {
        // Inizializza array di ambienti - NUOVI ENHANCED PRIMA
        allEnvironments = [
            .cosmicNebula, .nebulaGalaxy, .animatedCosmos, .deepSpaceEnhanced,  // ⭐ NUOVI ENHANCED
            .deepSpace, .nebula, .voidSpace, .redGiant,
            .asteroidBelt, .binaryStars, .ionStorm, .pulsarField,
            .planetarySystem, .cometTrail, .darkMatterCloud, .supernovaRemnant
        ]
        
        // Titolo sezione background - LATO DESTRO
        let bgTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        bgTitle.text = "BACKGROUND"
        bgTitle.fontSize = 18
        bgTitle.fontColor = .yellow
        bgTitle.position = CGPoint(x: size.width * 3/4, y: size.height - 200)
        bgTitle.zPosition = 100
        addChild(bgTitle)
        
        // Pulsante decrement (◄) - LATO DESTRO
        let prevButton = SKShapeNode(rectOf: CGSize(width: 45, height: 45), cornerRadius: 8)
        prevButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        prevButton.strokeColor = .yellow
        prevButton.lineWidth = 2
        prevButton.position = CGPoint(x: size.width * 3/4 - 80, y: size.height - 260)
        prevButton.name = "bg_prev"
        prevButton.zPosition = 100
        addChild(prevButton)
        
        let prevLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        prevLabel.text = "◄"
        prevLabel.fontSize = 24
        prevLabel.fontColor = .yellow
        prevLabel.verticalAlignmentMode = .center
        prevButton.addChild(prevLabel)
        
        // Label ambiente corrente - LATO DESTRO
        backgroundLabel = SKLabelNode(fontNamed: "Courier")
        backgroundLabel.text = allEnvironments[selectedBackgroundIndex].name
        backgroundLabel.fontSize = 12
        backgroundLabel.fontColor = .white
        backgroundLabel.position = CGPoint(x: size.width * 3/4, y: size.height - 260)
        backgroundLabel.verticalAlignmentMode = .center
        backgroundLabel.preferredMaxLayoutWidth = 100
        backgroundLabel.numberOfLines = 2
        backgroundLabel.zPosition = 100
        addChild(backgroundLabel)
        
        // Pulsante increment (►) - LATO DESTRO
        let nextButton = SKShapeNode(rectOf: CGSize(width: 45, height: 45), cornerRadius: 8)
        nextButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        nextButton.strokeColor = .yellow
        nextButton.lineWidth = 2
        nextButton.position = CGPoint(x: size.width * 3/4 + 80, y: size.height - 260)
        nextButton.name = "bg_next"
        nextButton.zPosition = 100
        addChild(nextButton)
        
        let nextLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        nextLabel.text = "►"
        nextLabel.fontSize = 24
        nextLabel.fontColor = .yellow
        nextLabel.verticalAlignmentMode = .center
        nextButton.addChild(nextLabel)
        
        // Applica il primo ambiente
        applyBackgroundPreview(allEnvironments[selectedBackgroundIndex])
    }
    
    private func createPlayButton() {
        playButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 15)
        playButton.fillColor = UIColor.green.withAlphaComponent(0.3)
        playButton.strokeColor = .green
        playButton.lineWidth = 3
        playButton.position = CGPoint(x: size.width / 2, y: 120)
        playButton.name = "play"
        playButton.zPosition = 100
        addChild(playButton)
        
        let playLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        playLabel.text = "PLAY"
        playLabel.fontSize = 28
        playLabel.fontColor = .green
        playLabel.verticalAlignmentMode = .center
        playButton.addChild(playLabel)
        
        // Animazione pulse
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.6),
            SKAction.scale(to: 1.0, duration: 0.6)
        ])
        playButton.run(SKAction.repeatForever(pulse))
    }
    
    private func createCloseButton() {
        let closeButton = SKShapeNode(circleOfRadius: 20)
        closeButton.fillColor = UIColor.red.withAlphaComponent(0.3)
        closeButton.strokeColor = .red
        closeButton.lineWidth = 2
        closeButton.position = CGPoint(x: size.width - 40, y: size.height - 40)
        closeButton.name = "closeButton"
        closeButton.zPosition = 1000
        addChild(closeButton)
        
        let xLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        xLabel.text = "X"
        xLabel.fontSize = 20
        xLabel.fontColor = .red
        xLabel.verticalAlignmentMode = .center
        xLabel.horizontalAlignmentMode = .center
        closeButton.addChild(xLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // Debouncing: ignora tap troppo ravvicinati
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastTouchTime >= touchDebounceInterval else {
            return
        }
        lastTouchTime = currentTime
        
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "closeButton" {
                // Torna al menu principale
                let transition = SKTransition.fade(withDuration: 0.5)
                let menuScene = MainMenuScene(size: size)
                menuScene.scaleMode = scaleMode
                view?.presentScene(menuScene, transition: transition)
                return
            } else if node.name == "decrement" || node.parent?.name == "decrement" {
                // Decrementa wave (minimo 1)
                if selectedWave > 1 {
                    selectedWave -= 1
                    waveLabel.text = "\(selectedWave)"
                    // Feedback visivo
                    animateButtonPress(node: node.name == "decrement" ? node : node.parent!)
                }
            } else if node.name == "increment" || node.parent?.name == "increment" {
                // Incrementa wave (massimo 20)
                if selectedWave < 20 {
                    selectedWave += 1
                    waveLabel.text = "\(selectedWave)"
                    // Feedback visivo
                    animateButtonPress(node: node.name == "increment" ? node : node.parent!)
                }
            } else if node.name == "play" || node.parent?.name == "play" {
                // Avvia il gioco dalla wave selezionata
                startGameAtWave(selectedWave)
            } else if node.name == "bg_prev" || node.parent?.name == "bg_prev" {
                // Background precedente
                selectedBackgroundIndex = (selectedBackgroundIndex - 1 + allEnvironments.count) % allEnvironments.count
                backgroundLabel.text = allEnvironments[selectedBackgroundIndex].name
                applyBackgroundPreview(allEnvironments[selectedBackgroundIndex])
                animateButtonPress(node: node.name == "bg_prev" ? node : node.parent!)
            } else if node.name == "bg_next" || node.parent?.name == "bg_next" {
                // Background successivo
                selectedBackgroundIndex = (selectedBackgroundIndex + 1) % allEnvironments.count
                backgroundLabel.text = allEnvironments[selectedBackgroundIndex].name
                applyBackgroundPreview(allEnvironments[selectedBackgroundIndex])
                animateButtonPress(node: node.name == "bg_next" ? node : node.parent!)
            }
        }
    }
    
    private func animateButtonPress(node: SKNode) {
        let scale = SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        node.run(scale)
    }
    
    private func stopMenuMusic() {
        // Ferma tutti i player audio attivi
        NotificationCenter.default.post(name: NSNotification.Name("StopMenuMusic"), object: nil)
    }
    
    private func startGameAtWave(_ wave: Int) {
        let transition = SKTransition.fade(withDuration: 0.5)
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .aspectFill
        gameScene.startingWave = wave  // Passa la wave di partenza
        view?.presentScene(gameScene, transition: transition)
    }
    
    private func applyBackgroundPreview(_ environment: SpaceEnvironment) {
        // Rimuovi tutti i layer di background esistenti (tag con zPosition < 0)
        enumerateChildNodes(withName: "//*") { node, _ in
            if node.zPosition < 0 {
                node.removeFromParent()
            }
        }
        
        // Crea un GameScene temporaneo per generare il background
        // Usiamo un trucco: creiamo l'ambiente direttamente qui
        // copiando la logica da GameScene
        
        switch environment {
        case .cosmicNebula:
            applyCosmicNebula()
        case .animatedCosmos:
            applyAnimatedCosmos()
        case .deepSpaceEnhanced:
            applyDeepSpaceEnhanced()
        case .nebulaGalaxy:
            applyNebulaGalaxy()
        case .deepSpace:
            applyDeepSpace()
        case .nebula:
            applyNebula()
        case .voidSpace:
            applyVoidSpace()
        case .redGiant:
            applyRedGiant()
        case .asteroidBelt:
            applyAsteroidBelt()
        case .binaryStars:
            applyBinaryStars()
        case .ionStorm:
            applyIonStorm()
        case .pulsarField:
            applyPulsarField()
        case .planetarySystem:
            applyPlanetarySystem()
        case .cometTrail:
            applyCometTrail()
        case .darkMatterCloud:
            applyDarkMatterCloud()
        case .supernovaRemnant:
            applySupernovaRemnant()
        }
    }
    
    // NUOVO: Animated Cosmos preview - Sistema solare realistico
    private func applyAnimatedCosmos() {
        backgroundColor = .black
        
        // Stelle di sfondo
        addSimpleStars(count: 80, colorRange: [.white])
        
        // Nebulosa distante
        let nebula = SKShapeNode(circleOfRadius: 180)
        nebula.fillColor = UIColor(red: 0.35, green: 0.25, blue: 0.65, alpha: 0.1)
        nebula.strokeColor = .clear
        nebula.glowWidth = 60
        nebula.position = CGPoint(x: size.width * 0.25, y: size.height * 0.75)
        nebula.zPosition = -60
        addChild(nebula)
        
        let nebulaRotate = SKAction.rotate(byAngle: .pi * 2, duration: 120)
        nebula.run(SKAction.repeatForever(nebulaRotate))
        
        // SISTEMA SOLARE REALISTICO (versione preview)
        createRealisticPreviewSolarSystem()
        
        // Indicatore "NEW"
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = "★ REALISTIC SOLAR SYSTEM ★"
        label.fontSize = 11
        label.fontColor = .yellow
        label.alpha = 0.7
        label.position = CGPoint(x: size.width / 2, y: 50)
        label.zPosition = 100
        addChild(label)
    }
    
    private func createRealisticPreviewSolarSystem() {
        let systemNode = SKNode()
        
        // POSIZIONE RANDOM come nel gioco
        let quadrants: [(x: CGFloat, y: CGFloat)] = [
            (size.width * 0.20, size.height * 0.75),
            (size.width * 0.80, size.height * 0.75),
            (size.width * 0.20, size.height * 0.25),
            (size.width * 0.80, size.height * 0.25)
        ]
        let chosenQuadrant = quadrants.randomElement()!
        systemNode.position = CGPoint(x: chosenQuadrant.x, y: chosenQuadrant.y)
        
        systemNode.zPosition = -50
        systemNode.setScale(2.0)  // Grande
        systemNode.alpha = 1.0    // Opacità piena, colori scuri
        
        // Sole centrale - silhouette visibile
        let sunSize: CGFloat = 18
        let sun = SKShapeNode(circleOfRadius: sunSize)
        sun.fillColor = UIColor(red: 0.22, green: 0.18, blue: 0.12, alpha: 1.0)
        sun.strokeColor = UIColor(red: 0.28, green: 0.22, blue: 0.15, alpha: 0.6)
        sun.lineWidth = 1.5
        sun.glowWidth = sunSize * 0.3
        systemNode.addChild(sun)
        
        // Corona solare
        let corona = SKShapeNode(circleOfRadius: sunSize * 1.3)
        corona.fillColor = UIColor(red: 0.18, green: 0.15, blue: 0.12, alpha: 0.3)
        corona.strokeColor = .clear
        corona.glowWidth = 5
        systemNode.addChild(corona)
        
        // Pulsazione sole LENTA
        let sunPulse = SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 5.0),
            SKAction.scale(to: 1.0, duration: 5.0)
        ])
        sun.run(SKAction.repeatForever(sunPulse))
        corona.run(SKAction.repeatForever(sunPulse))
        
        // Pianeti con velocità RALLENTATE e colori SCURI come nel gioco
        let planets: [(distance: CGFloat, size: CGFloat, color: UIColor, speed: Double, hasRings: Bool, startAngle: CGFloat)] = [
            (45, 2.5, UIColor(red: 0.18, green: 0.17, blue: 0.16, alpha: 1.0), 30, false, 0),              // Mercurio
            (65, 3.5, UIColor(red: 0.22, green: 0.20, blue: 0.16, alpha: 1.0), 44, false, .pi / 3),        // Venere
            (90, 4, UIColor(red: 0.12, green: 0.15, blue: 0.20, alpha: 1.0), 60, false, .pi * 2 / 3),      // Terra
            (115, 3, UIColor(red: 0.20, green: 0.12, blue: 0.10, alpha: 1.0), 84, false, .pi),             // Marte
            (150, 8, UIColor(red: 0.19, green: 0.17, blue: 0.15, alpha: 1.0), 130, false, .pi * 4 / 3),    // Giove
            (190, 7, UIColor(red: 0.20, green: 0.19, blue: 0.15, alpha: 1.0), 170, true, .pi * 5 / 3)      // Saturno
        ]
        
        for planet in planets {
            // Container orbita con SFASAMENTO INIZIALE
            let orbitContainer = SKNode()
            orbitContainer.zRotation = planet.startAngle
            systemNode.addChild(orbitContainer)
            
            // Orbita circolare PIÙ VISIBILE
            let orbitCircle = SKShapeNode(circleOfRadius: planet.distance)
            orbitCircle.strokeColor = UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 0.35)
            orbitCircle.lineWidth = 0.6
            orbitCircle.fillColor = .clear
            orbitCircle.glowWidth = 0.2
            systemNode.addChild(orbitCircle)
            
            // Pianeta - silhouette scura
            let planetNode = SKShapeNode(circleOfRadius: planet.size)
            planetNode.fillColor = planet.color
            planetNode.strokeColor = planet.color.withAlphaComponent(0.4)
            planetNode.lineWidth = 0.3
            planetNode.glowWidth = planet.size * 0.1
            planetNode.position = CGPoint(x: planet.distance, y: 0)
            orbitContainer.addChild(planetNode)
            
            // Anelli (Saturno) - scuri
            if planet.hasRings {
                let ring = SKShapeNode(circleOfRadius: planet.size * 2)
                ring.strokeColor = planet.color.withAlphaComponent(0.4)
                ring.lineWidth = planet.size * 0.4
                ring.fillColor = .clear
                planetNode.addChild(ring)
                
                // Anello interno
                let innerRing = SKShapeNode(circleOfRadius: planet.size * 1.5)
                innerRing.strokeColor = planet.color.withAlphaComponent(0.25)
                innerRing.lineWidth = planet.size * 0.25
                innerRing.fillColor = .clear
                planetNode.addChild(innerRing)
            }
            
            // Orbita RALLENTATA
            let orbit = SKAction.rotate(byAngle: .pi * 2, duration: planet.speed)
            orbitContainer.run(SKAction.repeatForever(orbit))
            
            // Auto-rotazione
            let rotation = SKAction.rotate(byAngle: .pi * 2, duration: planet.speed / 20)
            planetNode.run(SKAction.repeatForever(rotation))
        }
        
        addChild(systemNode)
    }
    
    private func createDebugEllipsePath(radiusX: CGFloat, radiusY: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let segments = 48
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
    
    // Cosmic Nebula con sprite nebula02 + particelle
    private func applyCosmicNebula() {
        backgroundColor = .black
        
        // Stelle di sfondo
        addSimpleStars(count: 80, colorRange: [.white])
        
        // Nebulosa sprite (nebula02)
        print("🔍 [DebugScene] Tentativo caricamento nebula02.png")
        if let imagePath = Bundle.main.path(forResource: "nebula02", ofType: "png") {
            print("✅ [DebugScene] PNG trovato: \(imagePath)")
        } else {
            print("❌ [DebugScene] nebula02.png NON trovata")
        }
        
        let nebulaTexture = SKTexture(imageNamed: "nebula02")
        print("🔍 [DebugScene] Texture size: \(nebulaTexture.size())")
        let nebula = SKSpriteNode(texture: nebulaTexture)
        nebula.position = CGPoint(x: size.width * 0.6, y: size.height * 0.5)
        nebula.setScale(1.5)
        nebula.alpha = 0.3
        nebula.blendMode = .add
        nebula.zPosition = -60
        addChild(nebula)
        
        // Rotazione lenta
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 90)
        nebula.run(SKAction.repeatForever(rotate))
        
        // Particelle dust (semplificate per preview)
        for _ in 0..<20 {
            let dust = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            dust.fillColor = UIColor(red: 0.6, green: 0.4, blue: 0.7, alpha: 0.3)
            dust.strokeColor = .clear
            dust.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            dust.zPosition = -50
            addChild(dust)
            
            // Movimento lento
            let duration = Double.random(in: 20...30)
            let moveBy = CGVector(dx: CGFloat.random(in: -50...50), dy: CGFloat.random(in: -50...50))
            let move = SKAction.move(by: moveBy, duration: duration)
            let moveBack = move.reversed()
            dust.run(SKAction.repeatForever(SKAction.sequence([move, moveBack])))
        }
        
        // Indicatore
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "COSMIC NEBULA"
        label.fontSize = 16
        label.fontColor = UIColor(red: 0.8, green: 0.6, blue: 0.9, alpha: 1.0)
        label.position = CGPoint(x: size.width/2, y: 30)
        label.zPosition = 200
        addChild(label)
    }
    
    // Nebula Galaxy con sprite nebula01 + particelle
    private func applyNebulaGalaxy() {
        backgroundColor = .black
        
        // Stelle di sfondo
        addSimpleStars(count: 80, colorRange: [.white])
        
        // Nebulosa sprite
        print("🔍 [DebugScene] Tentativo caricamento nebula01.png")
        if let imagePath = Bundle.main.path(forResource: "nebula01", ofType: "png") {
            print("✅ [DebugScene] PNG trovato: \(imagePath)")
        } else {
            print("❌ [DebugScene] nebula01.png NON trovata")
        }
        
        let nebulaTexture = SKTexture(imageNamed: "nebula01")
        print("🔍 [DebugScene] Texture size: \(nebulaTexture.size())")
        let nebula = SKSpriteNode(texture: nebulaTexture)
        nebula.position = CGPoint(x: size.width * 0.6, y: size.height * 0.5)
        nebula.setScale(1.5)
        nebula.alpha = 0.3
        nebula.blendMode = .add
        nebula.zPosition = -60
        addChild(nebula)
        
        // Rotazione lenta
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 90)
        nebula.run(SKAction.repeatForever(rotate))
        
        // Particelle dust (semplificate per preview)
        for _ in 0..<20 {
            let dust = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            dust.fillColor = UIColor(red: 0.6, green: 0.4, blue: 0.7, alpha: 0.3)
            dust.strokeColor = .clear
            dust.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            dust.zPosition = -55
            addChild(dust)
            
            // Movimento lento
            let moveX = CGFloat.random(in: -30...30)
            let moveY = CGFloat.random(in: -30...30)
            let move = SKAction.moveBy(x: moveX, y: moveY, duration: Double.random(in: 20...30))
            let moveBack = move.reversed()
            dust.run(SKAction.repeatForever(SKAction.sequence([move, moveBack])))
        }
        
        // Indicatore
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = "★ NEBULA + PARTICLES ★"
        label.fontSize = 11
        label.fontColor = UIColor(red: 0.8, green: 0.5, blue: 0.9, alpha: 1.0)
        label.alpha = 0.7
        label.position = CGPoint(x: size.width / 2, y: 50)
        label.zPosition = 100
        addChild(label)
    }
    
    // Deep Space Enhanced con stelle parallax animate
    private func applyDeepSpaceEnhanced() {
        backgroundColor = .black
        
        // Stelle di sfondo statiche
        addSimpleStars(count: 100, colorRange: [.white])
        
        // PARALLAX STARS ANIMATE (semplificato per debug)
        createDebugParallaxStars()
        
        // Indicatore
        let label = SKLabelNode(fontNamed: "Courier")
        label.text = "★ PARALLAX STARS ★"
        label.fontSize = 12
        label.fontColor = .cyan
        label.alpha = 0.5
        label.position = CGPoint(x: size.width / 2, y: 50)
        label.zPosition = 100
        addChild(label)
    }
    
    private func createDebugParallaxStars() {
        // 3 layer di stelle che si muovono a velocità diverse (da destra a sinistra)
        let speeds: [CGFloat] = [30, 60, 100]  // Pixel per secondo
        let scales: [CGFloat] = [1.0, 1.5, 2.0]
        let counts: [Int] = [15, 10, 7]
        
        for i in 0..<3 {
            for _ in 0..<counts[i] {
                let star = SKShapeNode(circleOfRadius: scales[i])
                star.fillColor = i == 2 ? UIColor.cyan.withAlphaComponent(0.6) : UIColor.white.withAlphaComponent(0.5)
                star.strokeColor = .clear
                star.position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                )
                star.zPosition = CGFloat(-80 + i * 10)
                
                // Movimento orizzontale continuo (da destra a sinistra)
                let duration = size.width / speeds[i]
                let moveLeft = SKAction.moveBy(x: -size.width - 100, y: 0, duration: TimeInterval(duration))
                let resetPosition = SKAction.moveBy(x: size.width + 100, y: 0, duration: 0)
                let sequence = SKAction.sequence([moveLeft, resetPosition])
                star.run(SKAction.repeatForever(sequence))
                
                addChild(star)
            }
        }
    }
    
    private func applyDeepSpace() {
        backgroundColor = .black
        addSimpleStars(count: 100, colorRange: [.white, .cyan, .yellow])
    }
    
    private func applyNebula() {
        backgroundColor = .black
        // Nebulosa viola-blu
        let nebula = SKShapeNode(ellipseOf: CGSize(width: 600, height: 400))
        nebula.fillColor = UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 0.3)
        nebula.strokeColor = .clear
        nebula.position = CGPoint(x: size.width / 2, y: size.height / 2)
        nebula.zPosition = -40
        nebula.glowWidth = 50
        addChild(nebula)
        addSimpleStars(count: 80, colorRange: [.white, .cyan])
    }
    
    private func applyVoidSpace() {
        // Gradiente nero-blu
        backgroundColor = UIColor(red: 0.0, green: 0.05, blue: 0.15, alpha: 1.0)
        addSimpleStars(count: 90, colorRange: [.white, UIColor(white: 0.9, alpha: 1.0)])
    }
    
    private func applyRedGiant() {
        // Rosso scuro
        backgroundColor = UIColor(red: 0.15, green: 0.05, blue: 0.0, alpha: 1.0)
        // Alone rosso
        let glow = SKShapeNode(circleOfRadius: 200)
        glow.fillColor = UIColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 0.2)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: size.width / 2 + 300, y: size.height / 2)
        glow.zPosition = -35
        glow.glowWidth = 80
        addChild(glow)
        addSimpleStars(count: 60, colorRange: [UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0)])
    }
    
    private func applyAsteroidBelt() {
        backgroundColor = UIColor(red: 0.08, green: 0.06, blue: 0.05, alpha: 1.0)
        // Asteroidi sparsi
        for _ in 0..<15 {
            let asteroid = SKShapeNode(circleOfRadius: CGFloat.random(in: 10...30))
            asteroid.fillColor = UIColor(white: 0.2, alpha: 0.3)
            asteroid.strokeColor = UIColor(white: 0.3, alpha: 0.4)
            asteroid.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height))
            asteroid.zPosition = -30
            addChild(asteroid)
        }
        addSimpleStars(count: 50, colorRange: [.white])
    }
    
    private func applyBinaryStars() {
        backgroundColor = .black
        // Stella blu
        let blueStar = SKShapeNode(circleOfRadius: 80)
        blueStar.fillColor = UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.4)
        blueStar.strokeColor = .clear
        blueStar.position = CGPoint(x: size.width / 2 - 150, y: size.height / 2)
        blueStar.zPosition = -35
        blueStar.glowWidth = 60
        addChild(blueStar)
        
        // Stella gialla
        let yellowStar = SKShapeNode(circleOfRadius: 80)
        yellowStar.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.4)
        yellowStar.strokeColor = .clear
        yellowStar.position = CGPoint(x: size.width / 2 + 150, y: size.height / 2)
        yellowStar.zPosition = -35
        yellowStar.glowWidth = 60
        addChild(yellowStar)
        
        addSimpleStars(count: 70, colorRange: [.white, .cyan, .yellow])
    }
    
    private func applyIonStorm() {
        backgroundColor = UIColor(red: 0.05, green: 0.0, blue: 0.15, alpha: 1.0)
        // Particelle verdi/ciano
        for _ in 0..<30 {
            let ion = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            ion.fillColor = UIColor(red: 0.2, green: 0.9, blue: 0.7, alpha: 0.6)
            ion.strokeColor = .clear
            ion.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height))
            ion.zPosition = -30
            ion.glowWidth = 8
            addChild(ion)
            
            // Scintillio
            let fade = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 0.5),
                SKAction.fadeAlpha(to: 0.8, duration: 0.5)
            ])
            ion.run(SKAction.repeatForever(fade))
        }
        addSimpleStars(count: 40, colorRange: [.white])
    }
    
    private func applyPulsarField() {
        backgroundColor = UIColor(red: 0.0, green: 0.02, blue: 0.08, alpha: 1.0)
        // Anelli pulsanti
        for i in 0..<3 {
            let ring = SKShapeNode(circleOfRadius: CGFloat(100 + i * 80))
            ring.strokeColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.3)
            ring.fillColor = .clear
            ring.lineWidth = 2
            ring.position = CGPoint(x: size.width / 2, y: size.height / 2)
            ring.zPosition = -30
            ring.glowWidth = 10
            addChild(ring)
            
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.1, duration: 1.0),
                SKAction.fadeAlpha(to: 0.6, duration: 0.3)
            ])
            ring.run(SKAction.repeatForever(pulse))
        }
        addSimpleStars(count: 50, colorRange: [.white, .cyan])
    }
    
    private func applyPlanetarySystem() {
        backgroundColor = .black
        // 3 pianeti semplificati
        let planets: [(x: CGFloat, y: CGFloat, radius: CGFloat, color: UIColor)] = [
            (size.width / 2 - 200, size.height / 2, 20, UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)),
            (size.width / 2, size.height / 2 + 150, 30, UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0)),
            (size.width / 2 + 180, size.height / 2 - 100, 25, UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0))
        ]
        
        for planet in planets {
            let p = SKShapeNode(circleOfRadius: planet.radius)
            p.fillColor = planet.color
            p.strokeColor = planet.color.withAlphaComponent(0.5)
            p.position = CGPoint(x: planet.x, y: planet.y)
            p.zPosition = -30
            p.glowWidth = planet.radius * 0.5
            addChild(p)
        }
        addSimpleStars(count: 80, colorRange: [.white])
    }
    
    private func applyCometTrail() {
        backgroundColor = .black
        // Cometa con scia
        let comet = SKShapeNode(circleOfRadius: 10)
        comet.fillColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
        comet.strokeColor = .white
        comet.position = CGPoint(x: size.width * 0.3, y: size.height * 0.7)
        comet.zPosition = -30
        comet.glowWidth = 20
        addChild(comet)
        
        // Scia simulata
        for i in 0..<10 {
            let trail = SKShapeNode(circleOfRadius: CGFloat(8 - i/2))
            trail.fillColor = UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: CGFloat(0.6 - Double(i) * 0.05))
            trail.strokeColor = .clear
            trail.position = CGPoint(x: comet.position.x + CGFloat(i * 15), y: comet.position.y - CGFloat(i * 10))
            trail.zPosition = -31
            addChild(trail)
        }
        addSimpleStars(count: 100, colorRange: [.white, .cyan])
    }
    
    private func applyDarkMatterCloud() {
        backgroundColor = UIColor(red: 0.02, green: 0.0, blue: 0.05, alpha: 1.0)
        // Nuvole viola
        for _ in 0..<3 {
            let cloud = SKShapeNode(circleOfRadius: CGFloat.random(in: 100...200))
            cloud.fillColor = UIColor(red: 0.15, green: 0.05, blue: 0.25, alpha: 0.2)
            cloud.strokeColor = UIColor(red: 0.3, green: 0.1, blue: 0.4, alpha: 0.3)
            cloud.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height))
            cloud.zPosition = -35
            cloud.glowWidth = 40
            addChild(cloud)
        }
        addSimpleStars(count: 40, colorRange: [UIColor(red: 0.7, green: 0.6, blue: 0.9, alpha: 1.0)])
    }
    
    private func applySupernovaRemnant() {
        backgroundColor = UIColor(red: 0.05, green: 0.0, blue: 0.0, alpha: 1.0)
        // Nucleo luminoso
        let core = SKShapeNode(circleOfRadius: 20)
        core.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.8, alpha: 1.0)
        core.strokeColor = UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 0.8)
        core.lineWidth = 3
        core.position = CGPoint(x: size.width / 2, y: size.height / 2)
        core.zPosition = -30
        core.glowWidth = 40
        addChild(core)
        
        // Anelli esplosivi
        let colors = [
            UIColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 0.4),
            UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.3),
            UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 0.25)
        ]
        
        for (i, color) in colors.enumerated() {
            let ring = SKShapeNode(circleOfRadius: CGFloat(80 + i * 60))
            ring.strokeColor = color
            ring.fillColor = .clear
            ring.lineWidth = CGFloat(6 - i)
            ring.position = core.position
            ring.zPosition = -31
            ring.glowWidth = 15
            addChild(ring)
        }
        
        addSimpleStars(count: 60, colorRange: [.white, UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0)])
    }
    
    private func addSimpleStars(count: Int, colorRange: [UIColor]) {
        for _ in 0..<count {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2))
            star.fillColor = colorRange.randomElement()!.withAlphaComponent(CGFloat.random(in: 0.3...0.7))
            star.strokeColor = .clear
            star.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height))
            star.zPosition = -40
            addChild(star)
        }
    }
}
