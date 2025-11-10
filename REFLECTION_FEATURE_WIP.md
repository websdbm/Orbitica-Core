# Projectile Reflection Feature (Work In Progress)

## Status: NON FUNZIONANTE - Da completare in futuro

## Problema
I proiettili trapassano l'atmosfera e il pianeta invece di rimbalzare correttamente.

## Causa Identificata
- Proiettili multipli (ID diversi) collidono in rapida successione
- Il `bounceCount` viene salvato correttamente ma letto sempre come 0 per nuovi proiettili
- Il push-out di 25px non è sufficiente a tenere il proiettile fuori dall'atmosfera
- Sistema di re-enable delle collisioni basato su distanza non funziona come previsto

## Codice Implementato

### CGVector Extension (FUNZIONANTE)
```swift
// MARK: - CGVector Extension for Reflection
extension CGVector {
    
    // Riflessione del vettore rispetto a una normale
    // Formula: v' = v - 2 * (v · n) * n
    func bounced(withNormal normal: CGVector) -> CGVector {
        let dotProduct = self * normal
        return CGVector(
            dx: self.dx - 2 * dotProduct * normal.dx,
            dy: self.dy - 2 * dotProduct * normal.dy
        )
    }
    
    var magnitude: CGFloat {
        return sqrt(dx * dx + dy * dy)
    }
    
    func normalized() -> CGVector {
        let length = magnitude
        guard length > 0 else { return CGVector.zero }
        return CGVector(dx: dx / length, dy: dy / length)
    }
    
    // Prodotto scalare
    static func * (lhs: CGVector, rhs: CGVector) -> CGFloat {
        return lhs.dx * rhs.dx + lhs.dy * rhs.dy
    }
}
```

### Bounce Helper Method
```swift
// MARK: - Projectile Bounce Helper
extension GameScene {
    func checkProjectileSafeDistance(_ projectile: SKNode, bounceCount: Int, iteration: Int) {
        guard projectile.parent != nil else { return }
        guard let planet = self.childNode(withName: "planet") else { return }
        
        let distance = hypot(projectile.position.x - planet.position.x,
                           projectile.position.y - planet.position.y)
        let safeDistance = atmosphereRadius + 30  // 30px oltre il bordo atmosfera
        
        if distance > safeDistance {
            // Proiettile completamente fuori, riabilita collisioni se non ha raggiunto max bounces
            if bounceCount < 3 {
                projectile.physicsBody?.contactTestBitMask = PhysicsCategory.atmosphere | PhysicsCategory.asteroid
            }
            projectile.userData?["isBouncing"] = false
            print("✅ Bounce complete, projectile safe at distance: \(Int(distance))px")
        } else if iteration < 40 {  // Max 2 secondi (40 * 0.05s)
            // Ancora troppo vicino, ricontrolla tra 0.05s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak projectile] in
                guard let self = self, let proj = projectile else { return }
                self.checkProjectileSafeDistance(proj, bounceCount: bounceCount, iteration: iteration + 1)
            }
        } else {
            // Timeout, riabilita comunque
            projectile.userData?["isBouncing"] = false
            print("⚠️ Bounce timeout, forcing re-enable")
        }
    }
}
```

### Collision Handling (in didBegin)
```swift
// Proiettile + Atmosfera (RIFLESSIONE)
if (bodyA.categoryBitMask == PhysicsCategory.projectile && bodyB.categoryBitMask == PhysicsCategory.atmosphere) ||
   (bodyA.categoryBitMask == PhysicsCategory.atmosphere && bodyB.categoryBitMask == PhysicsCategory.projectile) {
    
    let projectile = bodyA.categoryBitMask == PhysicsCategory.projectile ? bodyA.node : bodyB.node
    guard let projectile = projectile else { return }
    guard let projectilePhysics = projectile.physicsBody else { return }
    guard let planet = childNode(withName: "planet") else { return }
    
    // Controlla se è già in bounce (evita rimbalzi multipli rapidi)
    if let isBouncing = projectile.userData?["isBouncing"] as? Bool, isBouncing {
        print("⏭️ Bounce ignored - already bouncing")
        return
    }
    
    // Controlla contatore rimbalzi (max 3)
    var bounceCount = projectile.userData?["bounceCount"] as? Int ?? 0
    print("📊 Projectile ID: \(Unmanaged.passUnretained(projectile).toOpaque()), bounceCount: \(bounceCount)")
    
    if bounceCount >= 3 {
        createCollisionParticles(at: contact.contactPoint, color: .red)
        projectile.removeFromParent()
        print("💥 Projectile destroyed after 3 bounces")
        return
    }
    
    // Incrementa contatore PRIMA di tutto
    bounceCount += 1
    projectile.userData?["bounceCount"] = bounceCount
    projectile.userData?["isBouncing"] = true
    
    // Verifica che sia stato salvato
    let savedCount = projectile.userData?["bounceCount"] as? Int ?? -999
    print("⬆️ Incremented to bounceCount: \(bounceCount), saved: \(savedCount)")
    
    // 1. Calcola il normale al punto di contatto (dal centro pianeta verso esterno)
    let contactPoint = contact.contactPoint
    let normalVector = CGVector(
        dx: contactPoint.x - planet.position.x,
        dy: contactPoint.y - planet.position.y
    ).normalized()
    
    // 2. Disabilita temporaneamente collisioni con atmosfera (evita loop)
    let originalContactTestBitMask = projectilePhysics.contactTestBitMask
    projectilePhysics.contactTestBitMask = PhysicsCategory.asteroid  // Solo asteroidi
    
    // 3. Salva velocità PRIMA che la fisica la modifichi
    let currentVelocity = projectilePhysics.velocity
    let originalSpeed = currentVelocity.magnitude
    
    print("🔵 BOUNCE #\(bounceCount): speed=\(Int(originalSpeed))")
    
    // 4. Calcola la velocità riflessa usando la formula: v' = v - 2(v·n)n
    let reflectedVelocity = currentVelocity.bounced(withNormal: normalVector)
    let reflectedDirection = reflectedVelocity.normalized()
    
    // 5. PRIMA sposta il proiettile FUORI (IMPORTANTE!)
    let pushOutDistance: CGFloat = 25.0  // Aumentato per evitare bounce multipli
    let newPosition = CGPoint(
        x: contactPoint.x + normalVector.dx * pushOutDistance,
        y: contactPoint.y + normalVector.dy * pushOutDistance
    )
    projectile.position = newPosition
    
    // 6. POI applica la velocità riflessa
    let newVelocity = CGVector(
        dx: reflectedDirection.dx * originalSpeed,
        dy: reflectedDirection.dy * originalSpeed
    )
    projectilePhysics.velocity = newVelocity
    
    print("🔴 BOUNCE END: newVel=(\(Int(newVelocity.dx)),\(Int(newVelocity.dy))), newPos=(\(Int(newPosition.x)),\(Int(newPosition.y)))")
    print("✅ Projectile still exists: \(projectile.parent != nil)")
    
    // 7. Riabilita collisioni SOLO quando il proiettile è completamente fuori dall'atmosfera
    self.checkProjectileSafeDistance(projectile, bounceCount: bounceCount, iteration: 0)
    
    // Effetti visivi e ricarica atmosfera
    rechargeAtmosphere(amount: 1.05)
    flashAtmosphere()
    
    // Particelle FUORI dall'atmosfera (sul bordo esterno)
    let atmosphereThickness = atmosphereRadius - planetRadius
    let particlePosition = CGPoint(
        x: contactPoint.x + normalVector.dx * (atmosphereThickness + 5),
        y: contactPoint.y + normalVector.dy * (atmosphereThickness + 5)
    )
    createCollisionParticles(at: particlePosition, color: .cyan)
    
    // DEBUG: Marker visivo giallo per vedere dove va il proiettile
    let marker = SKShapeNode(circleOfRadius: 8)
    marker.fillColor = .yellow
    marker.strokeColor = .clear
    marker.position = newPosition
    marker.zPosition = 100
    addChild(marker)
    marker.run(SKAction.sequence([
        SKAction.wait(forDuration: 0.5),
        SKAction.fadeOut(withDuration: 0.2),
        SKAction.removeFromParent()
    ]))
    
    return
}
```

### Projectile Initialization
```swift
// In fireProjectile()
projectile.userData = NSMutableDictionary()
projectile.userData?["damageMultiplier"] = projectileDamageMultiplier
projectile.userData?["originalSize"] = NSValue(cgSize: usedSize)
projectile.userData?["bounceCount"] = 0  // Contatore rimbalzi per riflessione
```

## Cronologia dei Tentativi (Tutti Falliti)

### Tentativo 1: Push-out Fisso 2px
**Approccio:**
```swift
let pushOutDistance: CGFloat = 2.0
projectile.position = CGPoint(
    x: contactPoint.x + normalVector.dx * pushOutDistance,
    y: contactPoint.y + normalVector.dy * pushOutDistance
)
```
**Risultato:** ❌ Proiettile rientra immediatamente nell'atmosfera, bounce multipli rapidissimi
**Problema:** Distanza troppo piccola, proiettile ancora dentro il collision volume

### Tentativo 2: Aumento Push-out a 10px
**Approccio:** Incrementato `pushOutDistance` da 2px a 10px
**Risultato:** ❌ Ancora bounce multipli, leggermente rallentati ma non risolti
**Problema:** 10px non sufficienti, atmosfera troppo spessa

### Tentativo 3: contactTestBitMask Disable/Re-enable
**Approccio:**
```swift
// Disabilita subito
projectilePhysics.contactTestBitMask = PhysicsCategory.asteroid

// Riabilita dopo delay
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    proj.physicsBody?.contactTestBitMask = PhysicsCategory.atmosphere | PhysicsCategory.asteroid
}
```
**Risultato:** ❌ Bounce multipli continuano, delay 0.1s troppo breve
**Problema:** Proiettile torna nell'atmosfera prima che il delay scada

### Tentativo 4: Push-out 15px + Delay 0.15s
**Approccio:** Combinazione di push-out aumentato + delay più lungo
**Risultato:** ❌ Miglioramento minimo, ancora 3 bounce rapidi in ~0.3s
**Problema:** Velocità proiettile (575 px/s) troppo alta rispetto al push-out

### Tentativo 5: Flag `isBouncing` per Prevenire Re-entry
**Approccio:**
```swift
if let isBouncing = projectile.userData?["isBouncing"] as? Bool, isBouncing {
    return  // Ignora contatti durante bounce
}
projectile.userData?["isBouncing"] = true
```
**Risultato:** ⚠️ Parzialmente funzionante - blocca alcuni bounce ma non tutti
**Problema:** Flag viene controllato DOPO che didBegin è chiamato, race condition possibile

### Tentativo 6: Push-out 25px + isBouncing + Delay 0.2s
**Approccio:** Combinazione di tutte le tecniche precedenti
**Risultato:** ❌ Ancora bounce multipli, log mostra "⏭️ Bounce ignored" ma proiettile trapassa
**Problema:** Proiettili DIVERSI (ID diversi) collidono, non lo stesso proiettile che rimbalza

### Tentativo 7: Debug con Unmanaged.passUnretained per Tracking ID
**Approccio:**
```swift
print("📊 Projectile ID: \(Unmanaged.passUnretained(projectile).toOpaque()), bounceCount: \(bounceCount)")
```
**Risultato:** 🔍 **SCOPERTA CRUCIALE**: Gli ID sono DIVERSI ad ogni bounce!
- `0x000000010f47a4e0`
- `0x000000010f47a800` ← Proiettile DIVERSO!
- `0x000000010f47a940` ← Altro proiettile!

**Lezione:** Non è lo stesso proiettile che rimbalza, sono proiettili multipli sparati in rapida successione

### Tentativo 8: Sistema Distance-Based Re-enable
**Approccio:**
```swift
func checkProjectileSafeDistance(_ projectile: SKNode, bounceCount: Int, iteration: Int) {
    let distance = hypot(proj.position.x - planet.position.x, proj.position.y - planet.position.y)
    let safeDistance = atmosphereRadius + 30
    
    if distance > safeDistance {
        // Riabilita collisioni
    } else {
        // Ricontrolla tra 0.05s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { ... }
    }
}
```
**Risultato:** ❌ Proiettili continuano a trapassare, nessun log "✅ Bounce complete, projectile safe"
**Problema:** Metodo mai chiamato con successo, proiettili troppo veloci o già distrutti

### Tentativo 9: Incremento bounceCount SUBITO Dopo Lettura
**Approccio:**
```swift
var bounceCount = projectile.userData?["bounceCount"] as? Int ?? 0
bounceCount += 1
projectile.userData?["bounceCount"] = bounceCount  // Salva immediatamente
```
**Risultato:** ❌ Valore salvato correttamente (`saved: 1`) ma alla prossima collision torna a 0
**Problema:** Proiettili diversi hanno userData separati, ogni nuovo proiettile parte da bounceCount=0

### Tentativo 10: Yellow Debug Markers
**Approccio:**
```swift
let marker = SKShapeNode(circleOfRadius: 8)
marker.fillColor = .yellow
marker.position = newPosition
addChild(marker)
marker.run(SKAction.sequence([
    SKAction.wait(forDuration: 0.5),
    SKAction.fadeOut(withDuration: 0.3),
    SKAction.removeFromParent()
]))
```
**Risultato:** ✅ Markers visibili, CONFERMANO che push-out funziona
**Conclusione:** Il problema NON è il push-out, ma la gestione di proiettili multipli

## Analisi Finale del Problema

### Problema Principale Identificato
**NON è un problema di un singolo proiettile che rimbalza troppo velocemente.**

È un problema di **PROIETTILI MULTIPLI in rapida successione**:
1. Utente tiene premuto il tasto di sparo
2. Proiettile 1 colpisce atmosfera, viene spostato fuori
3. Proiettile 2 (appena sparato) colpisce atmosfera 0.1s dopo
4. Proiettile 3 colpisce atmosfera subito dopo
5. Ogni proiettile ha `bounceCount=0` perché è un oggetto diverso

### Perché userData["bounceCount"] Fallisce
```
📊 Projectile ID: 0x10f47a4e0, bounceCount: 0  ← Proiettile A
⬆️ Incremented to bounceCount: 1, saved: 1     ← Salva in A.userData
✅ Bounce complete, ready for next bounce

📊 Projectile ID: 0x10f47a800, bounceCount: 0  ← Proiettile B (NUOVO!)
⬆️ Incremented to bounceCount: 1, saved: 1     ← Salva in B.userData
✅ Bounce complete, ready for next bounce
```

**Ogni proiettile è un'istanza separata con il proprio userData.**

### Perché il Push-out Non Basta
- Velocità proiettile: ~575 px/s
- Push-out: 25px
- Tempo per attraversare 25px: 0.043s
- Delay re-enable: 0.2s
- **Risultato:** Proiettile può teoricamente fare round-trip completo prima del re-enable

### Problemi Architetturali di SpriteKit
1. **didBegin chiamato anche con contactTestBitMask=0**: Bug o feature di SpriteKit
2. **Race conditions su userData**: Dictionary non thread-safe
3. **Physics step discreto**: Proiettile può "saltare" attraverso atmosfera tra un frame e l'altro
4. **Collision detection volume-based**: Non posizionale, reagisce al overlap anche minimo

## Possibili Soluzioni Future

### Soluzione 1: Rate Limiting per Proiettili
```swift
// Traccia ultimo bounce GLOBALE, non per-proiettile
var lastBounceTime: TimeInterval = 0
let minTimeBetweenBounces: TimeInterval = 0.5

if currentTime - lastBounceTime < minTimeBetweenBounces {
    projectile.removeFromParent()  // Distruggi invece di far rimbalzare
    return
}
lastBounceTime = currentTime
```
**Pro:** Limita bounce indipendentemente da quanti proiettili
**Contro:** Gameplay innaturale, proiettili distrutti arbitrariamente

### Soluzione 2: Raycasting Predittivo
```swift
// Prima del bounce, verifica traiettoria futura
let futurePosition = projectile.position + velocity * 0.1  // 0.1s nel futuro
if futurePosition è dentro atmosfera {
    // Ajusta velocità per garantire uscita
}
```
**Pro:** Matematicamente garantisce uscita
**Contro:** Complesso, computazionalmente costoso, fisica non realistica

### Soluzione 3: Collision Layer Separato
```swift
// Dopo bounce, cambia category
projectile.physicsBody?.categoryBitMask = PhysicsCategory.bouncedProjectile
// bouncedProjectile NON collide con atmosphere
```
**Pro:** Semplice, garantito funzionamento
**Contro:** Un solo bounce possibile, perde il meccanismo "3 bounces"

### Soluzione 4: Bounce come Nuovo Oggetto
```swift
// Distruggi vecchio proiettile
projectile.removeFromParent()

// Crea NUOVO proiettile con velocità riflessa
let bouncedProjectile = createBouncedProjectile(
    position: newPosition,
    velocity: reflectedVelocity,
    remainingBounces: 2
)
```
**Pro:** Nessun problema di userData o collision persistence
**Contro:** Possibile gap visivo, trail particle non continuo

### Soluzione 5: Fisica Manuale Post-Bounce
```swift
// Dopo bounce, disabilita TUTTA la fisica
projectile.physicsBody = nil

// Gestisci movimento manualmente in update()
projectile.position.x += velocity.dx * deltaTime
projectile.position.y += velocity.dy * deltaTime

// Riabilita fisica solo quando fuori da safe zone
if distance > atmosphereRadius + 50 {
    attachPhysicsBody(to: projectile)
}
```
**Pro:** Controllo totale, nessuna collisione indesiderata
**Contro:** Complesso, perde collisioni con asteroidi durante movimento

### Soluzione 6: Atmosphere "One-Way Collision"
```swift
// Atmosfera collide solo con proiettili in INGRESSO
if velocity è verso il centro {
    // Bounce
} else {
    // Ignora (proiettile sta uscendo)
}
```
**Pro:** Elegante, matematicamente corretto
**Contro:** Difficile determinare "verso centro" con precisione in collision callback

## Lezioni Apprese (IMPORTANTI!)

### ❌ NON FARE:
1. **Non assumere che lo stesso oggetto causa bounce multipli** - Verificare sempre con ID tracking
2. **Non fidarsi solo di userData per stato persistente** - Proiettili multipli hanno userData separati
3. **Non usare delay fissi per problemi di fisica** - Velocità può variare, delay arbitrari falliscono
4. **Non manipolare contactTestBitMask senza verificare SpriteKit lo rispetti** - Può avere race conditions
5. **Non incrementare valori in userData senza verificare salvataggio** - Optional chaining può fallire silenziosamente

### ✅ FARE:
1. **Tracciare ID degli oggetti in debugging** - `Unmanaged.passUnretained().toOpaque()` è tuo amico
2. **Usare visual markers per debug fisico** - Yellow circles hanno rivelato che push-out funzionava
3. **Stampare PRIMA e DOPO modifiche** - `saved: \(value)` ha rivelato il problema userData
4. **Considerare architettura a eventi invece di stato** - Bounce potrebbe essere meglio come "evento" globale
5. **Testare con rate di fire diversi** - Problema emerso solo con sparo continuo

### 🔧 Best Practices per SpriteKit Physics:
1. **Collision detection non è event-driven affidabile** - È volume-based e può avere false positive
2. **userData è per metadati, non per stato critico** - Usare properties dedicate o dictionary esterni
3. **contactTestBitMask è suggestion, non garanzia** - SpriteKit può chiamare didBegin comunque
4. **Push-out deve essere > collision detection tolerance** - ~30-50px minimo per oggetti veloci
5. **Physics bodies possono "tunnel" se troppo veloci** - Considera continuous collision detection

## Metriche dei Test
- **Tentativi totali**: 10+
- **Tempo speso**: ~2 ore
- **Approcci diversi**: 6 (push-out, flags, delays, distance-check, userData, visual debug)
- **Bug identificati**: 3 (userData non persiste tra oggetti, ID diversi, SpriteKit race condition)
- **Linee di codice scritte e poi rimosse**: ~200+

## Note Tecniche Finali
- La matematica della riflessione è **CORRETTA** (formula verificata: v' = v - 2(v·n)n)
- Il push-out position funziona **CORRETTAMENTE** (markers gialli lo confermano)
- Il problema è **ARCHITETTURALE**, non implementativo
- SpriteKit non è progettato per questo tipo di meccanica senza workaround pesanti

## Raccomandazione
**NON implementare questa feature con l'approccio attuale.**

Opzioni:
1. **Archiviare e tornare più tardi** con approccio rayCasting ✅ (SCELTA ATTUALE)
2. **Semplificare**: Solo 1 bounce, poi distruggi
3. **Cambiare meccanica**: Atmosfera rallenta invece di riflettere
4. **Framework diverso**: Metal per fisica custom (overkill)

## Data: 9-10 novembre 2025
## Status: ARCHIVIATO - Da riprendere con approccio rayCasting o layer-based
