//
//  InitialEntryScene.swift
//  Orbitica Core
//
//  Scene per inserimento iniziali stile arcade
//

import SpriteKit
import UIKit

class InitialEntryScene: SKScene {
    
    private let playerScore: Int
    private let playerWave: Int
    private var currentInitials: [String] = ["A", "A", "A"]
    private var currentPosition = 0
    
    private var initialLabels: [SKLabelNode] = []
    private var cursorNode: SKShapeNode?
    
    init(size: CGSize, score: Int, wave: Int) {
        self.playerScore = score
        self.playerWave = wave
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        setupUI()
        animateCursor()
    }
    
    private func setupUI() {
        // Titolo "NEW HIGH SCORE!"
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "NEW HIGH SCORE!"
        title.fontSize = 32
        title.fontColor = .yellow
        title.position = CGPoint(x: size.width / 2, y: size.height - 70)
        title.zPosition = 10
        addChild(title)
        
        // Animazione blink titolo
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.5)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        let blink = SKAction.sequence([fadeOut, fadeIn])
        title.run(SKAction.repeatForever(blink))
        
        // Score display
        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "SCORE: \(playerScore)"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .cyan
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 110)
        scoreLabel.zPosition = 10
        addChild(scoreLabel)
        
        // Wave display
        let waveLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        waveLabel.text = "WAVE: \(playerWave)"
        waveLabel.fontSize = 20
        waveLabel.fontColor = .white
        waveLabel.position = CGPoint(x: size.width / 2, y: size.height - 135)
        waveLabel.zPosition = 10
        addChild(waveLabel)
        
        // Istruzioni "ENTER YOUR INITIALS"
        let instruction = SKLabelNode(fontNamed: "AvenirNext-Bold")
        instruction.text = "ENTER YOUR INITIALS"
        instruction.fontSize = 22
        instruction.fontColor = .white
        instruction.position = CGPoint(x: size.width / 2, y: size.height / 2 + 90)
        instruction.zPosition = 10
        addChild(instruction)
        
        // Istruzioni controllo
        let controlHelp = SKLabelNode(fontNamed: "AvenirNext-Regular")
        controlHelp.text = "TAP ARROWS TO CHANGE • TAP LETTER TO SELECT"
        controlHelp.fontSize = 11
        controlHelp.fontColor = .gray
        controlHelp.position = CGPoint(x: size.width / 2, y: size.height / 2 + 65)
        controlHelp.zPosition = 10
        addChild(controlHelp)
        
        // Initial entry boxes
        setupInitialBoxes()
        
        // Frecce su/giù
        createArrowButtons()
        
        // Confirm button IN BASSO
        createConfirmButton()
    }
    
    private func setupInitialBoxes() {
        let spacing: CGFloat = 60  // Più compatto
        let startX = size.width / 2 - spacing
        let y = size.height / 2 + 10
        
        for i in 0..<3 {
            // Box più piccolo
            let box = SKShapeNode(rectOf: CGSize(width: 50, height: 60), cornerRadius: 5)
            box.fillColor = i == currentPosition ? UIColor.white.withAlphaComponent(0.2) : UIColor.white.withAlphaComponent(0.05)
            box.strokeColor = i == currentPosition ? .yellow : .white
            box.lineWidth = 2
            box.position = CGPoint(x: startX + CGFloat(i) * spacing, y: y)
            box.name = "box_\(i)"
            box.zPosition = 5
            addChild(box)
            
            // Animazione pulsante per il box attivo
            if i == currentPosition {
                let pulseOut = SKAction.fadeAlpha(to: 0.5, duration: 0.6)
                let pulseIn = SKAction.fadeAlpha(to: 1.0, duration: 0.6)
                let pulse = SKAction.sequence([pulseOut, pulseIn])
                box.run(SKAction.repeatForever(pulse), withKey: "pulse")
            }
            
            // Letter label più piccolo
            let label = SKLabelNode(fontNamed: "Courier-Bold")
            label.text = currentInitials[i]
            label.fontSize = 36
            label.fontColor = .white
            label.position = CGPoint(x: startX + CGFloat(i) * spacing, y: y - 5)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.name = "initial_\(i)"
            label.zPosition = 10
            addChild(label)
            
            initialLabels.append(label)
        }
        
        // Niente cursor sotto la lettera - rimosso
    }
    
    private func createArrowButtons() {
        let x = size.width / 2 + 140  // Più vicino
        let y = size.height / 2 + 10
        
        // Up arrow
        let upButton = createArrowButton(direction: "▲", position: CGPoint(x: x, y: y + 30), name: "upButton")
        addChild(upButton)
        
        // Down arrow
        let downButton = createArrowButton(direction: "▼", position: CGPoint(x: x, y: y - 30), name: "downButton")
        addChild(downButton)
    }
    
    private func createArrowButton(direction: String, position: CGPoint, name: String) -> SKShapeNode {
        let button = SKShapeNode(circleOfRadius: 25)  // Più piccolo
        button.fillColor = UIColor.white.withAlphaComponent(0.1)
        button.strokeColor = .white
        button.lineWidth = 2
        button.position = position
        button.name = name
        button.zPosition = 10
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = direction
        label.fontSize = 24  // Più piccolo
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        return button
    }
    
    private func createConfirmButton() {
        let button = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 8)  // Più piccolo
        button.fillColor = UIColor.green.withAlphaComponent(0.2)
        button.strokeColor = .green
        button.lineWidth = 2
        button.position = CGPoint(x: size.width / 2, y: 100)  // Più in basso
        button.name = "confirmButton"
        button.zPosition = 10
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "CONFIRM"
        label.fontSize = 24
        label.fontColor = .green
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        addChild(button)
        
        // Pulsante X in alto a destra per chiudere
        createCloseButton()
    }
    
    private func createCloseButton() {
        let closeButton = SKShapeNode(circleOfRadius: 20)
        closeButton.fillColor = UIColor.red.withAlphaComponent(0.2)
        closeButton.strokeColor = .red
        closeButton.lineWidth = 2
        closeButton.position = CGPoint(x: size.width - 40, y: size.height - 40)
        closeButton.name = "closeButton"
        closeButton.zPosition = 10
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "✕"
        label.fontSize = 24
        label.fontColor = .red
        label.verticalAlignmentMode = .center
        closeButton.addChild(label)
        
        addChild(closeButton)
    }
    
    private func animateCursor() {
        // Cursor rimosso - animazione gestita dai box
    }
    
    private func updateCurrentLetter(delta: Int) {
        // Cicla A-Z
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let currentLetter = currentInitials[currentPosition]
        
        if let currentIndex = alphabet.firstIndex(of: Character(currentLetter)) {
            var newIndex = alphabet.distance(from: alphabet.startIndex, to: currentIndex) + delta
            
            // Wrap around
            if newIndex < 0 {
                newIndex = alphabet.count - 1
            } else if newIndex >= alphabet.count {
                newIndex = 0
            }
            
            let newLetter = alphabet[alphabet.index(alphabet.startIndex, offsetBy: newIndex)]
            currentInitials[currentPosition] = String(newLetter)
            
            // Aggiorna label
            initialLabels[currentPosition].text = String(newLetter)
            
            // Effetto bounce
            let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            initialLabels[currentPosition].run(SKAction.sequence([scaleUp, scaleDown]))
        }
    }
    
    private func selectPosition(_ position: Int) {
        guard position >= 0 && position < 3 else { return }
        
        currentPosition = position
        
        // Aggiorna box highlighting e animazione
        for i in 0..<3 {
            if let box = childNode(withName: "box_\(i)") as? SKShapeNode {
                box.fillColor = i == currentPosition ? UIColor.white.withAlphaComponent(0.2) : UIColor.white.withAlphaComponent(0.05)
                box.strokeColor = i == currentPosition ? .yellow : .white
                
                // Ferma animazione precedente
                box.removeAction(forKey: "pulse")
                
                // Avvia animazione pulsante solo per il box attivo
                if i == currentPosition {
                    let pulseOut = SKAction.fadeAlpha(to: 0.5, duration: 0.6)
                    let pulseIn = SKAction.fadeAlpha(to: 1.0, duration: 0.6)
                    let pulse = SKAction.sequence([pulseOut, pulseIn])
                    box.run(SKAction.repeatForever(pulse), withKey: "pulse")
                } else {
                    box.alpha = 1.0  // Reset alpha
                }
            }
        }
    }
    
    private func saveAndContinue() {
        let initials = currentInitials.joined()
        
        // Disabilita interazione
        isUserInteractionEnabled = false
        
        // Mostra saving indicator
        let savingLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        savingLabel.text = "SAVING..."
        savingLabel.fontSize = 28
        savingLabel.fontColor = .white
        savingLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 150)
        savingLabel.name = "savingLabel"
        savingLabel.zPosition = 15
        addChild(savingLabel)
        
        // Chiama API
        saveScore(initials: initials)
    }
    
    private func saveScore(initials: String) {
        guard let url = URL(string: "https://formazioneweb.org/orbitica/score.php?action=save") else {
            showError("Invalid URL")
            return
        }
        
        // Device ID (opzionale)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "initials": initials,
            "score": playerScore,
            "wave": playerWave,
            "device_id": deviceId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            showError("Failed to encode data")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.childNode(withName: "savingLabel")?.removeFromParent()
                
                if let error = error {
                    self?.showError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.showError("No response")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool, success {
                        
                        let rank = json["rank"] as? Int ?? 0
                        self?.showSuccess(rank: rank)
                        
                    } else {
                        let errorMsg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String ?? "Unknown error"
                        self?.showError(errorMsg)
                    }
                } catch {
                    self?.showError("Parse error")
                }
            }
        }
        
        task.resume()
    }
    
    private func showSuccess(rank: Int) {
        let successLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        successLabel.text = "RANK #\(rank)!"
        successLabel.fontSize = 48
        successLabel.fontColor = .green
        successLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 150)
        successLabel.zPosition = 15
        addChild(successLabel)
        
        // Transition to HiScore dopo 2 secondi
        let wait = SKAction.wait(forDuration: 2.0)
        let transition = SKAction.run { [weak self] in
            guard let self = self else { return }
            let hiScoreScene = HiScoreScene(size: self.size)
            hiScoreScene.scaleMode = self.scaleMode
            self.view?.presentScene(hiScoreScene, transition: SKTransition.fade(withDuration: 0.5))
        }
        run(SKAction.sequence([wait, transition]))
    }
    
    private func showError(_ message: String) {
        isUserInteractionEnabled = true
        
        let errorLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        errorLabel.text = "ERROR: \(message)"
        errorLabel.fontSize = 20
        errorLabel.fontColor = .red
        errorLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 150)
        errorLabel.zPosition = 15
        errorLabel.name = "errorLabel"
        addChild(errorLabel)
        
        // Rimuovi dopo 3 secondi
        let wait = SKAction.wait(forDuration: 3.0)
        let remove = SKAction.removeFromParent()
        errorLabel.run(SKAction.sequence([wait, remove]))
        
        print("❌ Save Error: \(message)")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let nodesAtPoint = nodes(at: location)
            
            for node in nodesAtPoint {
                if node.name == "upButton" {
                    updateCurrentLetter(delta: 1)
                } else if node.name == "downButton" {
                    updateCurrentLetter(delta: -1)
                } else if node.name == "confirmButton" {
                    saveAndContinue()
                } else if node.name == "closeButton" {
                    // Torna al menu principale senza salvare
                    let transition = SKTransition.fade(withDuration: 0.5)
                    let menuScene = MainMenuScene(size: size)
                    menuScene.scaleMode = scaleMode
                    view?.presentScene(menuScene, transition: transition)
                } else if let name = node.name, name.starts(with: "initial_") {
                    // Tap su una lettera per selezionarla
                    if let posStr = name.split(separator: "_").last,
                       let pos = Int(posStr) {
                        selectPosition(pos)
                    }
                } else if let name = node.name, name.starts(with: "box_") {
                    // Tap sul box
                    if let posStr = name.split(separator: "_").last,
                       let pos = Int(posStr) {
                        selectPosition(pos)
                    }
                }
            }
        }
    }
}
