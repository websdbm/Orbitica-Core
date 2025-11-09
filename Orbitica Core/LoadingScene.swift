//
//  LoadingScene.swift
//  Orbitica Core
//
//  Created by Alessandro Grassi on 09/11/25.
//

import SpriteKit

class LoadingScene: SKScene {
    
    override func didMove(to view: SKView) {
        setupAsteroidBeltBackground()
        
        // Transizione automatica al menu dopo breve delay
        let wait = SKAction.wait(forDuration: 1.5)
        let transition = SKAction.run { [weak self] in
            guard let self = self else { return }
            let menuScene = MainMenuScene(size: self.size)
            menuScene.scaleMode = .aspectFill
            let fadeTransition = SKTransition.fade(withDuration: 0.8)
            self.view?.presentScene(menuScene, transition: fadeTransition)
        }
        run(SKAction.sequence([wait, transition]))
    }
    
    private func setupAsteroidBeltBackground() {
        // BACKGROUND ASTEROID BELT: grigio-marrone scuro (stesso del menu)
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
        
        // Asteroidi che ruotano
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
            
            // Movimento lento
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
        
        // Stelle bianco-grigie opache
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
}
