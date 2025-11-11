//
//  AIBehaviors.swift
//  Orbitica Core
//
//  Comportamenti AI riutilizzabili per diverse entità
//

import Foundation
import CoreGraphics

// MARK: - Comportamento: Evita Collisione Pianeta

/// Evita di schiantarsi contro il pianeta
class AvoidPlanetBehavior: AIBehavior {
    let basePriority: Int = 90
    let safetyMargin: CGFloat
    
    init(safetyMargin: CGFloat = 100) {
        self.safetyMargin = safetyMargin
    }
    
    func evaluate(entity: AIEntity, context: AIContext) -> AIDecision? {
        let toPlanet = CGVector(
            dx: context.planetPosition.x - entity.position.x,
            dy: context.planetPosition.y - entity.position.y
        )
        let distance = toPlanet.length
        let dangerZone = context.planetRadius + safetyMargin
        
        // Se troppo vicino al pianeta, SCAPPA!
        if distance < dangerZone {
            let escapeDirection = CGVector(dx: -toPlanet.dx, dy: -toPlanet.dy).normalized()
            
            // Urgenza aumenta avvicinandosi al pianeta
            let urgency = 1.0 + (1.0 - distance / dangerZone) * 0.5
            
            // Se la velocità ti porta verso il pianeta, frena
            let velocityTowardPlanet = entity.velocity.dot(toPlanet) / max(distance, 1)
            let shouldBrake = velocityTowardPlanet > 150
            
            return AIDecision(
                movement: CGVector(
                    dx: escapeDirection.dx * urgency,
                    dy: escapeDirection.dy * urgency
                ),
                shouldFire: false,
                fireTarget: nil,
                shouldBrake: shouldBrake,
                priority: .emergency
            )
        }
        
        return nil
    }
}

// MARK: - Comportamento: Attacca Pianeta (Kamikaze)

/// Nave nemica che si schianta contro il pianeta
class AttackPlanetBehavior: AIBehavior {
    let basePriority: Int = 70
    let approachSpeed: CGFloat
    
    init(approachSpeed: CGFloat = 1.0) {
        self.approachSpeed = approachSpeed
    }
    
    func evaluate(entity: AIEntity, context: AIContext) -> AIDecision? {
        // Vai direttamente verso il pianeta
        let toPlanet = CGVector(
            dx: context.planetPosition.x - entity.position.x,
            dy: context.planetPosition.y - entity.position.y
        )
        let direction = toPlanet.normalized()
        
        return AIDecision(
            movement: CGVector(
                dx: direction.dx * approachSpeed,
                dy: direction.dy * approachSpeed
            ),
            shouldFire: false,
            fireTarget: nil,
            shouldBrake: false,
            priority: .objective
        )
    }
}

// MARK: - Comportamento: Bombarda Pianeta

/// Nave nemica che spara al pianeta da distanza di sicurezza
class BombardPlanetBehavior: AIBehavior {
    let basePriority: Int = 70
    let optimalRange: CGFloat
    let aimTolerance: CGFloat
    
    init(optimalRange: CGFloat = 250, aimTolerance: CGFloat = 0.3) {
        self.optimalRange = optimalRange
        self.aimTolerance = aimTolerance
    }
    
    func evaluate(entity: AIEntity, context: AIContext) -> AIDecision? {
        let toPlanet = CGVector(
            dx: context.planetPosition.x - entity.position.x,
            dy: context.planetPosition.y - entity.position.y
        )
        let distance = toPlanet.length
        let targetRadius = context.planetRadius + optimalRange
        
        var movement = CGVector.zero
        var shouldFire = false
        
        // Se troppo lontano, avvicinati
        if distance > targetRadius + 50 {
            let approach = toPlanet.normalized()
            movement = CGVector(dx: approach.dx * 0.7, dy: approach.dy * 0.7)
        }
        // Se troppo vicino, allontanati
        else if distance < targetRadius - 50 {
            let retreat = toPlanet.normalized()
            movement = CGVector(dx: -retreat.dx * 0.5, dy: -retreat.dy * 0.5)
        }
        // Distanza ottimale: orbita tangenzialmente
        else {
            let tangent = CGVector(dx: -toPlanet.dy, dy: toPlanet.dx).normalized()
            movement = CGVector(dx: tangent.dx * 0.6, dy: tangent.dy * 0.6)
        }
        
        // Verifica allineamento per sparare
        let planetAngle = atan2(toPlanet.dy, toPlanet.dx)
        let shipAngle = entity.angle + .pi / 2  // Compensazione sprite
        var angleDiff = abs(planetAngle - shipAngle)
        if angleDiff > .pi { angleDiff = 2 * .pi - angleDiff }
        
        if angleDiff < aimTolerance {
            shouldFire = true
        }
        
        return AIDecision(
            movement: movement,
            shouldFire: shouldFire,
            fireTarget: context.planetPosition,
            shouldBrake: false,
            priority: .objective
        )
    }
}

// MARK: - Comportamento: Caccia Giocatore

/// Nave nemica che insegue e attacca il giocatore
class HuntPlayerBehavior: AIBehavior {
    let basePriority: Int = 75
    let aggressiveness: CGFloat
    let firingRange: CGFloat
    let aimTolerance: CGFloat
    
    init(aggressiveness: CGFloat = 1.0, firingRange: CGFloat = 400, aimTolerance: CGFloat = 0.4) {
        self.aggressiveness = aggressiveness
        self.firingRange = firingRange
        self.aimTolerance = aimTolerance
    }
    
    func evaluate(entity: AIEntity, context: AIContext) -> AIDecision? {
        let toPlayer = CGVector(
            dx: context.playerPosition.x - entity.position.x,
            dy: context.playerPosition.y - entity.position.y
        )
        let distance = toPlayer.length
        
        // Insegui il giocatore
        let direction = toPlayer.normalized()
        let movement = CGVector(
            dx: direction.dx * aggressiveness,
            dy: direction.dy * aggressiveness
        )
        
        // Spara se abbastanza vicino e allineato
        var shouldFire = false
        if distance < firingRange {
            let playerAngle = atan2(toPlayer.dy, toPlayer.dx)
            let shipAngle = entity.angle + .pi / 2
            var angleDiff = abs(playerAngle - shipAngle)
            if angleDiff > .pi { angleDiff = 2 * .pi - angleDiff }
            
            shouldFire = angleDiff < aimTolerance
        }
        
        return AIDecision(
            movement: movement,
            shouldFire: shouldFire,
            fireTarget: context.playerPosition,
            shouldBrake: false,
            priority: .combat
        )
    }
}

// MARK: - Comportamento: Difendi Pianeta

/// Nave alleata che distrugge asteroidi minacciosi
class DefendPlanetBehavior: AIBehavior {
    let basePriority: Int = 80
    let patrolRadius: CGFloat
    let aimTolerance: CGFloat
    
    init(patrolRadius: CGFloat = 180, aimTolerance: CGFloat = 0.4) {
        self.patrolRadius = patrolRadius
        self.aimTolerance = aimTolerance
    }
    
    func evaluate(entity: AIEntity, context: AIContext) -> AIDecision? {
        // Trova l'asteroide più pericoloso
        guard let dangerous = findMostDangerousAsteroid(context: context) else {
            // Nessun asteroide: pattuglia
            return patrolBehavior(entity: entity, context: context)
        }
        
        let toAsteroid = CGVector(
            dx: dangerous.position.x - entity.position.x,
            dy: dangerous.position.y - entity.position.y
        )
        
        // Muoviti verso l'asteroide
        let direction = toAsteroid.normalized()
        let movement = CGVector(dx: direction.dx * 0.9, dy: direction.dy * 0.9)
        
        // Verifica se puoi sparare
        let asteroidAngle = atan2(toAsteroid.dy, toAsteroid.dx)
        let shipAngle = entity.angle + .pi / 2
        var angleDiff = abs(asteroidAngle - shipAngle)
        if angleDiff > .pi { angleDiff = 2 * .pi - angleDiff }
        
        let shouldFire = angleDiff < aimTolerance
        
        return AIDecision(
            movement: movement,
            shouldFire: shouldFire,
            fireTarget: dangerous.position,
            shouldBrake: false,
            priority: .combat
        )
    }
    
    private func patrolBehavior(entity: AIEntity, context: AIContext) -> AIDecision {
        let toPlanet = CGVector(
            dx: context.planetPosition.x - entity.position.x,
            dy: context.planetPosition.y - entity.position.y
        )
        let distance = toPlanet.length
        let targetRadius = context.planetRadius + patrolRadius
        
        var movement = CGVector.zero
        
        // Mantieni distanza di pattuglia
        if distance > targetRadius + 30 {
            let approach = toPlanet.normalized()
            movement = CGVector(dx: approach.dx * 0.6, dy: approach.dy * 0.6)
        } else if distance < targetRadius - 30 {
            let retreat = toPlanet.normalized()
            movement = CGVector(dx: -retreat.dx * 0.6, dy: -retreat.dy * 0.6)
        } else {
            // Orbita tangenzialmente
            let tangent = CGVector(dx: -toPlanet.dy, dy: toPlanet.dx).normalized()
            movement = CGVector(dx: tangent.dx * 0.7, dy: tangent.dy * 0.7)
        }
        
        return AIDecision(
            movement: movement,
            shouldFire: false,
            fireTarget: nil,
            shouldBrake: false,
            priority: .idle
        )
    }
    
    private func findMostDangerousAsteroid(context: AIContext) -> AsteroidInfo? {
        guard !context.asteroids.isEmpty else { return nil }
        
        var scored: [(asteroid: AsteroidInfo, danger: CGFloat)] = []
        
        for asteroid in context.asteroids {
            let toPlanet = CGVector(
                dx: context.planetPosition.x - asteroid.position.x,
                dy: context.planetPosition.y - asteroid.position.y
            )
            let toPlanetLength = toPlanet.length
            
            let velocityToPlanet = asteroid.velocity.dot(toPlanet) / max(toPlanetLength, 1)
            
            let dangerScore: CGFloat
            if velocityToPlanet > 0 {
                dangerScore = (1000.0 / asteroid.distanceFromPlanet) * velocityToPlanet
            } else {
                dangerScore = 100.0 / asteroid.distanceFromPlanet
            }
            
            scored.append((asteroid, dangerScore))
        }
        
        return scored.max(by: { $0.danger < $1.danger })?.asteroid
    }
}

// MARK: - Comportamento: Raccogli Power-up

/// Cerca e raccoglie power-up vicini
class CollectPowerupBehavior: AIBehavior {
    let basePriority: Int = 40
    let searchRadius: CGFloat
    
    init(searchRadius: CGFloat = 300) {
        self.searchRadius = searchRadius
    }
    
    func evaluate(entity: AIEntity, context: AIContext) -> AIDecision? {
        // Trova power-up più vicino
        let nearbyPowerups = context.powerups.filter {
            entity.position.distance(to: $0.position) < searchRadius
        }
        
        guard let nearest = nearbyPowerups.min(by: {
            entity.position.distance(to: $0.position) < entity.position.distance(to: $1.position)
        }) else {
            return nil
        }
        
        let toPowerup = CGVector(
            dx: nearest.position.x - entity.position.x,
            dy: nearest.position.y - entity.position.y
        )
        let direction = toPowerup.normalized()
        
        return AIDecision(
            movement: CGVector(dx: direction.dx * 0.8, dy: direction.dy * 0.8),
            shouldFire: false,
            fireTarget: nearest.position,  // Per puntare verso il powerup
            shouldBrake: false,
            priority: .opportunity
        )
    }
}

// MARK: - Comportamento: Orbita Pianeta

/// Mantiene un'orbita stabile attorno al pianeta
class OrbitPlanetBehavior: AIBehavior {
    let basePriority: Int = 20
    let orbitRadius: CGFloat
    let orbitSpeed: CGFloat
    
    init(orbitRadius: CGFloat = 180, orbitSpeed: CGFloat = 0.8) {
        self.orbitRadius = orbitRadius
        self.orbitSpeed = orbitSpeed
    }
    
    func evaluate(entity: AIEntity, context: AIContext) -> AIDecision? {
        let toPlanet = CGVector(
            dx: context.planetPosition.x - entity.position.x,
            dy: context.planetPosition.y - entity.position.y
        )
        let distance = toPlanet.length
        let targetRadius = context.planetRadius + orbitRadius
        
        var movement = CGVector.zero
        
        // Correggi distanza
        if distance > targetRadius + 30 {
            let approach = toPlanet.normalized()
            movement = CGVector(dx: approach.dx * 0.5, dy: approach.dy * 0.5)
        } else if distance < targetRadius - 30 {
            let retreat = toPlanet.normalized()
            movement = CGVector(dx: -retreat.dx * 0.5, dy: -retreat.dy * 0.5)
        } else {
            // Orbita tangenzialmente
            let tangent = CGVector(dx: -toPlanet.dy, dy: toPlanet.dx).normalized()
            movement = CGVector(dx: tangent.dx * orbitSpeed, dy: tangent.dy * orbitSpeed)
        }
        
        return AIDecision(
            movement: movement,
            shouldFire: false,
            fireTarget: nil,
            shouldBrake: false,
            priority: .idle
        )
    }
}

// MARK: - Utility Extensions

extension CGVector {
    var length: CGFloat {
        return sqrt(dx * dx + dy * dy)
    }
    
    func normalized() -> CGVector {
        let len = length
        guard len > 0 else { return .zero }
        return CGVector(dx: dx / len, dy: dy / len)
    }
    
    func dot(_ other: CGVector) -> CGFloat {
        return dx * other.dx + dy * other.dy
    }
}

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return sqrt(dx * dx + dy * dy)
    }
    
    func angle(to other: CGPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return atan2(dy, dx)
    }
}
