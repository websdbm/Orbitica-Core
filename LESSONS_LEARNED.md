# Lezioni Apprese - Orbitica Core

## Projectile Reflection Feature (Nov 2025)

### 🔴 Problema Principale
Implementazione riflessione proiettili sull'atmosfera FALLITA dopo 10+ tentativi.

### 💡 Root Cause Identificata
**NON era un problema di bounce troppo rapido dello stesso proiettile.**
**ERA un problema di proiettili MULTIPLI sparati in rapida successione.**

Ogni proiettile è un oggetto separato con il proprio `userData`, quindi:
```
Proiettile A (ID: 0x4e0) → bounceCount=0 → incrementa a 1
Proiettile B (ID: 0x800) → bounceCount=0 → incrementa a 1 ← NUOVO oggetto!
Proiettile C (ID: 0x940) → bounceCount=0 → incrementa a 1 ← NUOVO oggetto!
```

### ❌ Cosa NON Funziona in SpriteKit

1. **userData per stato tra collisioni multiple**
   - Ogni SKNode ha il proprio userData
   - Non è condiviso tra istanze
   - Non è thread-safe

2. **contactTestBitMask disable/re-enable**
   - SpriteKit può chiamare `didBegin` anche dopo aver disabilitato
   - Race conditions possibili
   - Delay fissi non garantiscono nulla

3. **Push-out position da solo**
   - Funziona (confermato con visual markers)
   - Ma non basta se altri proiettili colpiscono subito dopo
   - Velocità 575px/s attraversa 25px in 0.043s

### ✅ Cosa HA Funzionato (per debug)

1. **Visual Debug Markers**
   ```swift
   let marker = SKShapeNode(circleOfRadius: 8)
   marker.fillColor = .yellow
   // ... ha confermato che push-out funzionava
   ```

2. **Object ID Tracking**
   ```swift
   print("ID: \(Unmanaged.passUnretained(node).toOpaque())")
   // Ha rivelato che erano oggetti diversi
   ```

3. **Before/After Value Logging**
   ```swift
   print("saved: \(projectile.userData?["bounceCount"] as? Int ?? -999)")
   // Ha mostrato che il valore veniva salvato ma perso tra oggetti
   ```

### 🎯 Best Practices Identificate

#### SpriteKit Physics
- ✅ Usa visual debug per fisica (shapes, colors, markers)
- ✅ Traccia ID oggetti quando debuggi collisioni multiple
- ✅ contactTestBitMask è una suggestion, non una garanzia
- ❌ Non usare userData per stato critico condiviso
- ❌ Non assumere che collision callbacks siano event-driven affidabili

#### Debugging Workflow
1. **Prima**: Visualizza il problema (markers, colors, shapes)
2. **Poi**: Traccia gli ID degli oggetti coinvolti
3. **Infine**: Log before/after di tutti i valori modificati
4. **Bonus**: Stampa timestamp per verificare race conditions

#### Gestione Stato in Giochi
- Stato per-oggetto → Properties dell'oggetto
- Stato condiviso → Variables della Scene
- Stato persistente → UserDefaults / Database
- ❌ **NON** userData per logica critica di gameplay

### 🔧 Soluzioni Alternative Proposte

#### Se dovessimo re-implementare:

**Opzione A: Collision Layer Separato**
```swift
// Dopo primo bounce, cambia category
projectile.physicsBody?.categoryBitMask = PhysicsCategory.bouncedProjectile
// bouncedProjectile non collide con atmosphere
```
✅ Semplice, garantito
❌ Solo 1 bounce possibile

**Opzione B: Rate Limiting Globale**
```swift
var lastAtmosphereBounceTime: TimeInterval = 0
if currentTime - lastAtmosphereBounceTime < 0.5 {
    projectile.removeFromParent()  // Distruggi
    return
}
```
✅ Controlla rate indipendentemente da quanti proiettili
❌ Gameplay innaturale

**Opzione C: Raycasting Predittivo**
```swift
// Calcola se uscirà dall'atmosfera prima di applicare bounce
let futurePos = pos + vel * 0.1
if futurePos è dentro atmosfera {
    // Ajusta velocità
}
```
✅ Matematicamente corretto
❌ Molto complesso

**Opzione D: Bounce come Nuovo Oggetto**
```swift
projectile.removeFromParent()
let newProjectile = createBounced(pos, vel, remainingBounces: 2)
```
✅ Nessun problema userData/collisions
❌ Possibile gap visivo

### 📊 Metriche

| Metrica | Valore |
|---------|--------|
| Tentativi totali | 10+ |
| Tempo investito | ~2 ore |
| Approcci diversi | 6 |
| Bug identificati | 3 |
| Linee scritte/rimosse | 200+ |
| **Successo** | ❌ 0% |

### 🎓 Key Takeaways

1. **Debugga SEMPRE con object identity tracking** quando hai collisioni multiple
2. **Visual feedback è più affidabile dei log** per problemi di fisica
3. **SpriteKit non è ottimale per meccaniche complesse di riflessione** senza workaround
4. **Archivia e documenta fallimenti** - sono più preziosi dei successi per imparare
5. **Non tutti i problemi sono risolvibili con l'approccio iniziale** - ok cambiare architettura

### 📝 Riferimenti

- Codice completo in: `REFLECTION_FEATURE_WIP.md`
- Formula riflessione (corretta): `v' = v - 2(v·n)n`
- Stack Overflow reference: CGVector.bounced(withNormal:)

### 🔮 Futuro

Se riprenderemo questa feature:
- ✅ Iniziare con approccio rayCasting O layer-based
- ✅ Prototipare con 1 solo proiettile prima di testare raffica
- ✅ Implementare visual debug da subito
- ❌ Non usare userData per bounceCount
- ❌ Non assumere che contactTestBitMask sia affidabile

---

**Conclusione**: A volte la soluzione migliore è **non implementare la feature** se richiede troppi workaround. Il comportamento originale (proiettile fermato da atmosfera) è più affidabile e performante.

**Data**: 9-10 Novembre 2025
**Status**: ✅ ARCHIVIATO con documentazione completa
