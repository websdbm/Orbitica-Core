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
    
    // Stato interno - Speronamento asteroidi
    private var lastRamAttemptTime: TimeInterval = 0
    private let ramCooldown: TimeInterval = 5.0  // Tenta speronamento ogni 5 secondi max
    private var ramAttemptsInWindow: Int = 0
    private var ramWindowStartTime: TimeInterval = 0
    private let maxRamAttemptsPerWindow: Int = 2  // Max 2 tentativi ogni 10 secondi
    private let ramWindowDuration: TimeInterval = 10.0
    
    // Stato interno - Orbital Ring usage
    private var lastOrbitalRingSeekTime: TimeInterval = 0
    private let orbitalRingCooldown: TimeInterval = 6.0  // Cerca orbital ring ogni 6 secondi
    private var orbitalRingUsageCount: Int = 0
    
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
        
        // MOVIMENTO REALISTICO: Virate eleganti con inerzia invece di su/giù continuo
        
        // GESTIONE AGGANCIO LINEE DI FORZA - Usa strategicamente le orbital rings
        let shouldForceDetach: Bool
        let shouldSeekOrbitalRing: Bool
        
        if state.isGrappledToOrbit {
            if !wasAttached {
                attachedTime = currentTime
                wasAttached = true
                print("🔗 AI: Agganciato a linea di forza - sfruttando per manovra")
            }
            
            // Rimani agganciato per fare mezzo giro tattico, poi distaccati
            shouldForceDetach = (currentTime - attachedTime > maxAttachTime)
            shouldSeekOrbitalRing = false
            
            if shouldForceDetach {
                print("🔓 AI: Completato giro tattico su linea di forza - distacco")
            }
        } else {
            if wasAttached {
                print("✅ AI: Sganciato da orbital ring - riprendendo controllo manuale")
                orbitalRingUsageCount += 1
            }
            wasAttached = false
            attachedTime = 0
            shouldForceDetach = false
            
            // CALCOLA DISTANZA DAL PIANETA (necessaria per valutazione tattica)
            let shipVector = CGVector(
                dx: state.playerPosition.x - state.planetPosition.x,
                dy: state.playerPosition.y - state.planetPosition.y
            )
            let currentRadius = sqrt(shipVector.dx * shipVector.dx + shipVector.dy * shipVector.dy)
            
            // Cerca orbital ring con cooldown intelligente
            // Condizioni: disponibile, passato abbastanza tempo, situazione tattica favorevole
            let timeSinceLastSeek = currentTime - lastOrbitalRingSeekTime
            let hasRing = state.orbitalRingRadius != nil
            let cooldownExpired = timeSinceLastSeek > orbitalRingCooldown
            
            // Situazioni tattiche favorevoli per usare orbital ring:
            // 1. Molti asteroidi nelle vicinanze (>3)
            // 2. Lontano dall'orbita desiderata
            // 3. Ogni tanto per variare il gameplay (50% probabilità se cooldown scaduto)
            let nearbyAsteroids = state.asteroids.filter { $0.distanceFromPlanet < 300 }.count
            let isOffOrbit = abs(currentRadius - desiredOrbitRadius) > 50
            let tacticallyUseful = nearbyAsteroids > 3 || isOffOrbit
            
            if hasRing && cooldownExpired && (tacticallyUseful || Double.random(in: 0...1) < 0.5) {
                shouldSeekOrbitalRing = true
                lastOrbitalRingSeekTime = currentTime
                print("⭕ AI: Orbital ring disponibile - tattica attivata (asteroidi: \(nearbyAsteroids), offOrbit: \(isOffOrbit))")
            } else {
                shouldSeekOrbitalRing = false
            }
        }
        
        // 1. CALCOLA DISTANZA E ANGOLO DAL PIANETA
        let shipVector = CGVector(
            dx: state.playerPosition.x - state.planetPosition.x,
            dy: state.playerPosition.y - state.planetPosition.y
        )
        let currentRadius = sqrt(shipVector.dx * shipVector.dx + shipVector.dy * shipVector.dy)
        
        // 2. DETERMINA TARGET DESIDERATO con priorità strategiche
        var desiredTargetPosition: CGPoint?
        let safetyZone = desiredOrbitRadius * 0.9
        
        // PRIORITÀ 1: Atmosfera sotto 50% - deve ricaricare!
        let atmosphereHealthPercent = state.atmosphereRadius / state.maxAtmosphereRadius
        if atmosphereHealthPercent < 0.50 && atmosphereHealthPercent > 0.05 {
            // Target: colpisci asteroidi per ricaricare atmosfera
            if let target = findMostDangerousAsteroid(state: state) {
                desiredTargetPosition = target.position
                print("🎯 AI: Atmosfera bassa (\(Int(atmosphereHealthPercent * 100))%) - priorità asteroidi per ricarica")
            }
        }
        
        // PRIORITÀ 2: Power-up nelle immediate vicinanze (< 200px)
        if desiredTargetPosition == nil {
            if let powerup = findNearestPowerup(state: state), powerup.distanceFromPlayer < 200 {
                desiredTargetPosition = powerup.position
                print("💎 AI: Power-up vicino - raccolta")
            }
        }
        
        // PRIORITÀ 3: Cerca orbital ring per manovra tattica (ELEVATA PRIORITÀ)
        if desiredTargetPosition == nil && shouldSeekOrbitalRing {
            if let ringRadius = state.orbitalRingRadius {
                // Calcola punto sulla ring più vicino alla posizione attuale
                let angleToRing = atan2(shipVector.dy, shipVector.dx)
                let ringX = state.planetPosition.x + cos(angleToRing) * ringRadius
                let ringY = state.planetPosition.y + sin(angleToRing) * ringRadius
                desiredTargetPosition = CGPoint(x: ringX, y: ringY)
                print("⭕ AI: Puntando verso orbital ring (raggio: \(Int(ringRadius))px) per manovra tattica")
            }
        }
        
        // PRIORITÀ 4: Distacco forzato da orbital ring
        if desiredTargetPosition == nil && shouldForceDetach && currentRadius > 0 {
            let radialX = shipVector.dx / currentRadius
            let radialY = shipVector.dy / currentRadius
            desiredTargetPosition = CGPoint(
                x: state.playerPosition.x + radialX * 100,
                y: state.playerPosition.y + radialY * 100
            )
            print("🔓 AI: Distacco da orbital ring completato")
        }
        
        // PRIORITÀ 5: Speronamento asteroidi (tecnica reale dei giocatori) - con cooldown intelligente
        // Reset finestra se è passato troppo tempo
        if currentTime - ramWindowStartTime > ramWindowDuration {
            ramAttemptsInWindow = 0
            ramWindowStartTime = currentTime
        }
        
        let canAttemptRam = (currentTime - lastRamAttemptTime > ramCooldown) && 
                           (ramAttemptsInWindow < maxRamAttemptsPerWindow)
        
        if desiredTargetPosition == nil && canAttemptRam && Double.random(in: 0...1) < 0.3 {
            if let target = findRammableAsteroid(state: state) {
                desiredTargetPosition = target.position
                lastRamAttemptTime = currentTime
                ramAttemptsInWindow += 1
                print("💥 AI: Tentativo speronamento asteroide! (\(ramAttemptsInWindow)/\(maxRamAttemptsPerWindow) in finestra)")
            }
        }
        
        // PRIORITÀ 6: Emergenza - troppo vicino al pianeta
        if desiredTargetPosition == nil && currentRadius < safetyZone {
            let radialX = shipVector.dx / currentRadius
            let radialY = shipVector.dy / currentRadius
            desiredTargetPosition = CGPoint(
                x: state.playerPosition.x + radialX * 100,
                y: state.playerPosition.y + radialY * 100
            )
        }
        
        // PRIORITÀ 7: Troppo lontano - rientra con virata elegante
        if desiredTargetPosition == nil && currentRadius > desiredOrbitRadius * 1.5 {
            // Invece di puntare dritto al pianeta, usa virata ad arco
            let currentAngle = atan2(shipVector.dy, shipVector.dx)
            let targetAngle = currentAngle + .pi / 4  // Virata di 45°
            let targetRadius = desiredOrbitRadius * 1.2
            desiredTargetPosition = CGPoint(
                x: state.planetPosition.x + cos(targetAngle) * targetRadius,
                y: state.planetPosition.y + sin(targetAngle) * targetRadius
            )
        }
        
        // PRIORITÀ 8: Target asteroide normale
        if desiredTargetPosition == nil {
            if let target = findMostDangerousAsteroid(state: state) {
                desiredTargetPosition = target.position
            }
        }
        
        // PRIORITÀ 9: Orbita elegante usando inerzia e virate morbide
        if desiredTargetPosition == nil {
            // Virata tangenziale + leggera componente radiale per orbita fluida
            let tangentX = -shipVector.dy / currentRadius
            let tangentY = shipVector.dx / currentRadius
            let radialX = shipVector.dx / currentRadius
            let radialY = shipVector.dy / currentRadius
            
            // Usa velocità attuale per calcolare virata naturale con inerzia
            let currentSpeed = sqrt(state.playerVelocity.dx * state.playerVelocity.dx + 
                                  state.playerVelocity.dy * state.playerVelocity.dy)
            let speedFactor = min(currentSpeed / 200.0, 1.5)  // Normalizza velocità
            
            // Target: combinazione tangente + correzione radiale dolce
            let radiusError = currentRadius - desiredOrbitRadius
            let radialCorrection = radiusError > 0 ? -0.2 : 0.2  // Correzione gentile
            
            desiredTargetPosition = CGPoint(
                x: state.playerPosition.x + tangentX * 100 * speedFactor + radialX * radialCorrection * 50,
                y: state.playerPosition.y + tangentY * 100 * speedFactor + radialY * radialCorrection * 50
            )
        }
        
        // Salva il target per rotazione nave (usato da GameScene)
        currentTarget = desiredTargetPosition
        
        // 3. CALCOLA L'ANGOLO VERSO IL TARGET DESIDERATO
        guard let targetPos = desiredTargetPosition else {
            return .zero
        }
        
        let toTarget = CGVector(
            dx: targetPos.x - state.playerPosition.x,
            dy: targetPos.y - state.playerPosition.y
        )
        let desiredAngle = atan2(toTarget.dy, toTarget.dx)
        
        // L'angolo della nave ha offset di -π/2 perché la texture punta verso l'alto
        let currentShipAngle = state.playerAngle + .pi / 2
        
        // 4. CALCOLA DIFFERENZA ANGOLARE (più breve tra clockwise e counterclockwise)
        var angleDiff = desiredAngle - currentShipAngle
        // Normalizza tra -π e π
        while angleDiff > .pi { angleDiff -= .pi * 2 }
        while angleDiff < -.pi { angleDiff += .pi * 2 }
        
        // 5. SIMULA CONTROLLO REALISTICO CON JOYSTICK
        // Il joystick può ruotare la nave E dare thrust in avanti
        
        // Componente di rotazione: proporzionale all'errore angolare con smoothing
        let rotationComponent: CGFloat
        if abs(angleDiff) > .pi / 3 {  // Angolo molto diverso (>60°): rotazione forte ma limitata
            rotationComponent = (angleDiff > 0 ? 0.85 : -0.85)  // Non a fondo per evitare flickering
        } else if abs(angleDiff) > .pi / 6 {  // Angolo medio (30-60°): rotazione media
            rotationComponent = angleDiff / (.pi / 4) * 0.7  // 70% della potenza
        } else {
            // Rotazione proporzionale gentile (più precisa vicino al target)
            rotationComponent = angleDiff / (.pi / 4) * 0.5  // 50% della potenza per precisione
        }
        
        // Componente di thrust: solo se abbastanza allineato
        let thrustComponent: CGFloat
        let alignmentThreshold: CGFloat = .pi / 3  // ~60 gradi
        
        if abs(angleDiff) < alignmentThreshold {
            // Abbastanza allineato: applica thrust in avanti
            // Intensità proporzionale all'allineamento (migliore allineamento = più thrust)
            let alignmentFactor = 1.0 - (abs(angleDiff) / alignmentThreshold)
            thrustComponent = alignmentFactor * difficulty.reactionSpeed
        } else {
            // Disallineato: niente thrust, solo rotazione
            thrustComponent = 0.0
        }
        
        // 6. CONVERTI IN VETTORE JOYSTICK VIRTUALE
        // La nave può solo spingere "in avanti" (nella direzione Y locale)
        // La rotazione è gestita dalla componente X del joystick
        
        // X del joystick = rotazione (sinistra/destra)
        // Y del joystick = thrust (avanti/indietro)
        
        // Calcola vettore thrust nella direzione della nave
        let thrustX = cos(currentShipAngle) * thrustComponent
        let thrustY = sin(currentShipAngle) * thrustComponent
        
        // Aggiungi componente di rotazione laterale (come se girasse il joystick)
        // Questo simula un "slide" che aiuta a ruotare più velocemente
        let lateralX = cos(currentShipAngle + .pi / 2) * rotationComponent * 0.3
        let lateralY = sin(currentShipAngle + .pi / 2) * rotationComponent * 0.3
        
        return CGVector(
            dx: thrustX + lateralX,
            dy: thrustY + lateralY
        )
    }
    
    func shouldFire(for state: GameState) -> Bool {
        // Limita rate di fuoco
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastFireTime > fireRateLimit else { return false }
        
        // PRIORITÀ STRATEGICA: Atmosfera sotto 50% - DEVE ricaricare sparando ad asteroidi!
        let atmosphereHealthPercent = state.atmosphereRadius / state.maxAtmosphereRadius
        let shouldTargetAtmosphere = atmosphereHealthPercent < 0.50 && atmosphereHealthPercent > 0.05
        
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
        lastRamAttemptTime = 0
        ramAttemptsInWindow = 0
        ramWindowStartTime = 0
        lastOrbitalRingSeekTime = 0
        orbitalRingUsageCount = 0
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
    
    /// Trova un asteroide adatto per speronamento (tecnica reale dei giocatori)
    private func findRammableAsteroid(state: GameState) -> AsteroidInfo? {
        guard !state.asteroids.isEmpty else { return nil }
        
        // Cerca asteroidi:
        // 1. Relativamente vicini al player (< 250px)
        // 2. Sulla traiettoria orbitale (non troppo dentro/fuori)
        // 3. Preferibilmente grandi (più facili da speronare)
        
        let playerToAsteroids = state.asteroids.compactMap { asteroid -> (asteroid: AsteroidInfo, distance: CGFloat, alignment: CGFloat)? in
            // Distanza dal player
            let toAsteroid = CGVector(
                dx: asteroid.position.x - state.playerPosition.x,
                dy: asteroid.position.y - state.playerPosition.y
            )
            let distance = sqrt(toAsteroid.dx * toAsteroid.dx + toAsteroid.dy * toAsteroid.dy)
            
            // Troppo lontano: skip
            guard distance < 250 else { return nil }
            
            // Calcola allineamento con velocità attuale (favorisce speronamenti naturali)
            let velocityMagnitude = sqrt(state.playerVelocity.dx * state.playerVelocity.dx + 
                                        state.playerVelocity.dy * state.playerVelocity.dy)
            let alignment: CGFloat
            if velocityMagnitude > 10 {
                let dotProduct = (toAsteroid.dx * state.playerVelocity.dx + 
                                 toAsteroid.dy * state.playerVelocity.dy) / (distance * velocityMagnitude)
                alignment = max(0, dotProduct)  // 0 = perpendicolare, 1 = allineato
            } else {
                alignment = 0.5  // Neutro se fermo
            }
            
            return (asteroid, distance, alignment)
        }
        
        // Trova il candidato migliore (vicino + allineato + grande)
        let best = playerToAsteroids.max { a, b in
            // Score: allineamento * (size factor) / distance
            let scoreA = a.alignment * (1.0 + a.asteroid.size / 30.0) / a.distance
            let scoreB = b.alignment * (1.0 + b.asteroid.size / 30.0) / b.distance
            return scoreA < scoreB
        }
        
        return best?.asteroid
    }
}
