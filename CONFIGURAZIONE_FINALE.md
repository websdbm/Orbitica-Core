# 🔧 CONFIGURAZIONE FINALE - App Transport Security

## ⚠️ IMPORTANTE: Configurare ATS in Xcode

Per risolvere l'errore **"App Transport Security policy requires the use of a secure connection"**, devi aggiungere il file `Info.plist` al progetto Xcode.

### Passi da seguire in Xcode:

1. **Apri Xcode** e il progetto `Orbitica Core.xcodeproj`

2. **Aggiungi Info.plist al target:**
   - Nel navigator a sinistra, clicca con tasto destro sulla cartella "Orbitica Core"
   - Seleziona **"Add Files to Orbitica Core..."**
   - Seleziona il file `Info.plist` che si trova in `Orbitica Core/Info.plist`
   - **IMPORTANTE**: Verifica che sia spuntato:
     - ☑️ "Copy items if needed"
     - ☑️ Target: "Orbitica Core"
   - Clicca **"Add"**

3. **Configura il target per usare Info.plist:**
   - Clicca sul progetto "Orbitica Core" in alto nel navigator
   - Seleziona il target "Orbitica Core"
   - Vai alla tab **"Build Settings"**
   - Cerca "Info.plist File" (usa la barra di ricerca)
   - Imposta il valore a: `Orbitica Core/Info.plist`

4. **Verifica la configurazione:**
   - Vai alla tab **"Info"** del target
   - Dovresti vedere la chiave **"App Transport Security Settings"**
   - Espandila e verifica che ci sia:
     - Exception Domains
       - formazioneweb.org
         - Allow Arbitrary Loads: YES
         - Include Subdomains: YES

### Alternativa: Modifica manualmente in Xcode

Se preferisci NON usare il file Info.plist separato:

1. Vai alla tab **"Info"** del target "Orbitica Core"
2. Clicca sul **"+"** per aggiungere una nuova chiave
3. Seleziona **"App Transport Security Settings"**
4. Espandi la freccia e clicca sul **"+"** a destra
5. Seleziona **"Exception Domains"**
6. Espandi e clicca **"+"** per aggiungere un dominio
7. Inserisci come chiave: **"formazioneweb.org"**
8. Espandi "formazioneweb.org" e aggiungi:
   - **"NSExceptionAllowsInsecureHTTPLoads"** = YES (Boolean)
   - **"NSIncludesSubdomains"** = YES (Boolean)

---

## ✅ Modifiche Completate

### 1. App Transport Security
- ✅ Creato file `Info.plist` con eccezione per `formazioneweb.org`
- ✅ Permette connessioni HTTP al server per HiScore

### 2. Pulsante SAVE SCORE nel Game Over
- ✅ Aggiunto pulsante giallo **"SAVE SCORE"** sopra RETRY/MENU
- ✅ Posizione: centrato, sotto il punteggio finale
- ✅ Al tap, apre la schermata inserimento iniziali (`InitialEntryScene`)
- ✅ I pulsanti RETRY e MENU sono stati spostati più in basso

### 3. Riduzione pulsanti del 20%
- ✅ Pulsante **"PLAY NOW"**: da 250x70 a 200x56 pixel
- ✅ Pulsante **"HI-SCORE"**: da 250x70 a 200x56 pixel
- ✅ Font ridotto: da 32pt a 26pt
- ✅ Posizione "HI-SCORE" leggermente più vicina a "PLAY NOW"

---

## 🎮 Funzionalità Complete

### Flusso Game Over:
1. **Pianeta distrutto** → Controllo automatico se score è top-10
2. **Se top-10** → Vai direttamente a `InitialEntryScene` (inserimento iniziali)
3. **Se NON top-10** → Mostra schermata Game Over con:
   - Punteggio finale
   - Wave raggiunta
   - Pulsante **SAVE SCORE** (giallo) → Permette di salvare comunque il punteggio
   - Pulsante **RETRY** → Ricomincia il gioco
   - Pulsante **MENU** → Torna al menu principale

### Menu Principale:
- **PLAY NOW** (bianco, 200x56px) → Avvia il gioco
- **HI-SCORE** (giallo, 200x56px) → Mostra classifica top 10

### Schermata HiScore:
- Carica automaticamente da server
- Mostra top 10 con iniziali, score e wave
- Pulsante BACK per tornare al menu

---

## 🚀 Test dell'App

Dopo aver configurato l'Info.plist in Xcode:

1. **Clean Build Folder**: ⇧⌘K (Shift+Cmd+K)
2. **Build**: ⌘B (Cmd+B)
3. **Run**: ⌘R (Cmd+R)

### Testa il flusso completo:
1. Avvia il gioco
2. Fatti colpire il pianeta fino al game over
3. Clicca **"SAVE SCORE"** → Dovrebbe aprire schermata inserimento iniziali
4. Inserisci 3 lettere e clicca **CONFIRM**
5. Verifica che il punteggio venga salvato
6. Dal menu principale, clicca **"HI-SCORE"** → Dovrebbe caricare la classifica

### Se vedi ancora l'errore ATS:
- Verifica che l'Info.plist sia nel target
- Prova a fare **Clean Build Folder** e ricompila
- Controlla che il percorso in Build Settings sia corretto

---

**✅ Tutte le modifiche sono complete e pronte per il test!** 🎮🏆
