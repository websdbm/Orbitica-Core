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
        // Pulsante decrement (-)
        let decrementButton = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 10)
        decrementButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        decrementButton.strokeColor = .white
        decrementButton.lineWidth = 2
        decrementButton.position = CGPoint(x: size.width / 2 - 120, y: size.height - 250)
        decrementButton.name = "decrement"
        decrementButton.zPosition = 100
        addChild(decrementButton)
        
        let minusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        minusLabel.text = "-"
        minusLabel.fontSize = 36
        minusLabel.fontColor = .white
        minusLabel.verticalAlignmentMode = .center
        decrementButton.addChild(minusLabel)
        
        // Wave number display
        waveLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        waveLabel.text = "\(selectedWave)"
        waveLabel.fontSize = 72
        waveLabel.fontColor = .cyan
        waveLabel.position = CGPoint(x: size.width / 2, y: size.height - 250)
        waveLabel.verticalAlignmentMode = .center
        waveLabel.zPosition = 100
        addChild(waveLabel)
        
        // Pulsante increment (+)
        let incrementButton = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 10)
        incrementButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        incrementButton.strokeColor = .white
        incrementButton.lineWidth = 2
        incrementButton.position = CGPoint(x: size.width / 2 + 120, y: size.height - 250)
        incrementButton.name = "increment"
        incrementButton.zPosition = 100
        addChild(incrementButton)
        
        let plusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        plusLabel.text = "+"
        plusLabel.fontSize = 36
        plusLabel.fontColor = .white
        plusLabel.verticalAlignmentMode = .center
        incrementButton.addChild(plusLabel)
    }
    
    private func createBackgroundSelector() {
        // Inizializza array di ambienti
        allEnvironments = [
            .deepSpace, .nebula, .voidSpace, .redGiant,
            .asteroidBelt, .binaryStars, .ionStorm, .pulsarField,
            .planetarySystem, .cometTrail, .darkMatterCloud, .supernovaRemnant
        ]
        
        // Titolo sezione background
        let bgTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        bgTitle.text = "BACKGROUND"
        bgTitle.fontSize = 20
        bgTitle.fontColor = .yellow
        bgTitle.position = CGPoint(x: size.width / 2, y: size.height - 370)
        bgTitle.zPosition = 100
        addChild(bgTitle)
        
        // Pulsante decrement (◄)
        let prevButton = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 8)
        prevButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        prevButton.strokeColor = .yellow
        prevButton.lineWidth = 2
        prevButton.position = CGPoint(x: size.width / 2 - 150, y: size.height - 430)
        prevButton.name = "bg_prev"
        prevButton.zPosition = 100
        addChild(prevButton)
        
        let prevLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        prevLabel.text = "◄"
        prevLabel.fontSize = 28
        prevLabel.fontColor = .yellow
        prevLabel.verticalAlignmentMode = .center
        prevButton.addChild(prevLabel)
        
        // Label ambiente corrente
        backgroundLabel = SKLabelNode(fontNamed: "Courier")
        backgroundLabel.text = allEnvironments[selectedBackgroundIndex].name
        backgroundLabel.fontSize = 16
        backgroundLabel.fontColor = .white
        backgroundLabel.position = CGPoint(x: size.width / 2, y: size.height - 430)
        backgroundLabel.verticalAlignmentMode = .center
        backgroundLabel.zPosition = 100
        addChild(backgroundLabel)
        
        // Pulsante increment (►)
        let nextButton = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 8)
        nextButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        nextButton.strokeColor = .yellow
        nextButton.lineWidth = 2
        nextButton.position = CGPoint(x: size.width / 2 + 150, y: size.height - 430)
        nextButton.name = "bg_next"
        nextButton.zPosition = 100
        addChild(nextButton)
        
        let nextLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        nextLabel.text = "►"
        nextLabel.fontSize = 28
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
    
    // Helper rapido: applica solo background color e stelle base per preview
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
