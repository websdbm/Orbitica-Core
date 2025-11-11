//
//  AIEngine.swift
//  Orbitica Core
//
//  Motore AI modulare per diversi tipi di entità
//

import Foundation
import CoreGraphics
import QuartzCore

// MARK: - AI Context (stato condiviso per tutte le AI)

/// Contesto completo del gioco visibile alle AI
struct AIContext {
    let playerPosition: CGPoint
    let playerVelocity: CGVector
    let planetPosition: CGPoint
    let planetRadius: CGFloat
    let planetHealth: Int
    let maxPlanetHealth: Int
    let atmosphereRadius: CGFloat
    let asteroids: [AsteroidInfo]
    let powerups: [PowerupInfo]
    let enemies: [EnemyInfo]  // Altre navi nemiche
    let allies: [AllyInfo]    // Navi alleate
    let currentWave: Int
    let deltaTime: TimeInterval
}

/// Informazioni su una nave nemica
struct EnemyInfo {
    let id: String
    let position: CGPoint
    let velocity: CGVector
    let angle: CGFloat
    let health: Int
    let maxHealth: Int
    let type: EnemyType
    let distanceFromPlanet: CGFloat
    let distanceFromPlayer: CGFloat
}

/// Informazioni su una nave alleata
struct AllyInfo {
    let id: String
    let position: CGPoint
    let velocity: CGVector
    let angle: CGFloat
    let health: Int
    let maxHealth: Int
    let distanceFromPlanet: CGFloat
    let distanceFromPlayer: CGFloat
}

enum EnemyType: String {
    case kamikaze    // Si schianta contro il pianeta
    case shooter     // Spara al pianeta da distanza
    case hunter      // Attacca il giocatore
}

// MARK: - AI Decision Output

/// Output di una decisione AI
struct AIDecision {
    let movement: CGVector        // Direzione thrust (-1...1)
    let shouldFire: Bool          // Deve sparare?
    let fireTarget: CGPoint?      // Target opzionale per il fuoco
    let shouldBrake: Bool         // Deve frenare?
    let priority: DecisionPriority // Priorità della decisione
    
    static let idle = AIDecision(
        movement: .zero,
        shouldFire: false,
        fireTarget: nil,
        shouldBrake: false,
        priority: .idle
    )
}

enum DecisionPriority: Int {
    case emergency = 100   // Evita collisione imminente
    case combat = 80       // Attacco/difesa
    case objective = 60    // Obiettivo principale
    case opportunity = 40  // Power-up, target secondari
    case idle = 20         // Pattuglia, attesa
}

// MARK: - AI Behavior Protocol

/// Protocollo base per tutti i comportamenti AI
protocol AIBehavior {
    /// Valuta la situazione e restituisce una decisione
    func evaluate(entity: AIEntity, context: AIContext) -> AIDecision?
    
    /// Priorità del comportamento (più alto = più importante)
    var basePriority: Int { get }
}

// MARK: - AI Entity

/// Entità controllata da AI
struct AIEntity {
    let id: String
    let position: CGPoint
    let velocity: CGVector
    let angle: CGFloat
    let health: Int
    let maxHealth: Int
    let type: AIEntityType
    
    // Parametri di movimento
    let maxSpeed: CGFloat
    let turnRate: CGFloat
    let acceleration: CGFloat
    
    // Stato interno
    var lastFireTime: TimeInterval
    var currentTarget: CGPoint?
    var memoryData: [String: Any]  // Dati persistenti per comportamenti complessi
}

enum AIEntityType {
    case playerShip      // Nave giocatore in auto-play
    case enemyShip       // Nave nemica
    case allyShip        // Nave alleata
    case asteroid        // Asteroide controllato
}

// MARK: - AI Agent Controller

/// Controller principale che coordina comportamenti AI per agenti generici
class AIAgentController {
    private var behaviors: [AIBehavior]
    private let reactionSpeed: CGFloat
    private let fireRateLimit: TimeInterval
    
    init(behaviors: [AIBehavior], reactionSpeed: CGFloat = 0.75, fireRateLimit: TimeInterval = 0.15) {
        self.behaviors = behaviors.sorted { $0.basePriority > $1.basePriority }
        self.reactionSpeed = reactionSpeed
        self.fireRateLimit = fireRateLimit
    }
    
    /// Valuta tutti i comportamenti e sceglie la decisione migliore
    func makeDecision(entity: AIEntity, context: AIContext) -> AIDecision {
        var bestDecision: AIDecision = .idle
        var highestPriority: Int = 0
        
        // Valuta ogni comportamento
        for behavior in behaviors {
            if let decision = behavior.evaluate(entity: entity, context: context) {
                let totalPriority = decision.priority.rawValue + behavior.basePriority
                
                if totalPriority > highestPriority {
                    bestDecision = decision
                    highestPriority = totalPriority
                }
            }
        }
        
        // Applica velocità di reazione al movimento
        let scaledMovement = CGVector(
            dx: bestDecision.movement.dx * reactionSpeed,
            dy: bestDecision.movement.dy * reactionSpeed
        )
        
        return AIDecision(
            movement: scaledMovement,
            shouldFire: bestDecision.shouldFire,
            fireTarget: bestDecision.fireTarget,
            shouldBrake: bestDecision.shouldBrake,
            priority: bestDecision.priority
        )
    }
    
    /// Aggiunge un comportamento dinamicamente
    func addBehavior(_ behavior: AIBehavior) {
        behaviors.append(behavior)
        behaviors.sort { $0.basePriority > $1.basePriority }
    }
    
    /// Rimuove un comportamento
    func removeBehavior(ofType type: AIBehavior.Type) {
        behaviors.removeAll { Swift.type(of: $0) == type }
    }
}

// MARK: - Utility Extensions

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

extension CGVector {
    var length: CGFloat {
        return sqrt(dx * dx + dy * dy)
    }
    
    var normalized: CGVector {
        let len = length
        guard len > 0 else { return .zero }
        return CGVector(dx: dx / len, dy: dy / len)
    }
    
    func dot(_ other: CGVector) -> CGFloat {
        return dx * other.dx + dy * other.dy
    }
}
