//
//  HiScoreScene.swift
//  Orbitica Core
//
//  Schermata classifica top 10 - stile arcade anni '80
//

import SpriteKit

class HiScoreScene: SKScene {
    
    private var scores: [(initials: String, score: Int, wave: Int)] = []
    private var isLoading = true
    private var scrollNode: SKNode!
    private var contentNode: SKNode!
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        setupScrollView()
        setupUI()
        loadScores()
    }
    
    private func setupScrollView() {
        // Container principale per lo scroll
        scrollNode = SKNode()
        scrollNode.position = .zero
        addChild(scrollNode)
        
        // Nodo per il contenuto scrollabile
        contentNode = SKNode()
        scrollNode.addChild(contentNode)
    }
    
    private func setupUI() {
        // Fondino con gradiente sfumato (da opaco in alto a trasparente in basso)
        createGradientBackground()
        
        // Titolo "HIGH SCORES" stile arcade - FISSO
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "HIGH SCORES"
        title.fontSize = 48
        title.fontColor = .yellow
        title.position = CGPoint(x: size.width / 2, y: size.height - 80)
        title.zPosition = 201  // Sopra il background gradient (200)
        addChild(title)
        
        // Sottotitolo - FISSO
        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        subtitle.text = "TOP 10 PILOTS"
        subtitle.fontSize = 20
        subtitle.fontColor = .cyan
        subtitle.position = CGPoint(x: size.width / 2, y: size.height - 120)
        subtitle.zPosition = 201  // Sopra il background gradient (200)
        addChild(subtitle)
        
        // Loading indicator
        let loadingLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        loadingLabel.text = "LOADING..."
        loadingLabel.fontSize = 24
        loadingLabel.fontColor = .white
        loadingLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        loadingLabel.name = "loadingLabel"
        loadingLabel.zPosition = 10  // Sotto la tabella ma visibile
        addChild(loadingLabel)
        
        // Animazione blink loading
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.5)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        let blink = SKAction.sequence([fadeOut, fadeIn])
        loadingLabel.run(SKAction.repeatForever(blink))
        
        // Back button (freccia) - FISSO in alto a sinistra
        createBackButton()
    }
    
    private func createGradientBackground() {
        // Crea sfumatura con più strati sovrapposti
        let totalHeight: CGFloat = 160
        let numLayers = 20  // Numero di layer per creare il gradiente
        let layerHeight = totalHeight / CGFloat(numLayers)
        
        for i in 0..<numLayers {
            let layer = SKShapeNode(rectOf: CGSize(width: size.width, height: layerHeight + 1))  // +1 per evitare gap
            layer.strokeColor = .clear
            
            // Calcola alpha: opaco in alto (1.0), trasparente in basso (0.0)
            // I primi 3/4 sono completamente opachi, poi sfuma
            let position = CGFloat(i) / CGFloat(numLayers)
            let fadeStart: CGFloat = 0.75  // Inizia a sfumare dopo il 75%
            
            let alpha: CGFloat
            if position < fadeStart {
                alpha = 1.0  // Completamente opaco
            } else {
                // Sfuma gradualmente da 1.0 a 0.0
                let fadeProgress = (position - fadeStart) / (1.0 - fadeStart)
                alpha = 1.0 - fadeProgress
            }
            
            layer.fillColor = UIColor.black.withAlphaComponent(alpha)
            
            // Posiziona il layer dall'alto verso il basso
            let yPosition = size.height - (CGFloat(i) * layerHeight) - (layerHeight / 2)
            layer.position = CGPoint(x: size.width / 2, y: yPosition)
            layer.zPosition = 200  // SOPRA tutto per coprire la tabella quando scorre
            
            addChild(layer)
        }
    }
    
    private func createBackButton() {
        // Freccia back in alto a sinistra
        let backButton = SKShapeNode()
        let path = CGMutablePath()
        
        // Disegna freccia verso sinistra
        path.move(to: CGPoint(x: 15, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 10))
        path.addLine(to: CGPoint(x: 0, y: 5))
        path.addLine(to: CGPoint(x: -20, y: 5))
        path.addLine(to: CGPoint(x: -20, y: -5))
        path.addLine(to: CGPoint(x: 0, y: -5))
        path.addLine(to: CGPoint(x: 0, y: -10))
        path.closeSubpath()
        
        backButton.path = path
        backButton.fillColor = .white
        backButton.strokeColor = .clear
        backButton.position = CGPoint(x: 50, y: size.height - 50)
        backButton.name = "backButton"
        backButton.zPosition = 1000
        
        // Area touch più grande
        let touchArea = SKShapeNode(rectOf: CGSize(width: 80, height: 80))
        touchArea.fillColor = .clear
        touchArea.strokeColor = .clear
        touchArea.name = "backButton"
        touchArea.position = CGPoint(x: 50, y: size.height - 50)
        touchArea.zPosition = 999
        
        addChild(touchArea)
        addChild(backButton)
        
        // Animazione pulse
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])
        backButton.run(SKAction.repeatForever(pulse))
    }
    
    private func loadScores() {
        guard let url = URL(string: "https://formazioneweb.org/orbitica/score.php?action=list") else {
            showError("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.childNode(withName: "loadingLabel")?.removeFromParent()
                
                if let error = error {
                    self?.showError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.showError("No data received")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let scoresArray = json["scores"] as? [[String: Any]] {
                        
                        var loadedScores: [(String, Int, Int)] = []
                        for scoreData in scoresArray {
                            let initials = scoreData["initials"] as? String ?? "---"
                            let score = scoreData["score"] as? Int ?? 0
                            let wave = scoreData["wave"] as? Int ?? 0
                            loadedScores.append((initials, score, wave))
                        }
                        
                        self?.scores = loadedScores
                        self?.displayScores()
                    } else {
                        self?.showError("Invalid response format")
                    }
                } catch {
                    self?.showError("Parse error: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume()
    }
    
    private func displayScores() {
        // Rimuovi contenuto precedente
        contentNode.removeAllChildren()
        
        // Se non ci sono scores
        if scores.isEmpty {
            let emptyLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            emptyLabel.text = "You are the first!"
            emptyLabel.fontSize = 32
            emptyLabel.fontColor = .cyan
            emptyLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
            emptyLabel.zPosition = 10  // Sotto il gradient, visibile
            
            // Animazione blink
            let fadeOut = SKAction.fadeAlpha(to: 0.4, duration: 1.0)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 1.0)
            let blink = SKAction.sequence([fadeOut, fadeIn])
            emptyLabel.run(SKAction.repeatForever(blink))
            
            contentNode.addChild(emptyLabel)
            return
        }
        
        let startY = size.height - 240  // Ulteriormente abbassato per più spazio dall'alto
        let lineHeight: CGFloat = 55  // Aumentato per più spazio
        
        // Header - con più spazio dall'alto
        let headerY = startY + 50  // Aumentato da 40: più spazio dall'header
        let headerRank = createLabel(text: "#", x: size.width / 2 - 250, y: headerY, size: 18, color: .gray)
        let headerInitials = createLabel(text: "PILOT", x: size.width / 2 - 150, y: headerY, size: 18, color: .gray)
        let headerScore = createLabel(text: "SCORE", x: size.width / 2 + 50, y: headerY, size: 18, color: .gray)
        let headerWave = createLabel(text: "WAVE", x: size.width / 2 + 200, y: headerY, size: 18, color: .gray)
        
        contentNode.addChild(headerRank)
        contentNode.addChild(headerInitials)
        contentNode.addChild(headerScore)
        contentNode.addChild(headerWave)
        
        // Linea separatrice sotto header
        let separator = SKShapeNode(rectOf: CGSize(width: size.width - 100, height: 2))
        separator.fillColor = UIColor.white.withAlphaComponent(0.3)
        separator.strokeColor = .clear
        separator.position = CGPoint(x: size.width / 2, y: startY + 15)
        separator.zPosition = 10  // Sotto il gradient background
        contentNode.addChild(separator)
        
        // Scores - con più spazio dall'header
        for (index, scoreData) in scores.enumerated() {
            let y = startY - CGFloat(index) * lineHeight
            let rank = index + 1
            
            // Colore in base al ranking
            let color: UIColor
            switch rank {
            case 1: color = .yellow      // 1° oro
            case 2: color = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)  // 2° argento
            case 3: color = UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1)     // 3° bronzo
            default: color = .white
            }
            
            let rankLabel = createLabel(text: "\(rank)", x: size.width / 2 - 250, y: y, size: 24, color: color)
            let initialsLabel = createLabel(text: scoreData.initials, x: size.width / 2 - 150, y: y, size: 28, color: color)
            let scoreLabel = createLabel(text: "\(scoreData.score)", x: size.width / 2 + 50, y: y, size: 26, color: color)
            let waveLabel = createLabel(text: "\(scoreData.wave)", x: size.width / 2 + 200, y: y, size: 24, color: color)
            
            initialsLabel.fontName = "Courier-Bold"  // Font monospaced per iniziali
            
            contentNode.addChild(rankLabel)
            contentNode.addChild(initialsLabel)
            contentNode.addChild(scoreLabel)
            contentNode.addChild(waveLabel)
        }
        
        // Se meno di 10, mostra slot vuoti
        if scores.count < 10 {
            for index in scores.count..<10 {
                let y = startY - CGFloat(index) * lineHeight
                let rank = index + 1
                
                let rankLabel = createLabel(text: "\(rank)", x: size.width / 2 - 250, y: y, size: 24, color: .darkGray)
                let initialsLabel = createLabel(text: "---", x: size.width / 2 - 150, y: y, size: 28, color: .darkGray)
                let scoreLabel = createLabel(text: "0", x: size.width / 2 + 50, y: y, size: 26, color: .darkGray)
                let waveLabel = createLabel(text: "0", x: size.width / 2 + 200, y: y, size: 24, color: .darkGray)
                
                contentNode.addChild(rankLabel)
                contentNode.addChild(initialsLabel)
                contentNode.addChild(scoreLabel)
                contentNode.addChild(waveLabel)
            }
        }
    }
    
    private func showError(_ message: String) {
        let errorLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        errorLabel.text = "ERROR"
        errorLabel.fontSize = 32
        errorLabel.fontColor = .red
        errorLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        errorLabel.zPosition = 10  // Sotto il gradient
        contentNode.addChild(errorLabel)
        
        let detailLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        detailLabel.text = message
        detailLabel.fontSize = 18
        detailLabel.fontColor = .white
        detailLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 10)
        detailLabel.zPosition = 10
        contentNode.addChild(detailLabel)
        
        print("❌ HiScore Error: \(message)")
    }
    
    private func createLabel(text: String, x: CGFloat, y: CGFloat, size: CGFloat, color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.position = CGPoint(x: x, y: y)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 10  // Sotto il gradient background (200)
        return label
    }
    
    // MARK: - Touch & Scroll Handling
    
    private var touchStartY: CGFloat = 0
    private var scrollStartY: CGFloat = 0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtPoint = nodes(at: location)
        
        // Check back button
        for node in nodesAtPoint {
            if node.name == "backButton" {
                let transition = SKTransition.fade(withDuration: 0.5)
                let menuScene = MainMenuScene(size: size)
                menuScene.scaleMode = scaleMode
                view?.presentScene(menuScene, transition: transition)
                return
            }
        }
        
        // Inizia scroll
        touchStartY = location.y
        scrollStartY = contentNode.position.y
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Calcola delta scroll
        let deltaY = location.y - touchStartY
        let newY = scrollStartY + deltaY
        
        // Limiti scroll (minimo e massimo)
        let minY: CGFloat = 0
        let maxY: CGFloat = max(0, CGFloat(scores.count) * 55 - 200)  // Permetti scroll solo se necessario
        
        contentNode.position.y = max(minY, min(newY, maxY))
    }
}
