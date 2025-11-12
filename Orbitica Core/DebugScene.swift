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
    // ORA usa SpaceEnvironment da BackgroundManager
    private var allEnvironments: [SpaceEnvironment] {
        return SpaceEnvironment.allCases
    }
    
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
        // allEnvironments ora è una computed property che usa SpaceEnvironment.allCases
        
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
        
        // Usa BackgroundManager per setup unificato (STESSO CODICE di GameScene e RegiaScene)
        let dummyWorldLayer = SKNode()
        addChild(dummyWorldLayer)
        dummyWorldLayer.zPosition = -100
        
        BackgroundManager.setupBackground(
            environment,
            in: self,
            worldLayer: dummyWorldLayer,
            playFieldMultiplier: 1.0
        )
        
        print("✅ Debug preview: \(environment.name)")
    }
    
    // MARK: - Helper Functions
    
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
