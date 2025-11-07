//
//  MainMenuScene.swift
//  Orbitica Core
//
//  Created by Alessandro Grassi on 07/11/25.
//

import SpriteKit

class MainMenuScene: SKScene {
    
    private var titleLabel: SKLabelNode!
    private var subtitleLabel: SKLabelNode!
    private var playButton: SKShapeNode!
    private var playButtonLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        setupTitle()
        setupPlayButton()
        setupBackground()
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
        planet.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
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
        // Titolo principale - ORBITICA CORE
        titleLabel = SKLabelNode(fontNamed: "Zerovelo")
        titleLabel.text = "ORBITICA"
        titleLabel.fontSize = 72
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 200)
        titleLabel.zPosition = 10
        addChild(titleLabel)
        
        // Sottotitolo - CORE
        subtitleLabel = SKLabelNode(fontNamed: "Zerovelo")
        subtitleLabel.text = "CORE"
        subtitleLabel.fontSize = 48
        subtitleLabel.fontColor = UIColor.cyan.withAlphaComponent(0.8)
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 140)
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
        tagline.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        tagline.zPosition = 10
        addChild(tagline)
    }
    
    private func setupPlayButton() {
        // Bottone rettangolare con bordo
        let buttonWidth: CGFloat = 250
        let buttonHeight: CGFloat = 70
        
        playButton = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 10)
        playButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        playButton.strokeColor = .white
        playButton.lineWidth = 3
        playButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        playButton.zPosition = 10
        playButton.name = "playButton"
        addChild(playButton)
        
        // Label del bottone
        playButtonLabel = SKLabelNode(fontNamed: "Zerovelo")
        playButtonLabel.text = "PLAY NOW"
        playButtonLabel.fontSize = 32
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "playButton" || node.parent?.name == "playButton" {
                startGame()
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
}
