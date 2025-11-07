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
        title.fontSize = 44
        title.fontColor = .yellow
        title.position = CGPoint(x: size.width / 2, y: size.height - 100)
        title.zPosition = 10
        addChild(title)
        
        // Animazione blink titolo
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.5)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        let blink = SKAction.sequence([fadeOut, fadeIn])
        title.run(SKAction.repeatForever(blink))
        
        // Score display
        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "SCORE: \(playerScore)    WAVE: \(playerWave)"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = .cyan
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 160)
        scoreLabel.zPosition = 10
        addChild(scoreLabel)
        
        // Istruzioni
        let instruction = SKLabelNode(fontNamed: "AvenirNext-Bold")
        instruction.text = "ENTER YOUR INITIALS"
        instruction.fontSize = 32
        instruction.fontColor = .white
        instruction.position = CGPoint(x: size.width / 2, y: size.height / 2 + 150)
        instruction.zPosition = 10
        addChild(instruction)
        
        // Initial entry boxes
        setupInitialBoxes()
        
        // Frecce su/giù
        createArrowButtons()
        
        // Confirm button IN BASSO
        createConfirmButton()
        
        // Istruzioni controllo IN ALTO sopra i box
        let controlHelp = SKLabelNode(fontNamed: "AvenirNext-Regular")
        controlHelp.text = "TAP ARROWS TO CHANGE LETTER • TAP INITIALS TO SELECT POSITION"
        controlHelp.fontSize = 14
        controlHelp.fontColor = .gray
        controlHelp.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        controlHelp.zPosition = 10
        addChild(controlHelp)
    }
    
    private func setupInitialBoxes() {
        let spacing: CGFloat = 80  // Ridotto da 100 a 80
        let startX = size.width / 2 - spacing
        let y = size.height / 2
        
        for i in 0..<3 {
            // Box PIÙ PICCOLO
            let box = SKShapeNode(rectOf: CGSize(width: 60, height: 80), cornerRadius: 5)  // Era 80x100, ora 60x80
            box.fillColor = i == currentPosition ? UIColor.white.withAlphaComponent(0.2) : UIColor.white.withAlphaComponent(0.05)
            box.strokeColor = i == currentPosition ? .yellow : .white
            box.lineWidth = 3
            box.position = CGPoint(x: startX + CGFloat(i) * spacing, y: y)
            box.name = "box_\(i)"
            box.zPosition = 5
            addChild(box)
            
            // Letter label PIÙ PICCOLA
            let label = SKLabelNode(fontNamed: "Courier-Bold")
            label.text = currentInitials[i]
            label.fontSize = 44  // Ridotto da 56 a 44
            label.fontColor = .white
            label.position = CGPoint(x: startX + CGFloat(i) * spacing, y: y - 8)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.name = "initial_\(i)"
            label.zPosition = 10
            addChild(label)
            
            initialLabels.append(label)
        }
        
        // Cursor blinking sotto la lettera corrente
        cursorNode = SKShapeNode(rectOf: CGSize(width: 50, height: 4))  // Ridotto da 60x5 a 50x4
        cursorNode?.fillColor = .yellow
        cursorNode?.strokeColor = .clear
        cursorNode?.position = CGPoint(x: startX, y: y - 50)
        cursorNode?.zPosition = 10
        if let cursor = cursorNode {
            addChild(cursor)
        }
    }
    
    private func createArrowButtons() {
        let x = size.width / 2 + 200  // Ridotto da 250 a 200 per stare più vicino
        let y = size.height / 2
        
        // Up arrow
        let upButton = createArrowButton(direction: "▲", position: CGPoint(x: x, y: y + 40), name: "upButton")
        addChild(upButton)
        
        // Down arrow
        let downButton = createArrowButton(direction: "▼", position: CGPoint(x: x, y: y - 40), name: "downButton")
        addChild(downButton)
    }
    
    private func createArrowButton(direction: String, position: CGPoint, name: String) -> SKShapeNode {
        let button = SKShapeNode(circleOfRadius: 35)
        button.fillColor = UIColor.white.withAlphaComponent(0.1)
        button.strokeColor = .white
        button.lineWidth = 3
        button.position = position
        button.name = name
        button.zPosition = 10
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = direction
        label.fontSize = 32
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        return button
    }
    
    private func createConfirmButton() {
        let button = SKShapeNode(rectOf: CGSize(width: 250, height: 70), cornerRadius: 10)
        button.fillColor = UIColor.green.withAlphaComponent(0.2)
        button.strokeColor = .green
        button.lineWidth = 4
        button.position = CGPoint(x: size.width / 2, y: 150)  // SPOSTATO PIÙ IN BASSO (era 200)
        button.name = "confirmButton"
        button.zPosition = 10
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "CONFIRM"
        label.fontSize = 32
        label.fontColor = .green
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        addChild(button)
    }
    
    private func animateCursor() {
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.4)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.4)
        let blink = SKAction.sequence([fadeOut, fadeIn])
        cursorNode?.run(SKAction.repeatForever(blink))
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
        
        // Aggiorna box highlighting
        for i in 0..<3 {
            if let box = childNode(withName: "box_\(i)") as? SKShapeNode {
                box.fillColor = i == currentPosition ? UIColor.white.withAlphaComponent(0.2) : UIColor.white.withAlphaComponent(0.05)
                box.strokeColor = i == currentPosition ? .yellow : .white
            }
        }
        
        // Muovi cursor (aggiornato per spacing ridotto)
        let spacing: CGFloat = 80  // AGGIORNATO da 100 a 80
        let startX = size.width / 2 - spacing
        cursorNode?.position.x = startX + CGFloat(currentPosition) * spacing
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
