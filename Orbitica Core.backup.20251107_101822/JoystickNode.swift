//
//  JoystickNode.swift
//  Orbitica Core
//
//  Created by Alessandro Grassi on 07/11/25.
//  Based on: https://github.com/kazmiekr/joysticknode
//

import SpriteKit

class JoystickNode: SKNode {
    
    // Componenti
    private var baseNode: SKShapeNode!
    private var thumbNode: SKShapeNode!
    
    // Proprietà
    var isTracking = false
    private var trackingTouch: UITouch?
    
    // Callback
    var onMove: ((CGVector) -> Void)?
    var onEnd: (() -> Void)?
    
    // Parametri
    private let baseRadius: CGFloat
    private let thumbRadius: CGFloat
    private let maxDistance: CGFloat
    
    init(baseRadius: CGFloat = 60, thumbRadius: CGFloat = 25) {
        self.baseRadius = baseRadius
        self.thumbRadius = thumbRadius
        self.maxDistance = baseRadius - thumbRadius - 5
        
        super.init()
        
        setupNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNodes() {
        // Base
        baseNode = SKShapeNode(circleOfRadius: baseRadius)
        baseNode.fillColor = SKColor.white.withAlphaComponent(0.3)
        baseNode.strokeColor = SKColor.white.withAlphaComponent(0.8)
        baseNode.lineWidth = 4
        baseNode.zPosition = 0
        addChild(baseNode)
        
        // Thumb
        thumbNode = SKShapeNode(circleOfRadius: thumbRadius)
        thumbNode.fillColor = SKColor.white.withAlphaComponent(0.8)
        thumbNode.strokeColor = .white
        thumbNode.lineWidth = 3
        thumbNode.zPosition = 1
        addChild(thumbNode)
    }
    
    func touchBegan(_ touch: UITouch, in node: SKNode) {
        let location = touch.location(in: self)
        let distance = hypot(location.x, location.y)
        
        if distance <= baseRadius {
            isTracking = true
            trackingTouch = touch
            updateThumb(with: location)
        }
    }
    
    func touchMoved(_ touch: UITouch, in node: SKNode) {
        guard isTracking, touch == trackingTouch else { return }
        
        let location = touch.location(in: self)
        updateThumb(with: location)
    }
    
    func touchEnded(_ touch: UITouch) {
        guard isTracking, touch == trackingTouch else { return }
        
        isTracking = false
        trackingTouch = nil
        thumbNode.position = .zero
        thumbNode.setScale(1.0)
        onEnd?()
    }
    
    private func updateThumb(with location: CGPoint) {
        let distance = hypot(location.x, location.y)
        
        if distance <= maxDistance {
            thumbNode.position = location
        } else {
            let angle = atan2(location.y, location.x)
            thumbNode.position = CGPoint(
                x: cos(angle) * maxDistance,
                y: sin(angle) * maxDistance
            )
        }
        
        // Calcola direzione normalizzata
        let thumbPos = thumbNode.position
        let normalizedVector = CGVector(
            dx: thumbPos.x / maxDistance,
            dy: thumbPos.y / maxDistance
        )
        
        // Feedback visivo
        let magnitude = hypot(normalizedVector.dx, normalizedVector.dy)
        thumbNode.setScale(1.0 + magnitude * 0.3)
        
        // Callback
        onMove?(normalizedVector)
    }
}

class FireButtonNode: SKNode {
    
    private var buttonNode: SKShapeNode!
    private var iconNode: SKShapeNode!
    var isPressed = false
    private var trackingTouch: UITouch?
    
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?
    
    private let radius: CGFloat
    
    init(radius: CGFloat = 50) {
        self.radius = radius
        super.init()
        setupNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNodes() {
        // Button
        buttonNode = SKShapeNode(circleOfRadius: radius)
        buttonNode.fillColor = SKColor.red.withAlphaComponent(0.3)
        buttonNode.strokeColor = SKColor.red.withAlphaComponent(0.8)
        buttonNode.lineWidth = 4
        buttonNode.zPosition = 0
        addChild(buttonNode)
        
        // Icon
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 15))
        path.addLine(to: CGPoint(x: -10, y: -10))
        path.addLine(to: CGPoint(x: 0, y: -5))
        path.addLine(to: CGPoint(x: 10, y: -10))
        path.closeSubpath()
        
        iconNode = SKShapeNode(path: path)
        iconNode.fillColor = SKColor.red.withAlphaComponent(0.5)
        iconNode.strokeColor = .red
        iconNode.lineWidth = 3
        iconNode.zPosition = 1
        addChild(iconNode)
        
        // Label
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.fontSize = 16
        label.fontColor = .red
        label.text = "FIRE"
        label.position = CGPoint(x: 0, y: -30)
        label.zPosition = 1
        addChild(label)
    }
    
    func touchBegan(_ touch: UITouch, in node: SKNode) {
        let location = touch.location(in: self)
        let distance = hypot(location.x, location.y)
        
        if distance <= radius {
            isPressed = true
            trackingTouch = touch
            buttonNode.fillColor = SKColor.red.withAlphaComponent(0.6)
            onPress?()
        }
    }
    
    func touchEnded(_ touch: UITouch) {
        guard isPressed, touch == trackingTouch else { return }
        
        isPressed = false
        trackingTouch = nil
        buttonNode.fillColor = SKColor.red.withAlphaComponent(0.3)
        onRelease?()
    }
}
