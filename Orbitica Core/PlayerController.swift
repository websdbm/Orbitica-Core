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
    let atmosphereActive: Bool  // Se il power-up atmosfera è attivo
    let asteroids: [AsteroidInfo]
    let powerups: [PowerupInfo]  // Aggiunto per raccolta power-up
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

/// Informazioni su un power-up per la IA
struct PowerupInfo {
    let position: CGPoint
    let type: String  // "V", "B", "A", "G", "W", "M"
    let distanceFromPlayer: CGFloat
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
    
    // Stato interno - Firing
    private var lastFireTime: TimeInterval = 0
    private let fireRateLimit: TimeInterval = 0.15  // Spara max ogni 0.15s (più veloce)
    
    // Stato interno - Orbital Grapple (linee di forza)
    private var attachedTime: TimeInterval = 0
    private let maxAttachTime: TimeInterval = 2.5  // Distacco dopo 2.5 secondi
    private var wasAttached: Bool = false
    
    // Stato interno - Movimento dinamico
    private var thrustPhase: ThrustPhase = .cruise
    private var thrustPhaseStartTime: TimeInterval = 0
    private var thrustIntensity: CGFloat = 1.0
    
    // Stato interno - Manovre coreografiche
    private var lastManeuverTime: TimeInterval = 0
    private var currentManeuver: ManeuverPattern? = nil
    private var maneuverStartTime: TimeInterval = 0
    private var maneuverProgress: CGFloat = 0.0
    
    enum ThrustPhase {
        case accelerate  // Accelerazione 1.5x per 1-2s
        case cruise      // Crociera 1.0x per 3-5s
        case brake       // Frenata 0.5x per 1-2s
    }
    
    enum ManeuverPattern {
        case figure8     // Figura a 8
        case spiral      // Spirale espansiva
        case zigzag      // Zigzag rapido
        
        var duration: TimeInterval {
            switch self {
            case .figure8: return 6.0
            case .spiral: return 5.0
            case .zigzag: return 4.0
            }
        }
    }
    
    enum AIDifficulty {
        case easy, normal, hard
        
        var orbitRadiusMultiplier: CGFloat {
            switch self {
            case .easy: return 5.0    // Orbita molto larga (200px)
            case .normal: return 4.5  // Orbita larga (180px)  
            case .hard: return 4.0    // Orbita media (160px)
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
            case .easy: return 0.6    // Lento
            case .normal: return 0.75 // Naturale
            case .hard: return 0.9    // Veloce
            }
        }
    }
    
    func desiredMovement(for state: GameState) -> CGVector {
        let currentTime = CACurrentMediaTime()
        
        // Calcola raggio orbitale desiderato basato sulla difficoltà
        desiredOrbitRadius = state.planetRadius * difficulty.orbitRadiusMultiplier
        
        // GESTIONE AGGANCIO LINEE DI FORZA
        if state.isGrappledToOrbit {
            if !wasAttached {
                // Appena agganciato: registra tempo
                attachedTime = currentTime
                wasAttached = true
                print("🔗 AI: Agganciato a linea di forza")
            } else if currentTime - attachedTime > maxAttachTime {
                // Troppo tempo agganciato: FORZA IL DISTACCO
                print("🔓 AI: Distacco forzato da linea di forza dopo \(maxAttachTime)s")
                // Spinta radiale per sganciarsi
                let shipVector = CGVector(
                    dx: state.playerPosition.x - state.planetPosition.x,
                    dy: state.playerPosition.y - state.planetPosition.y
                )
                let currentRadius = sqrt(shipVector.dx * shipVector.dx + shipVector.dy * shipVector.dy)
                if currentRadius > 0 {
                    let radialX = shipVector.dx / currentRadius
                    let radialY = shipVector.dy / currentRadius
                    return CGVector(dx: radialX * 2.0, dy: radialY * 2.0)  // Spinta forte verso l'esterno
                }
            }
            // Ancora agganciato ma non ancora timeout: continua normalmente
        } else {
            // Non più agganciato: reset timer
            if wasAttached {
                print("✅ AI: Sganciato con successo")
            }
            wasAttached = false
            attachedTime = 0
        }
        
        // GESTIONE MOVIMENTO DINAMICO (accelera/frena)
        updateThrustPhase(currentTime: currentTime)
        
        // GESTIONE MANOVRE COREOGRAFICHE (ogni 15-20 secondi)
        if currentManeuver == nil && currentTime - lastManeuverTime > Double.random(in: 15...20) {
            // Inizia una nuova manovra
            currentManeuver = [ManeuverPattern.figure8, .spiral, .zigzag].randomElement()
            maneuverStartTime = currentTime
            maneuverProgress = 0.0
            lastManeuverTime = currentTime
            print("🎭 AI: Inizia manovra \(currentManeuver!)")
        }
        
        // Se c'è una manovra attiva, eseguila
        if let maneuver = currentManeuver {
            let elapsed = currentTime - maneuverStartTime
            if elapsed < maneuver.duration {
                maneuverProgress = CGFloat(elapsed / maneuver.duration)
                let maneuverThrust = executeManeuver(maneuver, progress: maneuverProgress, state: state)
                return CGVector(
                    dx: maneuverThrust.dx * thrustIntensity * difficulty.reactionSpeed,
                    dy: maneuverThrust.dy * thrustIntensity * difficulty.reactionSpeed
                )
            } else {
                // Manovra completata
                print("✅ AI: Manovra \(maneuver) completata")
                currentManeuver = nil
            }
        }
        
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
            // EMERGENZA: allontanati dal pianeta se troppo vicino
            let radialX = shipVector.dx / currentRadius
            let radialY = shipVector.dy / currentRadius
            
            // Considera anche la velocità: se stai andando verso il pianeta, spinta maggiore
            let velocityTowardPlanet = -(state.playerVelocity.dx * radialX + state.playerVelocity.dy * radialY)
            let urgency: CGFloat = velocityTowardPlanet > 0 ? 1.3 : 1.0  // Meno urgente per movimento naturale
            
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
                        dx: targetDirX * 0.6 + radialX * 0.5,  // Mix più cauto
                        dy: targetDirY * 0.6 + radialY * 0.5
                    )
                } else {
                    // Target sicuro: movimento moderato
                    thrust = CGVector(dx: targetDirX * 1.0, dy: targetDirY * 1.0)
                }
            }
        } else if let powerup = findNearestPowerup(state: state) {
            // NESSUN ASTEROIDE CRITICO: vai a prendere power-up se vicino
            let powerupVector = CGVector(
                dx: powerup.position.x - state.playerPosition.x,
                dy: powerup.position.y - state.playerPosition.y
            )
            let powerupDistance = sqrt(powerupVector.dx * powerupVector.dx + powerupVector.dy * powerupVector.dy)
            
            if powerupDistance > 0 && powerupDistance < 300 {  // Solo se entro 300px
                // Muoviti verso il power-up
                thrust = CGVector(
                    dx: (powerupVector.dx / powerupDistance) * 0.8,
                    dy: (powerupVector.dy / powerupDistance) * 0.8
                )
                // Salva come target per puntare la nave
                currentTarget = powerup.position
            } else {
                // Power-up troppo lontano: orbita
                let tangentX = -shipVector.dy / currentRadius
                let tangentY = shipVector.dx / currentRadius
                thrust = CGVector(dx: tangentX * 0.8, dy: tangentY * 0.8)
            }
        } else {
            // NESSUN TARGET E NESSUN POWERUP: orbita tangenzialmente
            let tangentX = -shipVector.dy / currentRadius
            let tangentY = shipVector.dx / currentRadius
            thrust = CGVector(dx: tangentX * 0.8, dy: tangentY * 0.8)
        }
        
        // Applica intensità dinamica del thrust e velocità di reazione
        return CGVector(
            dx: thrust.dx * thrustIntensity * difficulty.reactionSpeed,
            dy: thrust.dy * thrustIntensity * difficulty.reactionSpeed
        )
    }
    
    func shouldFire(for state: GameState) -> Bool {
        // Limita rate di fuoco
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastFireTime > fireRateLimit else { return false }
        
        // PRIORITÀ STRATEGICA: Controlla se l'atmosfera ha bisogno di aiuto
        let atmosphereHealthPercent = state.atmosphereRadius / state.maxAtmosphereRadius
        let shouldTargetAtmosphere = state.atmosphereActive && atmosphereHealthPercent < 0.3 && atmosphereHealthPercent > 0.01
        
        if shouldTargetAtmosphere {
            // Target: ATMOSFERA (prioritario quando < 30%)
            print("🎯 AI: Targeting atmosfera per ricarica (salute: \(Int(atmosphereHealthPercent * 100))%)")
            
            // Calcola angolo verso l'atmosfera (centro del pianeta)
            let toAtmosphere = CGVector(
                dx: state.planetPosition.x - state.playerPosition.x,
                dy: state.planetPosition.y - state.playerPosition.y
            )
            let atmosphereAngle = atan2(toAtmosphere.dy, toAtmosphere.dx)
            let atmosphereDistance = sqrt(toAtmosphere.dx * toAtmosphere.dx + toAtmosphere.dy * toAtmosphere.dy)
            
            // Compensazione angolo nave
            let shipAngle = state.playerAngle + .pi / 2
            
            // Calcola differenza angolare
            var angleDiff = abs(atmosphereAngle - shipAngle)
            if angleDiff > .pi {
                angleDiff = 2 * .pi - angleDiff
            }
            
            // Verifica allineamento (più tollerante per atmosfera grande)
            guard angleDiff < difficulty.aimTolerance * 1.5 else { return false }
            
            // Verifica che non sia troppo vicino (evita danno al pianeta)
            guard atmosphereDistance > state.planetRadius + 50 else { return false }
            
            // Spara all'atmosfera!
            lastFireTime = currentTime
            return true
        }
        
        // Se atmosfera è distrutta, NON sprecare colpi su di essa
        if atmosphereHealthPercent <= 0.01 {
            print("⚠️ AI: Atmosfera distrutta - ignoro come target")
        }
        
        // TARGET NORMALE: Trova asteroide più pericoloso
        guard let target = findMostDangerousAsteroid(state: state) else { return false }
        
        // Calcola angolo tra direzione nave e target
        let toTarget = CGVector(
            dx: target.position.x - state.playerPosition.x,
            dy: target.position.y - state.playerPosition.y
        )
        let targetAngle = atan2(toTarget.dy, toTarget.dx)
        let targetDistance = sqrt(toTarget.dx * toTarget.dx + toTarget.dy * toTarget.dy)
        
        // IMPORTANTE: player.zRotation ha offset di -π/2 perché la texture punta verso l'alto
        // Compensiamo per ottenere l'angolo effettivo della nave
        let shipAngle = state.playerAngle + .pi / 2
        
        // Calcola differenza angolare
        var angleDiff = abs(targetAngle - shipAngle)
        if angleDiff > .pi {
            angleDiff = 2 * .pi - angleDiff
        }
        
        // Verifica che sia allineato
        guard angleDiff < difficulty.aimTolerance else { return false }
        
        // VERIFICA CRITICA: il pianeta è sulla linea di tiro?
        // Calcola la distanza minima tra la linea di tiro e il centro del pianeta
        let toPlanet = CGVector(
            dx: state.planetPosition.x - state.playerPosition.x,
            dy: state.planetPosition.y - state.playerPosition.y
        )
        let planetDistance = sqrt(toPlanet.dx * toPlanet.dx + toPlanet.dy * toPlanet.dy)
        
        // Proietta il vettore al pianeta sulla direzione di sparo
        let planetAngle = atan2(toPlanet.dy, toPlanet.dx)
        let angleToShot = abs(planetAngle - shipAngle)
        let normalizedAngleToShot = angleToShot > .pi ? 2 * .pi - angleToShot : angleToShot
        
        // Distanza perpendicolare dalla linea di tiro al pianeta
        let perpendicularDistance = abs(planetDistance * sin(normalizedAngleToShot))
        
        // Se il pianeta è troppo vicino alla linea di tiro E davanti alla nave, NON SPARARE
        let planetIsAhead = cos(normalizedAngleToShot) > 0  // Pianeta è davanti
        let safetyMargin: CGFloat = state.planetRadius + 30  // Margine di sicurezza
        
        if planetIsAhead && perpendicularDistance < safetyMargin {
            // Il pianeta è sulla traiettoria - NON SPARARE
            return false
        }
        
        // Anche il target deve essere più lontano del pianeta (non sparare "attraverso" il pianeta)
        if planetIsAhead && planetDistance < targetDistance {
            return false
        }
        
        // Tutto ok: spara!
        let shouldShoot = true
        
        if shouldShoot {
            lastFireTime = currentTime
        }
        
        return shouldShoot
    }
    
    func reset() {
        lastFireTime = 0
        attachedTime = 0
        wasAttached = false
        thrustPhase = .cruise
        thrustIntensity = 1.0
        currentManeuver = nil
    }
    
    // MARK: - Helper Methods
    
    /// Aggiorna la fase di thrust per movimento dinamico (accelera/frena)
    private func updateThrustPhase(currentTime: TimeInterval) {
        let elapsed = currentTime - thrustPhaseStartTime
        
        switch thrustPhase {
        case .accelerate:
            thrustIntensity = 1.5
            if elapsed > Double.random(in: 1.0...2.0) {
                thrustPhase = .cruise
                thrustPhaseStartTime = currentTime
            }
            
        case .cruise:
            thrustIntensity = 1.0
            if elapsed > Double.random(in: 3.0...5.0) {
                // Alterna tra accelerazione e frenata
                thrustPhase = Bool.random() ? .accelerate : .brake
                thrustPhaseStartTime = currentTime
            }
            
        case .brake:
            thrustIntensity = 0.5
            if elapsed > Double.random(in: 1.0...2.0) {
                thrustPhase = .cruise
                thrustPhaseStartTime = currentTime
            }
        }
    }
    
    /// Esegue una manovra coreografica
    private func executeManeuver(_ maneuver: ManeuverPattern, progress: CGFloat, state: GameState) -> CGVector {
        let shipVector = CGVector(
            dx: state.playerPosition.x - state.planetPosition.x,
            dy: state.playerPosition.y - state.planetPosition.y
        )
        let currentRadius = sqrt(shipVector.dx * shipVector.dx + shipVector.dy * shipVector.dy)
        
        switch maneuver {
        case .figure8:
            // Figura a 8: alterna movimento verso l'interno e l'esterno
            let phase = sin(progress * .pi * 4)  // 4 cicli completi
            let radialX = shipVector.dx / currentRadius
            let radialY = shipVector.dy / currentRadius
            let tangentX = -shipVector.dy / currentRadius
            let tangentY = shipVector.dx / currentRadius
            
            return CGVector(
                dx: tangentX * 1.2 + radialX * phase * 0.5,
                dy: tangentY * 1.2 + radialY * phase * 0.5
            )
            
        case .spiral:
            // Spirale espansiva: movimento tangenziale + graduale allontanamento
            let tangentX = -shipVector.dy / currentRadius
            let tangentY = shipVector.dx / currentRadius
            let radialX = shipVector.dx / currentRadius
            let radialY = shipVector.dy / currentRadius
            let expansion = progress * 0.3  // Espansione graduale
            
            return CGVector(
                dx: tangentX * 1.5 + radialX * expansion,
                dy: tangentY * 1.5 + radialY * expansion
            )
            
        case .zigzag:
            // Zigzag: movimento a scatti alternati
            let zigzag = sin(progress * .pi * 8) > 0 ? 1.0 : -1.0
            let tangentX = -shipVector.dy / currentRadius
            let tangentY = shipVector.dx / currentRadius
            let perpendicularX = -tangentY
            let perpendicularY = tangentX
            
            return CGVector(
                dx: tangentX * 1.0 + perpendicularX * zigzag * 0.6,
                dy: tangentY * 1.0 + perpendicularY * zigzag * 0.6
            )
        }
    }
    
    private func findNearestPowerup(state: GameState) -> PowerupInfo? {
        guard !state.powerups.isEmpty else { return nil }
        
        // Filtra power-up vicini (entro 300px) e trova il più vicino
        let nearbyPowerups = state.powerups.filter { $0.distanceFromPlayer < 300 }
        
        // Ritorna il più vicino
        return nearbyPowerups.min(by: { $0.distanceFromPlayer < $1.distanceFromPlayer })
    }
    
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
