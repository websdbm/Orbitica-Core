//
//  MainMenuScene.swift
//  Orbitica Core
//
//  Created by Alessandro Grassi on 07/11/25.
//

import SpriteKit

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
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        setupBackground()
        setupOverlay()  // Overlay opaco sopra lo sfondo
        setupTitle()
        setupPlayButton()
        setupHiScoreButton()
        
        // Pulsante debug temporaneo
        if debugButtonEnabled {
            setupDebugButton()
        }
    }
    
    private func setupOverlay() {
        // Background semi-trasparente per far risaltare i testi
        let overlay = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.7), size: size)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 5  // Sopra lo sfondo ma sotto i testi
        addChild(overlay)
    }
    
    private func setupBackground() {
        // Stelle di sfondo animate
        for _ in 0..<50 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2))
            star.fillColor = .white
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            star.alpha = CGFloat.random(in: 0.3...1.0)
            star.zPosition = -1
            addChild(star)
            
            // Animazione pulsazione
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: Double.random(in: 1.0...3.0)),
                SKAction.fadeAlpha(to: 1.0, duration: Double.random(in: 1.0...3.0))
            ])
            star.run(SKAction.repeatForever(pulse))
        }
        
        // Pianeta centrale decorativo
        let planet = SKShapeNode(circleOfRadius: 30)
        planet.fillColor = .white
        planet.strokeColor = .white
        planet.lineWidth = 2
        planet.position = CGPoint(x: size.width / 2, y: size.height / 2 + 150)  // Alzato leggermente
        planet.zPosition = -0.5
        addChild(planet)
        
        // Anello attorno al pianeta
        let ring = SKShapeNode(circleOfRadius: 50)
        ring.fillColor = .clear
        ring.strokeColor = UIColor.cyan.withAlphaComponent(0.5)
        ring.lineWidth = 2
        ring.position = planet.position
        ring.zPosition = -0.5
        addChild(ring)
        
        // Pulsazione anello
        let ringPulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 1.5),
            SKAction.scale(to: 1.0, duration: 1.5)
        ])
        ring.run(SKAction.repeatForever(ringPulse))
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
        
        // Bottone rettangolare con bordo - ridotto del 20%
        let buttonWidth: CGFloat = 200  // Era 250, ora 200 (20% in meno)
        let buttonHeight: CGFloat = 56   // Era 70, ora 56 (20% in meno)
        
        playButton = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 10)
        playButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        playButton.strokeColor = .white
        playButton.lineWidth = 3
        playButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)  // Alzato per fare spazio
        playButton.zPosition = 10
        playButton.name = "playButton"
        addChild(playButton)
        
        // Label del bottone - ridotta del 20%
        playButtonLabel = SKLabelNode(fontNamed: fontName)
        playButtonLabel.text = "PLAY NOW"
        playButtonLabel.fontSize = 26  // Era 32, ora 26 (circa 20% in meno)
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
        
        // Bottone HI-SCORE sotto PLAY - ridotto del 20%
        let buttonWidth: CGFloat = 200  // Era 250, ora 200 (20% in meno)
        let buttonHeight: CGFloat = 56   // Era 70, ora 56 (20% in meno)
        
        hiScoreButton = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 10)
        hiScoreButton.fillColor = UIColor.yellow.withAlphaComponent(0.1)
        hiScoreButton.strokeColor = .yellow
        hiScoreButton.lineWidth = 3
        hiScoreButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 100)  // Sotto il PLAY, leggermente più vicino
        hiScoreButton.zPosition = 10
        hiScoreButton.name = "hiScoreButton"
        addChild(hiScoreButton)
        
        // Label del bottone - ridotta del 20%
        hiScoreButtonLabel = SKLabelNode(fontNamed: fontName)
        hiScoreButtonLabel.text = "HI-SCORE"
        hiScoreButtonLabel.fontSize = 26  // Era 32, ora 26 (circa 20% in meno)
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
        
        // Transizione alla GameScene
        let transition = SKTransition.fade(withDuration: 0.5)
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .aspectFill
        
        run(SKAction.wait(forDuration: 0.2)) {
            self.view?.presentScene(gameScene, transition: transition)
        }
    }
    
    private func showHiScore() {
        // Effetto flash
        hiScoreButton.fillColor = UIColor.yellow.withAlphaComponent(0.5)
        hiScoreButtonLabel.fontColor = .black
        
        // Transizione alla HiScoreScene
        let transition = SKTransition.fade(withDuration: 0.5)
        let hiScoreScene = HiScoreScene(size: size)
        hiScoreScene.scaleMode = scaleMode
        
        run(SKAction.wait(forDuration: 0.2)) {
            self.view?.presentScene(hiScoreScene, transition: transition)
        }
    }
    
    private func showDebugScene() {
        // Transizione alla DebugScene
        let transition = SKTransition.fade(withDuration: 0.5)
        let debugScene = DebugScene(size: size)
        debugScene.scaleMode = .aspectFill
        view?.presentScene(debugScene, transition: transition)
    }
}
