# AI Engine - Sistema Modulare per Orbitica Core

## Panoramica

Il sistema AI Engine è un framework modulare e riutilizzabile per creare comportamenti intelligenti per diverse entità di gioco:
- Navi nemiche (kamikaze, bombardieri, cacciatori)
- Navi alleate (difensori, supporto)
- Modalità auto-play per il giocatore
- Potenziali future entità (asteroidi controllati, boss, ecc.)

## Architettura

### 1. **AIEngine.swift** - Core del sistema
- `AIContext`: Stato completo del gioco (pianeta, asteroidi, navi, power-up)
- `AIEntity`: Rappresentazione di un'entità controllata da AI
- `AIDecision`: Output della decisione (movimento, fuoco, freno)
- `AIController`: Coordina più comportamenti e sceglie la decisione migliore

### 2. **AIBehaviors.swift** - Comportamenti riutilizzabili
Comportamenti disponibili:
- `AvoidPlanetBehavior`: Evita collisioni col pianeta (priorità 90)
- `AttackPlanetBehavior`: Kamikaze verso il pianeta (priorità 70)
- `BombardPlanetBehavior`: Spara al pianeta da distanza (priorità 70)
- `HuntPlayerBehavior`: Insegue e attacca il giocatore (priorità 75)
- `DefendPlanetBehavior`: Distrugge asteroidi pericolosi (priorità 80)
- `CollectPowerupBehavior`: Raccoglie power-up vicini (priorità 40)
- `OrbitPlanetBehavior`: Pattuglia in orbita (priorità 20)

### 3. **AIPresets.swift** - Configurazioni predefinite
Template pronti all'uso:
- `createPlayerAI()`: Auto-play intelligente
- `createKamikazeAI()`: Nave suicida
- `createBomberAI()`: Bombardiere a distanza
- `createHunterAI()`: Cacciatore aggressivo
- `createHybridEnemyAI()`: Nemico versatile
- `createDefenderAllyAI()`: Alleato difensore
- `createSupportAllyAI()`: Alleato supporto

## Come Usare

### Esempio 1: Nave Kamikaze

```swift
// 1. Crea l'AI controller
let kamikazeAI = AIPresets.createKamikazeAI(aggressiveness: 1.0)

// 2. Crea l'entità
var kamikazeEntity = AIEntity(
    id: "kamikaze_\(UUID())",
    position: spawnPosition,
    velocity: .zero,
    angle: 0,
    health: 100,
    maxHealth: 100,
    type: .enemyShip,
    maxSpeed: 250,
    turnRate: 4.0,
    acceleration: 200,
    lastFireTime: 0,
    currentTarget: nil,
    memoryData: [:]
)

// 3. Nel loop di update
override func update(_ currentTime: TimeInterval) {
    // Costruisci il contesto
    let context = AIContext(
        playerPosition: player.position,
        playerVelocity: player.physicsBody?.velocity ?? .zero,
        planetPosition: planet.position,
        planetRadius: planetRadius,
        planetHealth: planetHealth,
        maxPlanetHealth: maxPlanetHealth,
        atmosphereRadius: atmosphereRadius,
        asteroids: asteroidInfos,
        powerups: powerupInfos,
        enemies: enemyInfos,
        allies: allyInfos,
        currentWave: currentWave,
        deltaTime: deltaTime
    )
    
    // Aggiorna posizione/velocità dell'entità
    kamikazeEntity.position = kamikazeShip.position
    kamikazeEntity.velocity = kamikazeShip.physicsBody?.velocity ?? .zero
    kamikazeEntity.angle = kamikazeShip.zRotation
    
    // Ottieni decisione
    let decision = kamikazeAI.makeDecision(entity: kamikazeEntity, context: context)
    
    // Applica movimento
    let thrustPower: CGFloat = 200
    let force = CGVector(
        dx: decision.movement.dx * thrustPower,
        dy: decision.movement.dy * thrustPower
    )
    kamikazeShip.physicsBody?.applyForce(force)
    
    // Punta verso il pianeta
    let angle = atan2(
        context.planetPosition.y - kamikazeShip.position.y,
        context.planetPosition.x - kamikazeShip.position.x
    )
    kamikazeShip.zRotation = angle - .pi / 2
}
```

### Esempio 2: Nave Bombardiere

```swift
let bomberAI = AIPresets.createBomberAI(range: 250)

// Nel loop di update
let decision = bomberAI.makeDecision(entity: bomberEntity, context: context)

// Applica movimento
applyForce(decision.movement, to: bomberShip)

// Spara se richiesto
if decision.shouldFire, let target = decision.fireTarget {
    fireBullet(from: bomberShip, toward: target)
}

// Punta verso il target
if let target = decision.fireTarget {
    let angle = atan2(
        target.y - bomberShip.position.y,
        target.x - bomberShip.position.x
    )
    bomberShip.zRotation = angle - .pi / 2
}
```

### Esempio 3: Nave Alleata Difensore

```swift
let allyAI = AIPresets.createDefenderAllyAI()

// Nel loop di update
let decision = allyAI.makeDecision(entity: allyEntity, context: context)

applyForce(decision.movement, to: allyShip)

if decision.shouldFire {
    firePlayerBullet(from: allyShip)
}

if decision.shouldBrake {
    applyBrakes(to: allyShip)
}
```

### Esempio 4: AI Personalizzata

```swift
// Crea comportamenti custom
let customBehaviors: [AIBehavior] = [
    AvoidPlanetBehavior(safetyMargin: 120),
    HuntPlayerBehavior(aggressiveness: 1.5, firingRange: 500, aimTolerance: 0.3),
    CollectPowerupBehavior(searchRadius: 350)
]

let customAI = AIController(
    behaviors: customBehaviors,
    reactionSpeed: 0.85,
    fireRateLimit: 0.15
)
```

### Esempio 5: Comportamenti Dinamici

```swift
var enemyAI = AIPresets.createHunterAI()

// Cambia strategia quando salute bassa
if entity.health < entity.maxHealth * 0.3 {
    // Diventa più difensivo: cerca power-up di salute
    enemyAI.addBehavior(CollectPowerupBehavior(searchRadius: 500))
    enemyAI.removeBehavior(ofType: HuntPlayerBehavior.self)
}

// Ripristina aggressività quando guarito
if entity.health > entity.maxHealth * 0.7 {
    enemyAI.removeBehavior(ofType: CollectPowerupBehavior.self)
    enemyAI.addBehavior(HuntPlayerBehavior(aggressiveness: 1.2))
}
```

## Sistema di Priorità

Le decisioni AI vengono valutate in base a due livelli di priorità:

1. **Priorità del Comportamento** (`basePriority`):
   - AvoidPlanet: 90 (massima priorità - sopravvivenza)
   - DefendPlanet: 80 (difesa obiettivo)
   - HuntPlayer: 75 (combattimento attivo)
   - AttackPlanet/BombardPlanet: 70 (obiettivo offensivo)
   - CollectPowerup: 40 (opportunità)
   - OrbitPlanet: 20 (idle/pattuglia)

2. **Priorità della Decisione** (`DecisionPriority`):
   - emergency: 100 (evita morte imminente)
   - combat: 80 (combattimento)
   - objective: 60 (obiettivo principale)
   - opportunity: 40 (bonus)
   - idle: 20 (nessuna azione specifica)

**Priorità Totale** = `basePriority + decision.priority.rawValue`

Esempio:
- AvoidPlanet con emergency = 90 + 100 = 190 (vince sempre)
- HuntPlayer con combat = 75 + 80 = 155
- CollectPowerup con opportunity = 40 + 40 = 80

## Creare Nuovi Comportamenti

Per aggiungere un nuovo comportamento, implementa il protocollo `AIBehavior`:

```swift
class MyCustomBehavior: AIBehavior {
    let basePriority: Int = 60  // Scegli appropriatamente
    
    // Parametri personalizzati
    let myParameter: CGFloat
    
    init(myParameter: CGFloat = 1.0) {
        self.myParameter = myParameter
    }
    
    func evaluate(entity: AIEntity, context: AIContext) -> AIDecision? {
        // 1. Analizza la situazione
        // 2. Determina se questo comportamento è applicabile
        // 3. Restituisci una decisione o nil
        
        guard shouldActivate(entity: entity, context: context) else {
            return nil
        }
        
        let movement = calculateMovement(entity: entity, context: context)
        let shouldFire = checkFiring(entity: entity, context: context)
        
        return AIDecision(
            movement: movement,
            shouldFire: shouldFire,
            fireTarget: targetPosition,
            shouldBrake: false,
            priority: .objective
        )
    }
    
    private func shouldActivate(entity: AIEntity, context: AIContext) -> Bool {
        // Logica di attivazione
        return true
    }
    
    private func calculateMovement(entity: AIEntity, context: AIContext) -> CGVector {
        // Calcola direzione movimento
        return .zero
    }
    
    private func checkFiring(entity: AIEntity, context: AIContext) -> Bool {
        // Verifica se sparare
        return false
    }
}
```

## Integrazione con PlayerController Esistente

Il sistema AI Engine è **complementare** al `PlayerController.swift` esistente. Puoi:

1. **Migrare gradualmente**: Usa AIEngine per nuovi nemici, mantieni PlayerController per l'auto-play
2. **Sostituire completamente**: Converti PlayerController per usare AIEngine
3. **Usare in parallelo**: PlayerController per giocatore, AIEngine per nemici/alleati

### Opzione Consigliata: Adattatore

```swift
// Adattatore che usa AIEngine dietro PlayerController
class AIControllerAdapter: PlayerController {
    private let aiController: AIController
    private var aiEntity: AIEntity
    
    init(preset: (AIDifficulty) -> AIController, difficulty: AIDifficulty) {
        self.aiController = preset(difficulty)
        self.aiEntity = AIEntity(/* ... */)
    }
    
    func desiredMovement(for state: GameState) -> CGVector {
        // Converti GameState a AIContext
        let context = convertToAIContext(state)
        
        // Aggiorna entità
        updateEntity(from: state)
        
        // Ottieni decisione
        let decision = aiController.makeDecision(entity: aiEntity, context: context)
        
        return decision.movement
    }
    
    func shouldFire(for state: GameState) -> Bool {
        let context = convertToAIContext(state)
        updateEntity(from: state)
        let decision = aiController.makeDecision(entity: aiEntity, context: context)
        return decision.shouldFire
    }
    
    private func convertToAIContext(_ state: GameState) -> AIContext {
        // Conversione GameState -> AIContext
        return AIContext(/* ... */)
    }
    
    private func updateEntity(from state: GameState) {
        aiEntity.position = state.playerPosition
        aiEntity.velocity = state.playerVelocity
        aiEntity.angle = state.playerAngle
    }
}
```

## Vantaggi del Sistema

✅ **Modularità**: Comportamenti indipendenti e riutilizzabili
✅ **Estensibilità**: Facile aggiungere nuovi comportamenti
✅ **Flessibilità**: Combina comportamenti per creare AI complesse
✅ **Manutenibilità**: Ogni comportamento in un file separato
✅ **Testabilità**: Comportamenti testabili individualmente
✅ **Riusabilità**: Stesso codice per nemici, alleati, player
✅ **Dinamicità**: Modifica comportamenti a runtime
✅ **Priorità**: Sistema automatico di decisione

## Prossimi Passi

1. ✅ Sistema AI Engine creato
2. ⏳ Integrare AIEngine in GameScene per spawn nemici
3. ⏳ Creare classi EnemyShip, AllyShip con AI
4. ⏳ Aggiungere sistema di spawn ondate nemiche
5. ⏳ Bilanciare difficoltà e parametri AI
6. ⏳ Aggiungere comportamenti avanzati (formazioni, coordinamento)
7. ⏳ Sistema di ricompense per distruzione nemici
