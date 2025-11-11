//
//  RegiaScene.swift
//  Orbitica Core
//
//  Pagina di regia per configurare partite IA e registrare video
//

import SpriteKit
import UIKit

class RegiaScene: SKScene {
    
    // MARK: - Configuration State
    private var selectedWave: Int = 1
    private var selectedDifficulty: AIController.AIDifficulty = .normal
    private var selectedBackground: Int = 0  // Index dell'ambiente
    private var selectedMusic: Int = 0  // Index della traccia
    private var autoPlay: Bool = true
    private var recordingEnabled: Bool = false
    
    // UI Elements
    private var recordButton: SKShapeNode?
    private var recordLabel: SKLabelNode?
    private var statusLabel: SKLabelNode?
    
    private let musicTracks = ["wave1.m4a", "wave2.m4a", "wave3.m4a", "temp4c.m4a"]
    private let musicNames = ["Wave 1", "Wave 2", "Wave 3", "Boss Theme"]
    
    // MARK: - Setup
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupUI()
        
        // Listener per stato registrazione
        ReplayManager.shared.onRecordingStatusChanged = { [weak self] isRecording in
            self?.updateRecordButtonState(isRecording: isRecording)
        }
    }
    
    private func setupUI() {
        // Titolo
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "🎬 REGIA"
        title.fontSize = 28
        title.fontColor = .yellow
        title.position = CGPoint(x: size.width / 2, y: size.height - 50)
        addChild(title)
        
        // Status label
        statusLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        statusLabel?.fontSize = 14
        statusLabel?.fontColor = .white
        statusLabel?.position = CGPoint(x: size.width / 2, y: size.height - 80)
        statusLabel?.text = "Configure demo"
        addChild(statusLabel!)
        
        // Layout a 2 colonne
        let leftX: CGFloat = size.width * 0.25
        let rightX: CGFloat = size.width * 0.75
        let startY: CGFloat = size.height - 130
        let lineHeight: CGFloat = 65
        
        // COLONNA SINISTRA
        var yLeft = startY
        
        // Wave
        createCompactSelector(
            label: "WAVE:",
            xPos: leftX,
            yPos: yLeft,
            currentValue: "\(selectedWave)",
            onPrev: { [weak self] in
                guard let self = self else { return }
                self.selectedWave = max(1, self.selectedWave - 1)
                self.updateSelectors()
            },
            onNext: { [weak self] in
                guard let self = self else { return }
                self.selectedWave = min(20, self.selectedWave + 1)
                self.updateSelectors()
            }
        )
        yLeft -= lineHeight
        
        // Difficulty
        createCompactSelector(
            label: "AI:",
            xPos: leftX,
            yPos: yLeft,
            currentValue: difficultyName(selectedDifficulty),
            onPrev: { [weak self] in
                self?.cycleDifficulty(forward: false)
            },
            onNext: { [weak self] in
                self?.cycleDifficulty(forward: true)
            }
        )
        
        // COLONNA DESTRA
        var yRight = startY
        
        // Background
        createCompactSelector(
            label: "BG:",
            xPos: rightX,
            yPos: yRight,
            currentValue: "Style \(selectedBackground + 1)",
            onPrev: { [weak self] in
                guard let self = self else { return }
                self.selectedBackground = max(0, self.selectedBackground - 1)
                self.updateSelectors()
            },
            onNext: { [weak self] in
                guard let self = self else { return }
                self.selectedBackground = min(15, self.selectedBackground + 1)
                self.updateSelectors()
            }
        )
        yRight -= lineHeight
        
        // Music
        createCompactSelector(
            label: "MUSIC:",
            xPos: rightX,
            yPos: yRight,
            currentValue: musicNames[selectedMusic],
            onPrev: { [weak self] in
                guard let self = self else { return }
                self.selectedMusic = max(0, self.selectedMusic - 1)
                self.updateSelectors()
            },
            onNext: { [weak self] in
                guard let self = self else { return }
                self.selectedMusic = min(self.musicTracks.count - 1, self.selectedMusic + 1)
                self.updateSelectors()
            }
        )
        
        // AUTOPLAY TOGGLE (centrato)
        let toggleY = startY - lineHeight * 2 - 20
        let toggleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        toggleLabel.text = "AI AUTOPLAY:"
        toggleLabel.fontSize = 16
        toggleLabel.fontColor = .white
        toggleLabel.horizontalAlignmentMode = .right
        toggleLabel.position = CGPoint(x: size.width / 2 - 10, y: toggleY)
        addChild(toggleLabel)
        
        let toggleButton = SKShapeNode(rectOf: CGSize(width: 50, height: 35), cornerRadius: 8)
        toggleButton.fillColor = autoPlay ? .green : .red
        toggleButton.strokeColor = .white
        toggleButton.lineWidth = 2
        toggleButton.position = CGPoint(x: size.width / 2 + 50, y: toggleY + 8)
        toggleButton.name = "toggleAutoPlay"
        addChild(toggleButton)
        
        let toggleText = SKLabelNode(fontNamed: "AvenirNext-Bold")
        toggleText.text = autoPlay ? "ON" : "OFF"
        toggleText.fontSize = 14
        toggleText.fontColor = .white
        toggleText.verticalAlignmentMode = .center
        toggleText.position = CGPoint(x: 0, y: 0)
        toggleText.name = "toggleText"
        toggleButton.addChild(toggleText)
        
        // BOTTONI AZIONE (centrati in basso)
        let actionY = toggleY - 80
        
        // Record Button
        recordButton = SKShapeNode(rectOf: CGSize(width: 160, height: 50), cornerRadius: 10)
        recordButton?.fillColor = .red
        recordButton?.strokeColor = .white
        recordButton?.lineWidth = 2
        recordButton?.position = CGPoint(x: size.width / 2, y: actionY)
        recordButton?.name = "recordButton"
        addChild(recordButton!)
        
        recordLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        recordLabel?.text = "⏺ REC"
        recordLabel?.fontSize = 16
        recordLabel?.fontColor = .white
        recordLabel?.verticalAlignmentMode = .center
        recordLabel?.position = CGPoint(x: 0, y: 0)
        recordButton?.addChild(recordLabel!)
        
        // Start Demo Button
        let startButton = SKShapeNode(rectOf: CGSize(width: 220, height: 60), cornerRadius: 12)
        startButton.fillColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        startButton.strokeColor = .yellow
        startButton.lineWidth = 3
        startButton.position = CGPoint(x: size.width / 2, y: actionY - 70)
        startButton.name = "startDemo"
        addChild(startButton)
        
        let startLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        startLabel.text = "🚀 START DEMO"
        startLabel.fontSize = 20
        startLabel.fontColor = .white
        startLabel.verticalAlignmentMode = .center
        startLabel.position = CGPoint(x: 0, y: 0)
        startButton.addChild(startLabel)
        
        // Back Button
        let backButton = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 8)
        backButton.fillColor = UIColor.gray.withAlphaComponent(0.3)
        backButton.strokeColor = .white
        backButton.lineWidth = 2
        backButton.position = CGPoint(x: 70, y: 40)
        backButton.name = "backButton"
        addChild(backButton)
        
        let backLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        backLabel.text = "◄ BACK"
        backLabel.fontSize = 18
        backLabel.fontColor = .white
        backLabel.verticalAlignmentMode = .center
        backLabel.position = CGPoint(x: 0, y: 0)
        backButton.addChild(backLabel)
    }
    
    private func createCompactSelector(label: String, xPos: CGFloat, yPos: CGFloat,
                                      currentValue: String,
                                      onPrev: @escaping () -> Void,
                                      onNext: @escaping () -> Void) {
        let labelNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        labelNode.text = label
        labelNode.fontSize = 14
        labelNode.fontColor = .white
        labelNode.horizontalAlignmentMode = .center
        labelNode.position = CGPoint(x: xPos, y: yPos + 25)
        addChild(labelNode)
        
        // Pulsante Previous
        let prevButton = SKShapeNode(rectOf: CGSize(width: 40, height: 35), cornerRadius: 6)
        prevButton.fillColor = UIColor.white.withAlphaComponent(0.2)
        prevButton.strokeColor = .cyan
        prevButton.lineWidth = 2
        prevButton.position = CGPoint(x: xPos - 60, y: yPos)
        prevButton.name = "prev_\(label)"
        addChild(prevButton)
        
        let prevLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        prevLabel.text = "◄"
        prevLabel.fontSize = 18
        prevLabel.fontColor = .cyan
        prevLabel.verticalAlignmentMode = .center
        prevLabel.position = CGPoint(x: 0, y: 0)
        prevButton.addChild(prevLabel)
        
        // Value display
        let valueLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        valueLabel.text = currentValue
        valueLabel.fontSize = 16
        valueLabel.fontColor = .yellow
        valueLabel.horizontalAlignmentMode = .center
        valueLabel.position = CGPoint(x: xPos, y: yPos - 5)
        valueLabel.name = "value_\(label)"
        addChild(valueLabel)
        
        // Pulsante Next
        let nextButton = SKShapeNode(rectOf: CGSize(width: 40, height: 35), cornerRadius: 6)
        nextButton.fillColor = UIColor.white.withAlphaComponent(0.2)
        nextButton.strokeColor = .cyan
        nextButton.lineWidth = 2
        nextButton.position = CGPoint(x: xPos + 60, y: yPos)
        nextButton.name = "next_\(label)"
        addChild(nextButton)
        
        let nextLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        nextLabel.text = "►"
        nextLabel.fontSize = 18
        nextLabel.fontColor = .cyan
        nextLabel.verticalAlignmentMode = .center
        nextLabel.position = CGPoint(x: 0, y: 0)
        nextButton.addChild(nextLabel)
    }
    
    private func createSelector(label: String, yPos: CGFloat,
                               currentValue: String,
                               onPrev: @escaping () -> Void,
                               onNext: @escaping () -> Void) {
        let labelNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        labelNode.text = label
        labelNode.fontSize = 18
        labelNode.fontColor = .white
        labelNode.horizontalAlignmentMode = .right
        labelNode.position = CGPoint(x: size.width / 2 - 20, y: yPos)
        addChild(labelNode)
        
        // Pulsante Previous
        let prevButton = SKShapeNode(rectOf: CGSize(width: 50, height: 40), cornerRadius: 8)
        prevButton.fillColor = UIColor.white.withAlphaComponent(0.2)
        prevButton.strokeColor = .cyan
        prevButton.lineWidth = 2
        prevButton.position = CGPoint(x: size.width / 2 + 30, y: yPos + 10)
        prevButton.name = "prev_\(label)"
        addChild(prevButton)
        
        let prevLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        prevLabel.text = "◄"
        prevLabel.fontSize = 20
        prevLabel.fontColor = .cyan
        prevLabel.verticalAlignmentMode = .center
        prevLabel.position = CGPoint(x: 0, y: 0)
        prevButton.addChild(prevLabel)
        
        // Value display
        let valueLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        valueLabel.text = currentValue
        valueLabel.fontSize = 18
        valueLabel.fontColor = .yellow
        valueLabel.position = CGPoint(x: size.width / 2 + 100, y: yPos)
        valueLabel.name = "value_\(label)"
        addChild(valueLabel)
        
        // Pulsante Next
        let nextButton = SKShapeNode(rectOf: CGSize(width: 50, height: 40), cornerRadius: 8)
        nextButton.fillColor = UIColor.white.withAlphaComponent(0.2)
        nextButton.strokeColor = .cyan
        nextButton.lineWidth = 2
        nextButton.position = CGPoint(x: size.width / 2 + 170, y: yPos + 10)
        nextButton.name = "next_\(label)"
        addChild(nextButton)
        
        let nextLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        nextLabel.text = "►"
        nextLabel.fontSize = 20
        nextLabel.fontColor = .cyan
        nextLabel.verticalAlignmentMode = .center
        nextLabel.position = CGPoint(x: 0, y: 0)
        nextButton.addChild(nextLabel)
    }
    
    // MARK: - Helpers
    
    private func difficultyName(_ diff: AIController.AIDifficulty) -> String {
        switch diff {
        case .easy: return "EASY"
        case .normal: return "NORMAL"
        case .hard: return "HARD"
        }
    }
    
    private func cycleDifficulty(forward: Bool) {
        switch selectedDifficulty {
        case .easy:
            selectedDifficulty = forward ? .normal : .hard
        case .normal:
            selectedDifficulty = forward ? .hard : .easy
        case .hard:
            selectedDifficulty = forward ? .easy : .normal
        }
        updateSelectors()
    }
    
    private func updateSelectors() {
        // Aggiorna i valori dei selettori
        if let waveLabel = childNode(withName: "value_WAVE:") as? SKLabelNode {
            waveLabel.text = "\(selectedWave)"
        }
        if let diffLabel = childNode(withName: "value_AI:") as? SKLabelNode {
            diffLabel.text = difficultyName(selectedDifficulty)
        }
        if let bgLabel = childNode(withName: "value_BG:") as? SKLabelNode {
            bgLabel.text = "Style \(selectedBackground + 1)"
        }
        if let musicLabel = childNode(withName: "value_MUSIC:") as? SKLabelNode {
            musicLabel.text = musicNames[selectedMusic]
        }
    }
    
    private func updateRecordButtonState(isRecording: Bool) {
        recordingEnabled = isRecording
        recordButton?.fillColor = isRecording ? .green : .red
        recordLabel?.text = isRecording ? "⏹ STOP RECORDING" : "⏺ START RECORDING"
        statusLabel?.text = isRecording ? "🔴 RECORDING IN PROGRESS" : "Ready to record"
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if let name = node.name {
                handleTouch(on: name)
            }
        }
    }
    
    private func handleTouch(on nodeName: String) {
        if nodeName == "backButton" {
            // Torna al menu principale
            let mainMenu = MainMenuScene(size: size)
            mainMenu.scaleMode = .aspectFill
            view?.presentScene(mainMenu, transition: SKTransition.fade(withDuration: 0.5))
            
        } else if nodeName == "startDemo" {
            startDemo()
            
        } else if nodeName == "recordButton" {
            toggleRecording()
            
        } else if nodeName == "toggleAutoPlay" {
            autoPlay.toggle()
            if let toggleButton = childNode(withName: "toggleAutoPlay") as? SKShapeNode {
                toggleButton.fillColor = autoPlay ? .green : .red
                if let toggleText = toggleButton.childNode(withName: "toggleText") as? SKLabelNode {
                    toggleText.text = autoPlay ? "ON" : "OFF"
                }
            }
        }
        
        // Handle selector buttons
        else if nodeName.starts(with: "prev_") || nodeName.starts(with: "next_") {
            let isNext = nodeName.starts(with: "next_")
            let label = nodeName.replacingOccurrences(of: "prev_", with: "")
                                .replacingOccurrences(of: "next_", with: "")
            
            if label == "WAVE:" {
                selectedWave = isNext ? min(20, selectedWave + 1) : max(1, selectedWave - 1)
                updateSelectors()
            } else if label == "AI:" {
                cycleDifficulty(forward: isNext)
            } else if label == "BG:" {
                selectedBackground = isNext ? min(15, selectedBackground + 1) : max(0, selectedBackground - 1)
                updateSelectors()
            } else if label == "MUSIC:" {
                selectedMusic = isNext ? min(musicTracks.count - 1, selectedMusic + 1) : max(0, selectedMusic - 1)
                updateSelectors()
            }
        }
    }
    
    // MARK: - Actions
    
    private func startDemo() {
        print("🎬 Starting demo with config:")
        print("   Wave: \(selectedWave)")
        print("   Difficulty: \(difficultyName(selectedDifficulty))")
        print("   Background: \(selectedBackground)")
        print("   Music: \(musicNames[selectedMusic])")
        print("   AutoPlay: \(autoPlay)")
        print("   Recording: \(recordingEnabled)")
        
        // Crea GameScene con configurazione personalizzata
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .aspectFill
        
        // TODO: Passa configurazione al GameScene
        // gameScene.startingWave = selectedWave
        // gameScene.aiDifficulty = selectedDifficulty
        // gameScene.backgroundIndex = selectedBackground
        // gameScene.musicTrack = musicTracks[selectedMusic]
        // gameScene.useAIController = autoPlay
        
        view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 1.0))
    }
    
    private func toggleRecording() {
        if ReplayManager.shared.isCurrentlyRecording {
            // Stop recording
            ReplayManager.shared.stopRecording { [weak self] url, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.statusLabel?.text = "❌ Recording error: \(error.localizedDescription)"
                    } else {
                        self?.statusLabel?.text = "✅ Recording saved to Photos"
                    }
                }
            }
        } else {
            // Start recording
            ReplayManager.shared.startRecording { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.statusLabel?.text = "❌ Recording error: \(error.localizedDescription)"
                    } else {
                        self?.statusLabel?.text = "🔴 RECORDING..."
                    }
                }
            }
        }
    }
}
