//
//  DebugScene.swift
//  Orbitica Core
//
//  Debug scene per selezionare la wave di partenza
//

import SpriteKit

class DebugScene: SKScene {
    
    // Wave selector
    private var selectedWave: Int = 1
    private var waveLabel: SKLabelNode!
    private var playButton: SKShapeNode!
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
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
        decrementButton.position = CGPoint(x: size.width / 2 - 120, y: size.height / 2)
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
        waveLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        waveLabel.verticalAlignmentMode = .center
        waveLabel.zPosition = 100
        addChild(waveLabel)
        
        // Pulsante increment (+)
        let incrementButton = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 10)
        incrementButton.fillColor = UIColor.white.withAlphaComponent(0.1)
        incrementButton.strokeColor = .white
        incrementButton.lineWidth = 2
        incrementButton.position = CGPoint(x: size.width / 2 + 120, y: size.height / 2)
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
    
    private func createPlayButton() {
        playButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 15)
        playButton.fillColor = UIColor.green.withAlphaComponent(0.3)
        playButton.strokeColor = .green
        playButton.lineWidth = 3
        playButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 150)
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
                }
            } else if node.name == "increment" || node.parent?.name == "increment" {
                // Incrementa wave (massimo 20)
                if selectedWave < 20 {
                    selectedWave += 1
                    waveLabel.text = "\(selectedWave)"
                }
            } else if node.name == "play" || node.parent?.name == "play" {
                // Avvia il gioco dalla wave selezionata
                startGameAtWave(selectedWave)
            }
        }
    }
    
    private func startGameAtWave(_ wave: Int) {
        let transition = SKTransition.fade(withDuration: 0.5)
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .aspectFill
        gameScene.startingWave = wave  // Passa la wave di partenza
        view?.presentScene(gameScene, transition: transition)
    }
}
