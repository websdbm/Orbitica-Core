//
//  AIPresets.swift
//  Orbitica Core
//
//  Configurazioni predefinite per diversi tipi di AI
//

import Foundation
import CoreGraphics

// MARK: - AI Presets Factory

/// Factory per creare AI controller con comportamenti predefiniti
class AIPresets {
    
    // MARK: - Player AI (Auto-play)
    
    /// AI per la nave del giocatore in modalità auto-play/demo
    static func createPlayerAI(difficulty: AIDifficulty) -> AIController {
        let params = difficulty.parameters
        
        let behaviors: [AIBehavior] = [
            AvoidPlanetBehavior(safetyMargin: params.safetyMargin),
            DefendPlanetBehavior(
                patrolRadius: params.orbitRadius,
                aimTolerance: params.aimTolerance
            ),
            CollectPowerupBehavior(searchRadius: 300),
            OrbitPlanetBehavior(
                orbitRadius: params.orbitRadius,
                orbitSpeed: 0.8
            )
        ]
        
        return AIController(
            behaviors: behaviors,
            reactionSpeed: params.reactionSpeed,
            fireRateLimit: params.fireRateLimit
        )
    }
    
    // MARK: - Enemy AIs
    
    /// Nave kamikaze che si schianta contro il pianeta
    static func createKamikazeAI(aggressiveness: CGFloat = 1.0) -> AIController {
        let behaviors: [AIBehavior] = [
            AttackPlanetBehavior(approachSpeed: aggressiveness)
        ]
        
        return AIController(
            behaviors: behaviors,
            reactionSpeed: 0.9,
            fireRateLimit: 1.0  // Non spara
        )
    }
    
    /// Nave bombardiere che attacca il pianeta da distanza
    static func createBomberAI(range: CGFloat = 250) -> AIController {
        let behaviors: [AIBehavior] = [
            AvoidPlanetBehavior(safetyMargin: 80),
            BombardPlanetBehavior(optimalRange: range, aimTolerance: 0.3)
        ]
        
        return AIController(
            behaviors: behaviors,
            reactionSpeed: 0.7,
            fireRateLimit: 0.3
        )
    }
    
    /// Nave caccia che insegue il giocatore
    static func createHunterAI(aggressiveness: CGFloat = 1.0) -> AIController {
        let behaviors: [AIBehavior] = [
            AvoidPlanetBehavior(safetyMargin: 90),
            HuntPlayerBehavior(
                aggressiveness: aggressiveness,
                firingRange: 400,
                aimTolerance: 0.4
            ),
            OrbitPlanetBehavior(orbitRadius: 200, orbitSpeed: 0.6)
        ]
        
        return AIController(
            behaviors: behaviors,
            reactionSpeed: 0.85,
            fireRateLimit: 0.2
        )
    }
    
    /// Nave nemica versatile (mix di comportamenti)
    static func createHybridEnemyAI() -> AIController {
        let behaviors: [AIBehavior] = [
            AvoidPlanetBehavior(safetyMargin: 85),
            HuntPlayerBehavior(aggressiveness: 0.7, firingRange: 350, aimTolerance: 0.45),
            BombardPlanetBehavior(optimalRange: 220, aimTolerance: 0.35),
            OrbitPlanetBehavior(orbitRadius: 190, orbitSpeed: 0.7)
        ]
        
        return AIController(
            behaviors: behaviors,
            reactionSpeed: 0.75,
            fireRateLimit: 0.25
        )
    }
    
    // MARK: - Ally AIs
    
    /// Nave alleata difensore (aiuta il giocatore)
    static func createDefenderAllyAI() -> AIController {
        let behaviors: [AIBehavior] = [
            AvoidPlanetBehavior(safetyMargin: 95),
            DefendPlanetBehavior(patrolRadius: 200, aimTolerance: 0.35),
            CollectPowerupBehavior(searchRadius: 250),
            OrbitPlanetBehavior(orbitRadius: 200, orbitSpeed: 0.75)
        ]
        
        return AIController(
            behaviors: behaviors,
            reactionSpeed: 0.8,
            fireRateLimit: 0.18
        )
    }
    
    /// Nave alleata supporto (raccoglie power-up per il giocatore)
    static func createSupportAllyAI() -> AIController {
        let behaviors: [AIBehavior] = [
            AvoidPlanetBehavior(safetyMargin: 100),
            CollectPowerupBehavior(searchRadius: 400),  // Priorità power-up
            DefendPlanetBehavior(patrolRadius: 220, aimTolerance: 0.5),
            OrbitPlanetBehavior(orbitRadius: 220, orbitSpeed: 0.7)
        ]
        
        return AIController(
            behaviors: behaviors,
            reactionSpeed: 0.7,
            fireRateLimit: 0.25
        )
    }
}

// MARK: - AI Difficulty Parameters

enum AIDifficulty {
    case easy
    case normal
    case hard
    
    var parameters: AIParameters {
        switch self {
        case .easy:
            return AIParameters(
                orbitRadius: 200,
                safetyMargin: 110,
                aimTolerance: 0.5,
                reactionSpeed: 0.6,
                fireRateLimit: 0.18
            )
        case .normal:
            return AIParameters(
                orbitRadius: 180,
                safetyMargin: 100,
                aimTolerance: 0.4,
                reactionSpeed: 0.75,
                fireRateLimit: 0.15
            )
        case .hard:
            return AIParameters(
                orbitRadius: 160,
                safetyMargin: 90,
                aimTolerance: 0.3,
                reactionSpeed: 0.9,
                fireRateLimit: 0.12
            )
        }
    }
}

struct AIParameters {
    let orbitRadius: CGFloat
    let safetyMargin: CGFloat
    let aimTolerance: CGFloat
    let reactionSpeed: CGFloat
    let fireRateLimit: TimeInterval
}

// MARK: - Usage Examples

/*
 
 ESEMPIO 1: Creare una nave kamikaze
 
 let kamikazeAI = AIPresets.createKamikazeAI(aggressiveness: 1.2)
 let kamikazeEntity = AIEntity(
     id: "kamikaze_1",
     position: CGPoint(x: 100, y: 100),
     velocity: .zero,
     angle: 0,
     health: 50,
     maxHealth: 50,
     type: .enemyShip,
     maxSpeed: 200,
     turnRate: 3.0,
     acceleration: 150,
     lastFireTime: 0,
     currentTarget: nil,
     memoryData: [:]
 )
 
 // In update loop:
 let decision = kamikazeAI.makeDecision(entity: kamikazeEntity, context: gameContext)
 applyMovement(decision.movement)
 
 ---
 
 ESEMPIO 2: Creare una nave bombardiere
 
 let bomberAI = AIPresets.createBomberAI(range: 280)
 let bomberEntity = AIEntity(...)
 
 let decision = bomberAI.makeDecision(entity: bomberEntity, context: gameContext)
 if decision.shouldFire {
     fireBullet(toward: decision.fireTarget)
 }
 
 ---
 
 ESEMPIO 3: Creare una nave alleata difensore
 
 let allyAI = AIPresets.createDefenderAllyAI()
 let allyEntity = AIEntity(...)
 
 let decision = allyAI.makeDecision(entity: allyEntity, context: gameContext)
 applyThrust(decision.movement)
 if decision.shouldBrake {
     applyBrakes()
 }
 
 ---
 
 ESEMPIO 4: AI custom con comportamenti personalizzati
 
 let customBehaviors: [AIBehavior] = [
     AvoidPlanetBehavior(safetyMargin: 120),
     HuntPlayerBehavior(aggressiveness: 0.8, firingRange: 300, aimTolerance: 0.35),
     CollectPowerupBehavior(searchRadius: 200)
 ]
 
 let customAI = AIController(
     behaviors: customBehaviors,
     reactionSpeed: 0.8,
     fireRateLimit: 0.2
 )
 
 ---
 
 ESEMPIO 5: Modificare comportamenti dinamicamente
 
 var hunterAI = AIPresets.createHunterAI()
 
 // Aggiungi comportamento di raccolta power-up quando la salute è bassa
 if entity.health < entity.maxHealth * 0.3 {
     hunterAI.addBehavior(CollectPowerupBehavior(searchRadius: 400))
 }
 
 // Rimuovi comportamento quando non più necessario
 hunterAI.removeBehavior(ofType: CollectPowerupBehavior.self)
 
 */
