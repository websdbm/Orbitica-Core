# 🎬 Istruzioni Setup Sistema Regia & IA

## ✅ File Creati

Ho creato 3 nuovi file Swift per il sistema di registrazione video con IA:

1. **PlayerController.swift** - Protocollo per controllo unificato umano/IA
2. **ReplayManager.swift** - Manager per ReplayKit (registrazione schermo)
3. **RegiaScene.swift** - Pagina di configurazione demo/registrazione

## 📋 Prossimi Passi

### 1. Aggiungere i File al Progetto Xcode

**IMPORTANTE**: I file devono essere aggiunti al target "Orbitica Core"

**Manualmente:**
1. Apri `Orbitica Core.xcodeproj` in Xcode
2. Seleziona i 3 file nella cartella "Orbitica Core/":
   - `PlayerController.swift`
   - `ReplayManager.swift`
   - `RegiaScene.swift`
3. Trascinali nel Project Navigator di Xcode
4. Nella dialog che appare:
   - ✅ "Copy items if needed" (se non è già spuntato)
   - ✅ "Create groups"
   - ✅ Target: "Orbitica Core"
   - Clicca "Finish"

**Alternativamente:**
1. In Xcode, click destro sulla cartella "Orbitica Core" nel Project Navigator
2. "Add Files to 'Orbitica Core'..."
3. Seleziona i 3 file
4. Assicurati che "Orbitica Core" target sia selezionato
5. Click "Add"

### 2. Verificare la Compilazione

Dopo aver aggiunto i file, compila il progetto (⌘+B) per verificare che:
- Non ci siano errori di sintassi
- I file siano correttamente linkati
- ReplayKit framework sia disponibile (già incluso in iOS)

### 3. Modificare GameScene per Usare PlayerController

**File da modificare**: `GameScene.swift`

**Cambiamenti necessari**:

```swift
// Aggiungere property al GameScene
private var playerController: PlayerController?
private var aiDifficulty: AIController.AIDifficulty = .normal
private var useAIController: Bool = false

// Nel didMove(to view:) o init, configurare il controller
if useAIController {
    playerController = AIController(difficulty: aiDifficulty)
} else {
    playerController = HumanController()
}

// Nel update() sostituire il codice che legge joystick.direction
// PRIMA (codice attuale):
let direction = joystick.direction
// ... calcolo accelerazione ...

// DOPO:
guard let controller = playerController else { return }

// Costruisci GameState
let gameState = GameState(
    playerPosition: player.position,
    playerVelocity: playerVelocity,
    planetPosition: planet.position,
    planetRadius: planetRadius,
    asteroids: buildAsteroidInfo(),  // Crea array di AsteroidInfo
    isGrappled: isGrappled,
    orbitalDirection: lastOrbitalVelocity,
    currentWave: currentWave
)

let direction = controller.desiredMovement(for: gameState)
let shouldShoot = controller.shouldFire(for: gameState)

// Usa direction per accelerazione
// Usa shouldShoot per sparare automaticamente
```

**Helper per costruire AsteroidInfo**:
```swift
private func buildAsteroidInfo() -> [AsteroidInfo] {
    var asteroidList: [AsteroidInfo] = []
    
    worldLayer.enumerateChildNodes(withName: "asteroid") { node, _ in
        if let asteroid = node as? SKSpriteNode,
           let physics = asteroid.physicsBody {
            
            let distanceToPlanet = hypot(
                asteroid.position.x - planet.position.x,
                asteroid.position.y - planet.position.y
            )
            
            let info = AsteroidInfo(
                position: asteroid.position,
                velocity: physics.velocity,
                size: asteroid.size.width,
                health: 1.0,  // O usa un userData["health"] se hai questo sistema
                distanceFromPlanet: distanceToPlanet
            )
            asteroidList.append(info)
        }
    }
    
    return asteroidList
}
```

### 4. Aggiungere Parametri Configurabili a GameScene

**Aggiungi queste proprietà pubbliche**:
```swift
// Configurazione da RegiaScene
var startingWave: Int = 1
var selectedBackgroundIndex: Int?  // nil = random, altrimenti forza l'indice
var musicTrackName: String?  // nil = default, altrimenti forza traccia specifica
```

**Modifica setupInitialWave() per usare startingWave**:
```swift
private func setupInitialWave() {
    currentWave = startingWave  // Usa la wave configurata invece di 1
    waveLabel.text = "WAVE \(currentWave)"
    // ... resto del codice
}
```

**Modifica setupEnvironment() per usare backgroundIndex**:
```swift
private func setupEnvironment(for wave: Int) {
    if let forcedIndex = selectedBackgroundIndex {
        currentBackgroundIndex = forcedIndex
    } else {
        // Logica normale di cycling
        currentBackgroundIndex = (wave - 1) % backgrounds.count
    }
    
    // ... resto del codice
}
```

### 5. Passare Configurazione da RegiaScene a GameScene

**In RegiaScene.swift, modifica startDemo()**:
```swift
private func startDemo() {
    let gameScene = GameScene(size: size)
    gameScene.scaleMode = .aspectFill
    
    // Passa configurazione
    gameScene.startingWave = selectedWave
    gameScene.selectedBackgroundIndex = selectedBackground
    gameScene.musicTrackName = musicTracks[selectedMusic]
    gameScene.useAIController = autoPlay
    gameScene.aiDifficulty = selectedDifficulty
    
    // Se recording è attivo, continua a registrare durante il gameplay
    if recordingEnabled {
        print("🎥 Recording continues during gameplay")
    }
    
    view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 1.0))
}
```

### 6. Testing Workflow

1. **Avvia Orbitica Core** in Xcode
2. **Tap sul pulsante "REGIA"** nel Main Menu (accanto a DEBUG)
3. **Configura la sessione**:
   - Wave di partenza
   - Difficoltà IA (Easy/Normal/Hard)
   - Background (0-15)
   - Musica (Wave 1-3, Boss)
   - Toggle AI Autoplay ON
4. **Tap "START RECORDING"** (bottone diventa verde)
5. **Tap "START DEMO"** per lanciare il gioco
6. **L'IA giocherà automaticamente** mentre registri
7. **Ritorna alla RegiaScene** (o implementa un bottone in GameScene per tornare)
8. **Tap "STOP RECORDING"** per salvare il video

### 7. Verifiche Finali

- [ ] Compilazione senza errori
- [ ] Pulsante REGIA visibile nel Main Menu
- [ ] RegiaScene mostra tutti i controlli
- [ ] Selettori funzionano (◄ ►)
- [ ] Toggle Autoplay funziona
- [ ] Bottone registrazione cambia colore
- [ ] GameScene usa PlayerController
- [ ] IA gioca autonomamente
- [ ] Video salvato nel rullino

## 🎮 Come Funziona l'IA

### Logica AIController

1. **Mantieni Orbita Sicura**
   - Calcola distanza ideale dal pianeta (base * moltiplicatore difficoltà)
   - Se troppo vicino: thrust radiale verso l'esterno
   - Se troppo lontano: thrust radiale verso il pianeta
   - Se distanza OK: nessun thrust radiale

2. **Target Asteroidi Pericolosi**
   - Trova asteroide più pericoloso (vicino + veloce verso pianeta)
   - Punta verso l'asteroide
   - Combina con thrust orbitale per smooth tracking

3. **Spara Quando Allineato**
   - Rate limiting: 0.3s tra colpi
   - Controlla angolo tra direzione nave e asteroide
   - Tolleranza varia per difficoltà:
     - Easy: 0.4 radianti (~23°)
     - Normal: 0.3 radianti (~17°)
     - Hard: 0.2 radianti (~11°)

### Difficoltà

- **Easy**: Orbita larga (2.5x), mira imprecisa, reazione lenta
- **Normal**: Orbita media (2.2x), mira media, reazione normale
- **Hard**: Orbita stretta (2.0x), mira precisa, reazione veloce

## 📹 ReplayKit Notes

- **ReplayManager è un singleton**: `ReplayManager.shared`
- **Microfono/Camera disabilitati**: registra solo schermo + audio di gioco
- **Salvataggio automatico**: il video va nel rullino foto
- **Richiede permessi iOS**: prima volta chiederà autorizzazione
- **Callback asincroni**: usa closure per notifiche

## 🐛 Troubleshooting

**"Screen recording not available"**
- ReplayKit non funziona su Simulator (solo device reale)
- Verifica che non ci siano restrizioni iOS attive

**"IA non risponde correttamente"**
- Verifica che GameState sia costruito correttamente
- Debug con print() in AIController.desiredMovement()
- Controlla che buildAsteroidInfo() restituisca dati validi

**"Video non viene salvato"**
- Controlla permessi Foto nell'app Settings
- Verifica che stopRecording() venga chiamato correttamente
- ReplayKit ha timeout automatico di 15 minuti

**"Compilazione fallisce"**
- Verifica che i 3 file siano nel target "Orbitica Core"
- Pulisci build folder (Product > Clean Build Folder)
- Riavvia Xcode

## 🎯 Risultato Finale

Con questo sistema potrai:
- ✅ Configurare facilmente demo per video promozionali
- ✅ Far giocare l'IA automaticamente
- ✅ Registrare gameplay smooth senza input umano
- ✅ Scegliere wave, difficoltà, background e musica
- ✅ Salvare video HD nel rullino foto
- ✅ Creare trailer cinematici selezionando i momenti migliori

---

**Created by GitHub Copilot** 🤖
**Date**: November 11, 2024
