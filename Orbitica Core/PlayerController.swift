//
//  PlayerController.swift
//  Orbitica Core
//
//  Sistema di controllo unificato per player umano o IA
//

import Foundation
import CoreGraphics
import QuartzCore

/// Stato del gioco necessario per le decisioni del controller
struct GameState {
    let playerPosition: CGPoint
    let playerVelocity: CGVector
    let playerAngle: CGFloat
    let planetPosition: CGPoint
    let planetRadius: CGFloat
    let planetHealth: Int
    let maxPlanetHealth: Int
    let atmosphereRadius: CGFloat
    let maxAtmosphereRadius: CGFloat
    let asteroids: [AsteroidInfo]
    let currentWave: Int
    let score: Int
    let isGrappledToOrbit: Bool
    let orbitalRingRadius: CGFloat?
}

/// Informazioni su un asteroide per la IA
struct AsteroidInfo {
    let position: CGPoint
    let velocity: CGVector
    let size: CGFloat
    let health: Int
    let distanceFromPlanet: CGFloat
}

/// Protocollo per qualsiasi controller (umano o IA)
protocol PlayerController {
    /// Ritorna la direzione e intensità della spinta desiderata (-1...1 per x e y)
    func desiredMovement(for state: GameState) -> CGVector
    
    /// Ritorna true se il controller vuole sparare
    func shouldFire(for state: GameState) -> Bool
    
    /// Reset dello stato interno (chiamato a inizio partita)
    func reset()
}

// MARK: - Human Controller (Input Touch)

class HumanController: PlayerController {
    var joystickDirection: CGVector = .zero
    var isFiring: Bool = false
    
    func desiredMovement(for state: GameState) -> CGVector {
        return joystickDirection
    }
    
    func shouldFire(for state: GameState) -> Bool {
        return isFiring
    }
    
    func reset() {
        joystickDirection = .zero
        isFiring = false
    }
}

// MARK: - AI Controller (Algoritmo Semplice)

class AIController: PlayerController {
    // Parametri configurabili
    var difficulty: AIDifficulty = .normal
    var desiredOrbitRadius: CGFloat = 0  // Sarà impostato dinamicamente
    var currentTarget: CGPoint?  // Target corrente per puntare la nave
    
    // Stato interno
    private var lastFireTime: TimeInterval = 0
    private let fireRateLimit: TimeInterval = 0.15  // Spara max ogni 0.15s (più veloce)
    
    enum AIDifficulty {
        case easy, normal, hard
        
        var orbitRadiusMultiplier: CGFloat {
            switch self {
            case .easy: return 4.0    // Orbita molto larga (160px)
            case .normal: return 3.5  // Orbita larga (140px)  
            case .hard: return 3.0    // Orbita media (120px)
            }
        }
        
        var aimTolerance: CGFloat {
            switch self {
            case .easy: return 0.5  // ~29 gradi - spara più spesso
            case .normal: return 0.4  // ~23 gradi
            case .hard: return 0.3  // ~17 gradi
            }
        }
        
        var reactionSpeed: CGFloat {
            switch self {
            case .easy: return 0.8
            case .normal: return 1.0  // Reazione più veloce
            case .hard: return 1.2
            }
        }
    }
    
    func desiredMovement(for state: GameState) -> CGVector {
        // Calcola raggio orbitale desiderato basato sulla difficoltà
        desiredOrbitRadius = state.planetRadius * difficulty.orbitRadiusMultiplier
        
        // 1. CALCOLA DISTANZA DAL PIANETA
        let shipVector = CGVector(
            dx: state.playerPosition.x - state.planetPosition.x,
            dy: state.playerPosition.y - state.planetPosition.y
        )
        let currentRadius = sqrt(shipVector.dx * shipVector.dx + shipVector.dy * shipVector.dy)
        
        // 2. TROVA TARGET PIÙ PERICOLOSO
        let target = findMostDangerousAsteroid(state: state)
        
        // Salva il target corrente per puntare la nave
        currentTarget = target?.position
        
        var thrust = CGVector.zero
        
        // PRIORITÀ ASSOLUTA: evitare collisione con il pianeta
        let safetyZone = desiredOrbitRadius * 0.9  // Zona di sicurezza più ampia
        
        if currentRadius < safetyZone {
            // EMERGENZA: allontanati SEMPRE dal pianeta se troppo vicino
            let radialX = shipVector.dx / currentRadius
            let radialY = shipVector.dy / currentRadius
            
            // Considera anche la velocità: se stai andando verso il pianeta, spinta massima
            let velocityTowardPlanet = -(state.playerVelocity.dx * radialX + state.playerVelocity.dy * radialY)
            let urgency: CGFloat = velocityTowardPlanet > 0 ? 2.0 : 1.5  // Più urgente se ti stai avvicinando
            
            thrust = CGVector(dx: radialX * urgency, dy: radialY * urgency)
            
        } else if currentRadius > desiredOrbitRadius * 1.5 {
            // TROPPO LONTANO: avvicinati
            let radialX = -shipVector.dx / currentRadius
            let radialY = -shipVector.dy / currentRadius
            thrust = CGVector(dx: radialX, dy: radialY)
            
        } else if let target = target {
            // RAGGIO OK: muoviti verso il target MA controlla che non ti porti verso il pianeta
            let targetVector = CGVector(
                dx: target.position.x - state.playerPosition.x,
                dy: target.position.y - state.playerPosition.y
            )
            let targetDistance = sqrt(targetVector.dx * targetVector.dx + targetVector.dy * targetVector.dy)
            
            if targetDistance > 0 {
                let targetDirX = targetVector.dx / targetDistance
                let targetDirY = targetVector.dy / targetDistance
                
                // Verifica se il movimento verso il target ti porta verso il pianeta
                let radialX = shipVector.dx / currentRadius
                let radialY = shipVector.dy / currentRadius
                let dotProduct = targetDirX * (-radialX) + targetDirY * (-radialY)  // Negativo perché radial punta fuori
                
                if dotProduct > 0.3 {
                    // Il target è troppo verso il pianeta: bilancia movimento
                    thrust = CGVector(
                        dx: targetDirX * 0.8 + radialX * 0.7,  // Mix: 80% target + 70% fuga
                        dy: targetDirY * 0.8 + radialY * 0.7
                    )
                } else {
                    // Target sicuro: vai aggressivamente
                    thrust = CGVector(dx: targetDirX * 1.5, dy: targetDirY * 1.5)
                }
            }
        } else {
            // NESSUN TARGET: orbita tangenzialmente
            let tangentX = -shipVector.dy / currentRadius
            let tangentY = shipVector.dx / currentRadius
            thrust = CGVector(dx: tangentX * 0.8, dy: tangentY * 0.8)
        }
        
        // Applica velocità di reazione
        return CGVector(
            dx: thrust.dx * difficulty.reactionSpeed,
            dy: thrust.dy * difficulty.reactionSpeed
        )
    }
    
    func shouldFire(for state: GameState) -> Bool {
        // Limita rate di fuoco
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastFireTime > fireRateLimit else { return false }
        
        // Trova target
        guard let target = findMostDangerousAsteroid(state: state) else { return false }
        
        // Calcola angolo tra direzione nave e target
        let toTarget = CGVector(
            dx: target.position.x - state.playerPosition.x,
            dy: target.position.y - state.playerPosition.y
        )
        let targetAngle = atan2(toTarget.dy, toTarget.dx)
        
        // IMPORTANTE: player.zRotation ha offset di -π/2 perché la texture punta verso l'alto
        // Compensiamo per ottenere l'angolo effettivo della nave
        let shipAngle = state.playerAngle + .pi / 2
        
        // Calcola differenza angolare
        var angleDiff = abs(targetAngle - shipAngle)
        if angleDiff > .pi {
            angleDiff = 2 * .pi - angleDiff
        }
        
        // Spara se allineato entro la tolleranza
        let shouldShoot = angleDiff < difficulty.aimTolerance
        
        if shouldShoot {
            lastFireTime = currentTime
        }
        
        return shouldShoot
    }
    
    func reset() {
        lastFireTime = 0
    }
    
    // MARK: - Helper Methods
    
    private func findMostDangerousAsteroid(state: GameState) -> AsteroidInfo? {
        guard !state.asteroids.isEmpty else { return nil }
        
        // Priorità: asteroidi più vicini al pianeta E in movimento verso di esso
        var scored: [(asteroid: AsteroidInfo, danger: CGFloat)] = []
        
        for asteroid in state.asteroids {
            // Calcola direzione verso il pianeta
            let toPlanet = CGVector(
                dx: state.planetPosition.x - asteroid.position.x,
                dy: state.planetPosition.y - asteroid.position.y
            )
            let toPlanetLength = sqrt(toPlanet.dx * toPlanet.dx + toPlanet.dy * toPlanet.dy)
            
            // Velocità verso il pianeta (dot product)
            let velocityToPlanet = (asteroid.velocity.dx * toPlanet.dx + asteroid.velocity.dy * toPlanet.dy) / max(toPlanetLength, 1)
            
            // Score di pericolo: distanza inversa * velocità verso pianeta
            let dangerScore: CGFloat
            if velocityToPlanet > 0 {
                // Si sta avvicinando
                dangerScore = (1000.0 / asteroid.distanceFromPlanet) * velocityToPlanet
            } else {
                // Si sta allontanando: priorità bassa
                dangerScore = 100.0 / asteroid.distanceFromPlanet
            }
            
            scored.append((asteroid, dangerScore))
        }
        
        // Ritorna quello più pericoloso
        return scored.max(by: { $0.danger < $1.danger })?.asteroid
    }
}
