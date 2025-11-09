//
//  MainMenuScene.swift
//  Orbitica Core
//
//  Created by Alessandro Grassi on 07/11/25.
//

import SpriteKit
import AVFoundation

class MainMenuScene: SKScene {
    
    // FLAG DEBUG: Imposta a false per nascondere il pulsante debug
    private let debugButtonEnabled: Bool = true
    
    private var titleLabel: SKLabelNode!
    private var subtitleLabel: SKLabelNode!
    private var playButton: SKShapeNode!
    private var playButtonLabel: SKLabelNode!
    private var hiScoreButton: SKShapeNode!
    private var hiScoreButtonLabel: SKLabelNode!
    private var debugButton: SKShapeNode?
    
    // Music player per sottofondo
    private var musicPlayer: AVAudioPlayer?
    private var isFadingOut = false
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        setupBackground()
        // setupOverlay() rimosso - lo sfondo ora è completamente visibile
        setupTitle()
        setupPlayButton()
        setupHiScoreButton()
        
        // Pulsante debug temporaneo
        if debugButtonEnabled {
            setupDebugButton()
        }
        
        // Avvia musica di sottofondo
        setupBackgroundMusic()
    }
    
    private func setupOverlay() {
        // Background semi-trasparente per far risaltare i testi
        let overlay = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.7), size: size)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 5  // Sopra lo sfondo ma sotto i testi
        addChild(overlay)
    }
    
    private func setupBackground() {
        // BACKGROUND RANDOMICO: sceglie casualmente tra gli sfondi disponibili
        let backgroundTypes = ["asteroidBelt", "deepSpace", "nebula", "voidSpace"]
        let chosenBackground = backgroundTypes.randomElement() ?? "asteroidBelt"
        
        switch chosenBackground {
        case "asteroidBelt":
            setupAsteroidBeltBackground()
        case "deepSpace":
            setupDeepSpaceBackground()
        case "nebula":
            setupNebulaBackground()
        case "voidSpace":
            setupVoidSpaceBackground()
        default:
            setupAsteroidBeltBackground()
        }
    }
    
    private func setupAsteroidBeltBackground() {
        // BACKGROUND ASTEROID BELT: grigio-marrone scuro
        backgroundColor = UIColor(red: 0.08, green: 0.06, blue: 0.05, alpha: 1.0)
        
        // Polvere spaziale sottile
        for _ in 0..<15 {
            let width = CGFloat.random(in: 100...250)
            let height = CGFloat.random(in: 60...120)
            
            let dust = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
            dust.fillColor = UIColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 0.05)
            dust.strokeColor = .clear
            dust.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            dust.zRotation = CGFloat.random(in: 0...(2 * .pi))
            dust.zPosition = -50
            addChild(dust)
        }
        
        // Asteroidi che ruotano e si muovono
        for i in 0..<12 {
            let asteroidSize = CGFloat.random(in: 15...40)
            let sides = Int.random(in: 5...8)
            
            let asteroid = SKShapeNode(circleOfRadius: asteroidSize)
            asteroid.path = createIrregularPolygonPath(radius: asteroidSize, sides: sides)
            asteroid.fillColor = UIColor(white: 0.15, alpha: CGFloat.random(in: 0.15...0.3))
            asteroid.strokeColor = UIColor(white: 0.25, alpha: 0.2)
            asteroid.lineWidth = 1
            asteroid.position = CGPoint(
                x: CGFloat.random(in: -50...size.width + 50),
                y: CGFloat.random(in: -50...size.height + 50)
            )
            asteroid.zPosition = -30 + CGFloat(i) * 0.5
            addChild(asteroid)
            
            // Rotazione continua
            let rotationDuration = Double.random(in: 8...15)
            let rotationDirection: CGFloat = Bool.random() ? 1 : -1
            let rotate = SKAction.rotate(byAngle: .pi * 2 * rotationDirection, duration: rotationDuration)
            asteroid.run(SKAction.repeatForever(rotate))
            
            // Movimento lento casuale
            let moveDistance: CGFloat = CGFloat.random(in: 30...80)
            let moveAngle = CGFloat.random(in: 0...(2 * .pi))
            let moveX = cos(moveAngle) * moveDistance
            let moveY = sin(moveAngle) * moveDistance
            let moveDuration = Double.random(in: 10...20)
            
            let moveAction = SKAction.moveBy(x: moveX, y: moveY, duration: moveDuration)
            let moveBack = SKAction.moveBy(x: -moveX, y: -moveY, duration: moveDuration)
            let moveSequence = SKAction.sequence([moveAction, moveBack])
            asteroid.run(SKAction.repeatForever(moveSequence))
        }
        
        // Stelle bianco-grigio opache (poche)
        for _ in 0..<30 {
            let starSize = CGFloat.random(in: 1...2.5)
            let star = SKShapeNode(circleOfRadius: starSize)
            star.fillColor = UIColor(white: CGFloat.random(in: 0.6...0.8), alpha: CGFloat.random(in: 0.15...0.25))
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            star.zPosition = -40
            addChild(star)
            
            // Twinkle occasionale
            if Bool.random() {
                let fadeOut = SKAction.fadeAlpha(to: 0.05, duration: Double.random(in: 1.5...3))
                let fadeIn = SKAction.fadeAlpha(to: star.alpha, duration: Double.random(in: 1.5...3))
                let twinkle = SKAction.sequence([fadeOut, fadeIn])
                star.run(SKAction.repeatForever(twinkle))
            }
        }
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
    
    private func setupTitle() {
        // Prova diversi nomi possibili per il font Orbitron (Variable Font)
        let possibleFontNames = [
            "Orbitron",           // Nome base
            "Orbitron-Bold",      // Variante Bold
            "Orbitron-Regular",   // Variante Regular
            "OrbitronVariable",   // Possibile nome per variable font
            "AvenirNext-Bold"     // Fallback
        ]
        var fontName = "AvenirNext-Bold" // Fallback di default
        
        for name in possibleFontNames {
            if UIFont(name: name, size: 12) != nil {
                fontName = name
                print("✅ Font found: \(name)")
                break
            }
        }
        
        if fontName == "AvenirNext-Bold" {
            print("⚠️ Orbitron font not found, using fallback: \(fontName)")
            print("📝 Checking font registration...")
        }
        
        // Titolo principale - ORBITICA CORE
        titleLabel = SKLabelNode(fontNamed: fontName)
        titleLabel.text = "ORBITICA"
        titleLabel.fontSize = 72
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 120)  // Abbassato da 200
        titleLabel.zPosition = 10
        addChild(titleLabel)
        
        // Sottotitolo - CORE
        subtitleLabel = SKLabelNode(fontNamed: fontName)
        subtitleLabel.text = "CORE"
        subtitleLabel.fontSize = 48
        subtitleLabel.fontColor = UIColor.cyan.withAlphaComponent(0.8)
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)  // Abbassato da 140
        subtitleLabel.zPosition = 10
        addChild(subtitleLabel)
        
        // Animazione titolo - glow effect
        let glow = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 1.5),
            SKAction.fadeAlpha(to: 1.0, duration: 1.5)
        ])
        titleLabel.run(SKAction.repeatForever(glow))
        
        // Tagline sotto
        let tagline = SKLabelNode(fontNamed: "Courier-Bold")
        tagline.text = "GRAVITY SHIELD"
        tagline.fontSize = 20
        tagline.fontColor = UIColor.white.withAlphaComponent(0.6)
        tagline.horizontalAlignmentMode = .center
        tagline.verticalAlignmentMode = .center
        tagline.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)  // Abbassato da 100
        tagline.zPosition = 10
        addChild(tagline)
    }
    
    private func setupPlayButton() {
        // Usa lo stesso font del titolo
        let possibleFontNames = ["Orbitron", "Orbitron-Bold", "Orbitron-Regular", "OrbitronVariable", "AvenirNext-Bold"]
        var fontName = "AvenirNext-Bold"
        
        for name in possibleFontNames {
            if UIFont(name: name, size: 12) != nil {
                fontName = name
                break
            }
        }
        
        // Bottone rettangolare con bordo - posizionato a SINISTRA
        let buttonWidth: CGFloat = 180
        let buttonHeight: CGFloat = 48
        let spacing: CGFloat = 20  // Spazio tra i bottoni
        
        playButton = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 10)
        playButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        playButton.strokeColor = .white
        playButton.lineWidth = 3
        playButton.position = CGPoint(x: size.width / 2 - buttonWidth / 2 - spacing / 2, y: size.height / 2 - 80)
        playButton.zPosition = 10
        playButton.name = "playButton"
        addChild(playButton)
        
        // Label del bottone - ridotta ulteriormente
        playButtonLabel = SKLabelNode(fontNamed: fontName)
        playButtonLabel.text = "PLAY NOW"
        playButtonLabel.fontSize = 22  // Ridotto da 26 a 22
        playButtonLabel.fontColor = .white
        playButtonLabel.verticalAlignmentMode = .center
        playButtonLabel.position = .zero
        playButtonLabel.zPosition = 11
        playButton.addChild(playButtonLabel)
        
        // Animazione hover/pulse del bottone
        let buttonPulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ])
        playButton.run(SKAction.repeatForever(buttonPulse))
        
        // Istruzioni in basso
        let instructions = SKLabelNode(fontNamed: "Courier")
        instructions.text = "Protect the planet • Survive the waves"
        instructions.fontSize = 16
        instructions.fontColor = UIColor.white.withAlphaComponent(0.5)
        instructions.position = CGPoint(x: size.width / 2, y: 50)
        instructions.zPosition = 10
        addChild(instructions)
    }
    
    private func setupHiScoreButton() {
        // Usa lo stesso font del titolo
        let possibleFontNames = ["Orbitron", "Orbitron-Bold", "Orbitron-Regular", "OrbitronVariable", "AvenirNext-Bold"]
        var fontName = "AvenirNext-Bold"
        
        for name in possibleFontNames {
            if UIFont(name: name, size: 12) != nil {
                fontName = name
                break
            }
        }
        
        // Bottone HI-SCORE a DESTRA del PLAY
        let buttonWidth: CGFloat = 180
        let buttonHeight: CGFloat = 48
        let spacing: CGFloat = 20  // Spazio tra i bottoni
        
        hiScoreButton = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 10)
        hiScoreButton.fillColor = UIColor.yellow.withAlphaComponent(0.1)
        hiScoreButton.strokeColor = .yellow
        hiScoreButton.lineWidth = 3
        hiScoreButton.position = CGPoint(x: size.width / 2 + buttonWidth / 2 + spacing / 2, y: size.height / 2 - 80)
        hiScoreButton.zPosition = 10
        hiScoreButton.name = "hiScoreButton"
        addChild(hiScoreButton)
        
        // Label del bottone - ridotta ulteriormente
        hiScoreButtonLabel = SKLabelNode(fontNamed: fontName)
        hiScoreButtonLabel.text = "HI-SCORE"
        hiScoreButtonLabel.fontSize = 22  // Ridotto da 26 a 22
        hiScoreButtonLabel.fontColor = .yellow
        hiScoreButtonLabel.verticalAlignmentMode = .center
        hiScoreButtonLabel.position = .zero
        hiScoreButtonLabel.zPosition = 11
        hiScoreButton.addChild(hiScoreButtonLabel)
        
        // Animazione hover/pulse del bottone
        let buttonPulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ])
        hiScoreButton.run(SKAction.repeatForever(buttonPulse))
    }
    
    private func setupDebugButton() {
        // Bottone DEBUG piccolo in basso a sinistra
        let buttonSize: CGFloat = 80
        
        debugButton = SKShapeNode(rectOf: CGSize(width: buttonSize, height: buttonSize * 0.6), cornerRadius: 5)
        debugButton?.fillColor = UIColor.orange.withAlphaComponent(0.2)
        debugButton?.strokeColor = .orange
        debugButton?.lineWidth = 2
        debugButton?.position = CGPoint(x: 60, y: 50)
        debugButton?.zPosition = 10
        debugButton?.name = "debugButton"
        
        if let button = debugButton {
            addChild(button)
            
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = "DEBUG"
            label.fontSize = 14
            label.fontColor = .orange
            label.verticalAlignmentMode = .center
            label.zPosition = 11
            button.addChild(label)
        }
    }
    
    // MARK: - Altri sfondi
    
    private func setupDeepSpaceBackground() {
        backgroundColor = UIColor(red: 0.01, green: 0.01, blue: 0.03, alpha: 1.0)
        
        // Stelle abbondanti
        for _ in 0..<120 {
            let starSize = CGFloat.random(in: 0.8...2.5)
            let star = SKShapeNode(circleOfRadius: starSize)
            star.fillColor = UIColor(white: CGFloat.random(in: 0.7...1.0), alpha: CGFloat.random(in: 0.4...0.9))
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            star.zPosition = -40
            addChild(star)
            
            if Bool.random() {
                let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: Double.random(in: 1...2.5))
                let fadeIn = SKAction.fadeAlpha(to: star.alpha, duration: Double.random(in: 1...2.5))
                let twinkle = SKAction.sequence([fadeOut, fadeIn])
                star.run(SKAction.repeatForever(twinkle))
            }
        }
    }
    
    private func setupNebulaBackground() {
        backgroundColor = UIColor(red: 0.05, green: 0.02, blue: 0.08, alpha: 1.0)
        
        // Nebulose viola/blu
        for _ in 0..<8 {
            let nebulaSize = CGFloat.random(in: 150...300)
            let nebula = SKShapeNode(circleOfRadius: nebulaSize)
            nebula.fillColor = UIColor(
                red: CGFloat.random(in: 0.2...0.4),
                green: CGFloat.random(in: 0.1...0.3),
                blue: CGFloat.random(in: 0.4...0.6),
                alpha: CGFloat.random(in: 0.08...0.15)
            )
            nebula.strokeColor = .clear
            nebula.position = CGPoint(
                x: CGFloat.random(in: -100...size.width + 100),
                y: CGFloat.random(in: -100...size.height + 100)
            )
            nebula.zPosition = -60
            addChild(nebula)
        }
        
        // Stelle
        for _ in 0..<60 {
            let starSize = CGFloat.random(in: 1...2)
            let star = SKShapeNode(circleOfRadius: starSize)
            star.fillColor = UIColor(white: CGFloat.random(in: 0.6...0.9), alpha: CGFloat.random(in: 0.3...0.6))
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            star.zPosition = -40
            addChild(star)
        }
    }
    
    private func setupVoidSpaceBackground() {
        backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        // Pochissime stelle distanti
        for _ in 0..<40 {
            let starSize = CGFloat.random(in: 0.8...1.5)
            let star = SKShapeNode(circleOfRadius: starSize)
            star.fillColor = UIColor(white: CGFloat.random(in: 0.5...0.7), alpha: CGFloat.random(in: 0.2...0.4))
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            star.zPosition = -40
            addChild(star)
        }
    }
    
    // MARK: - Musica
    
    private func setupBackgroundMusic() {
        guard let url = Bundle.main.url(forResource: "temp2", withExtension: "m4a") else {
            print("⚠️ Menu music file not found: temp2.m4a")
            return
        }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1  // Loop infinito
            musicPlayer?.volume = 0.0
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()
            
            // Fade in veloce
            fadeInMusic()
        } catch {
            print("❌ Error loading menu music: \(error.localizedDescription)")
        }
    }
    
    private func fadeInMusic() {
        guard let player = musicPlayer else { return }
        
        let fadeInDuration: TimeInterval = 0.4  // 400ms
        let steps = 20
        let stepDuration = fadeInDuration / Double(steps)
        let volumeIncrement: Float = 0.6 / Float(steps)  // Volume target 0.6
        
        var currentStep = 0
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            player.volume = min(0.6, Float(currentStep) * volumeIncrement)
            
            if currentStep >= steps {
                timer.invalidate()
            }
        }
    }
    
    private func fadeOutMusic(completion: @escaping () -> Void) {
        guard let player = musicPlayer, !isFadingOut else {
            completion()
            return
        }
        
        isFadingOut = true
        let fadeOutDuration: TimeInterval = 0.4  // 400ms
        let steps = 20
        let stepDuration = fadeOutDuration / Double(steps)
        let startVolume = player.volume
        let volumeDecrement = startVolume / Float(steps)
        
        var currentStep = 0
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            currentStep += 1
            player.volume = max(0.0, startVolume - (Float(currentStep) * volumeDecrement))
            
            if currentStep >= steps {
                timer.invalidate()
                player.stop()
                self?.isFadingOut = false
                completion()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "playButton" || node.parent?.name == "playButton" {
                startGame()
                return
            } else if node.name == "hiScoreButton" || node.parent?.name == "hiScoreButton" {
                showHiScore()
                return
            } else if node.name == "debugButton" || node.parent?.name == "debugButton" {
                showDebugScene()
                return
            }
        }
    }
    
    private func startGame() {
        // Effetto flash
        playButton.fillColor = UIColor.white.withAlphaComponent(0.5)
        playButtonLabel.fontColor = .black
        
        // Fade out musica, poi transizione
        fadeOutMusic { [weak self] in
            guard let self = self else { return }
            let transition = SKTransition.fade(withDuration: 0.5)
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            self.view?.presentScene(gameScene, transition: transition)
        }
    }
    
    private func showHiScore() {
        // Effetto flash
        hiScoreButton.fillColor = UIColor.yellow.withAlphaComponent(0.5)
        hiScoreButtonLabel.fontColor = .black
        
        // Fade out musica, poi transizione
        fadeOutMusic { [weak self] in
            guard let self = self else { return }
            let transition = SKTransition.fade(withDuration: 0.5)
            let hiScoreScene = HiScoreScene(size: self.size)
            hiScoreScene.scaleMode = self.scaleMode
            self.view?.presentScene(hiScoreScene, transition: transition)
        }
    }
    
    private func showDebugScene() {
        // Fade out musica, poi transizione
        fadeOutMusic { [weak self] in
            guard let self = self else { return }
            let transition = SKTransition.fade(withDuration: 0.5)
            let debugScene = DebugScene(size: self.size)
            debugScene.scaleMode = .aspectFill
            self.view?.presentScene(debugScene, transition: transition)
        }
    }
}
