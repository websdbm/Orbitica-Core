# 🏆 SETUP SISTEMA HI-SCORE

## ✅ File Creati

### Swift (iOS App)
- ✅ `HiScoreScene.swift` - Schermata top 10 classifica
- ✅ `InitialEntryScene.swift` - Inserimento iniziali 3 lettere
- ✅ `MainMenuScene.swift` - Aggiunto pulsante "HI-SCORE"
- ✅ `GameScene.swift` - Integrazione controllo top-10 su game over

### Backend (Server)
- ✅ `database.sql` - Schema database MariaDB/MySQL
- ✅ `server/score.php` - REST API per salvare/recuperare scores

---

## 📋 PASSI PER COMPLETARE L'INTEGRAZIONE

### 1. Aggiungi i file Swift al progetto Xcode

1. Apri **Xcode** e il progetto `Orbitica Core.xcodeproj`
2. Nel navigator a sinistra, clicca con tasto destro sulla cartella "Orbitica Core"
3. Seleziona **"Add Files to Orbitica Core..."**
4. Seleziona questi file:
   - `HiScoreScene.swift`
   - `InitialEntryScene.swift`
5. **IMPORTANTE**: Verifica che sia spuntato:
   - ☑️ "Copy items if needed"
   - ☑️ Target: "Orbitica Core"
6. Clicca **"Add"**

### 2. Configura il database sul server

1. Accedi al tuo server MariaDB/MySQL
2. Crea il database (se non esiste):
   ```sql
   CREATE DATABASE orbitica_scores;
   USE orbitica_scores;
   ```
3. Esegui lo script `database.sql`:
   ```bash
   mysql -u username -p orbitica_scores < database.sql
   ```
   O copia/incolla il contenuto di `database.sql` nel pannello phpMyAdmin

### 3. Carica il file PHP sul server

1. Connetti via FTP/SFTP al server `formazioneweb.org`
2. Naviga alla cartella `/orbitica/` (o crea la cartella)
3. Carica il file `server/score.php` nella cartella
4. **IMPORTANTE**: Modifica le credenziali database nel file `score.php`:
   ```php
   // MODIFICA QUESTI VALORI CON LE TUE CREDENZIALI
   $host = 'localhost';
   $user = 'TUO_USERNAME';        // ← CAMBIA QUI
   $password = 'TUA_PASSWORD';    // ← CAMBIA QUI
   $database = 'orbitica_scores'; // ← CAMBIA QUI (se diverso)
   ```

### 4. Verifica configurazione server

1. Verifica che il file sia accessibile:
   ```
   http://formazioneweb.org/orbitica/score.php
   ```
   Dovresti vedere: `{"success": false, "error": "Invalid action"}`

2. Testa l'API con un GET:
   ```
   http://formazioneweb.org/orbitica/score.php?action=list
   ```
   Dovresti vedere: `{"success": true, "scores": [], "count": 0}`

### 5. Abilita App Transport Security (ATS) su iOS

Se il server NON usa HTTPS, devi modificare `Info.plist`:

1. Apri il file `Info.plist` in Xcode
2. Aggiungi questa configurazione:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>formazioneweb.org</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

⚠️ **NOTA**: In produzione è altamente consigliato usare HTTPS con certificato SSL valido.

### 6. Compila e testa l'app

1. In Xcode: **Product → Clean Build Folder** (⇧⌘K)
2. **Product → Build** (⌘B)
3. Se ci sono errori di compilazione, verifica che tutti i file Swift siano nel target
4. **Product → Run** (⌘R)

---

## 🎮 FUNZIONALITÀ IMPLEMENTATE

### Menu Principale
- ✅ Pulsante **"PLAY NOW"** - Avvia il gioco
- ✅ Pulsante **"HI-SCORE"** (giallo) - Mostra classifica top 10

### Durante il Gioco
- Quando `planetHealth` arriva a 0 → Game Over
- Sistema controlla automaticamente se score qualifica per top-10

### Game Over con Top-10
1. **Se score NON è top-10**: Mostra schermata classica "GAME OVER" con:
   - Punteggio finale
   - Wave raggiunta
   - Pulsanti RETRY / MENU

2. **Se score È top-10**: Mostra schermata "NEW HIGH SCORE!" con:
   - Inserimento 3 iniziali (A-Z)
   - Frecce ▲▼ per cambiare lettera
   - Tap su box per cambiare posizione
   - Pulsante CONFIRM (verde)
   - Salvataggio automatico su server
   - Mostra rank (#1, #2, ecc.)
   - Redirect automatico a HiScoreScene dopo 2 secondi

### Schermata HiScore
- Titolo "HIGH SCORES" (giallo)
- Sottotitolo "TOP 10 PILOTS" (cyan)
- Tabella con colonne: #, PILOT, SCORE, WAVE
- Colori speciali:
  - 🥇 #1: Oro (giallo)
  - 🥈 #2: Argento (grigio chiaro)
  - 🥉 #3: Bronzo (arancione)
  - #4-10: Bianco
- Slot vuoti mostrati in grigio scuro
- Pulsante **BACK** per tornare al menu

---

## 🔧 TROUBLESHOOTING

### Errore "Invalid URL" o "Network error"
- ✅ Verifica che l'URL sia corretto: `http://formazioneweb.org/orbitica/score.php`
- ✅ Controlla connessione internet del dispositivo
- ✅ Verifica ATS settings in Info.plist (se non usi HTTPS)

### Errore "Parse error"
- ✅ Verifica che `score.php` restituisca JSON valido
- ✅ Controlla errori PHP (abilita `error_reporting` temporaneamente)

### "Connection to database failed"
- ✅ Verifica credenziali database in `score.php`
- ✅ Controlla che il database `orbitica_scores` esista
- ✅ Verifica permessi utente MySQL (SELECT, INSERT)

### App crasha su game over
- ✅ Verifica che tutti i file Swift siano aggiunti al target in Xcode
- ✅ Controlla console Xcode per errori
- ✅ Verifica che URLSession funzioni (prova prima senza API)

### Iniziali non salvate / Rank sempre 0
- ✅ Verifica che la tabella `hiscores` sia creata correttamente
- ✅ Controlla che l'API POST restituisca `{"success": true, "rank": X}`
- ✅ Verifica formato JSON inviato (deve essere `{"initials":"ABC", "score":1000, "wave":5}`)

---

## 📊 STRUTTURA DATABASE

```sql
CREATE TABLE hiscores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_initials VARCHAR(3) NOT NULL,    -- Esattamente 3 lettere A-Z
    score INT NOT NULL,                      -- Punteggio
    wave INT NOT NULL DEFAULT 1,             -- Wave raggiunta
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Data/ora automatica
    device_id VARCHAR(255) DEFAULT NULL,     -- UUID dispositivo iOS
    INDEX idx_score (score DESC)             -- Indice per query veloci
);
```

---

## 🌐 API ENDPOINTS

### GET /score.php?action=list
Restituisce top 10 scores

**Response:**
```json
{
  "success": true,
  "scores": [
    {
      "initials": "ACE",
      "score": 15000,
      "wave": 12,
      "date": "2025-05-07 16:30:00"
    },
    // ... altri 9 record
  ],
  "count": 10
}
```

### POST /score.php?action=save
Salva nuovo score

**Request Body:**
```json
{
  "initials": "ABC",     // Esattamente 3 lettere A-Z (obbligatorio)
  "score": 5000,         // Intero positivo (obbligatorio)
  "wave": 5,             // Intero positivo (obbligatorio)
  "device_id": "UUID"    // UUID dispositivo (opzionale)
}
```

**Response:**
```json
{
  "success": true,
  "rank": 7,           // Posizione in classifica
  "isTopTen": true,    // True se rank <= 10
  "message": "Score saved successfully"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Initials must contain only letters A-Z"
}
```

---

## ✨ STILE RETRO ARCADE

Design ispirato agli arcade anni '80:
- Font **Courier-Bold** per iniziali (monospaced)
- **AvenirNext-Bold** per titoli e pulsanti
- Colori primari: Giallo (#FFFF00), Cyan (#00FFFF), Verde (#00FF00)
- Animazioni blink per elementi interattivi
- Bordi bianchi/colorati con alpha transparency
- Background nero con overlay trasparenti
- Cursor lampeggiante per input iniziali

---

## 🎯 PROSSIMI PASSI OPZIONALI

- [ ] Aggiungere effetti sonori (beep arcade) su button press
- [ ] Animazione CRT scanlines su HiScoreScene
- [ ] Leaderboard giornaliera/settimanale oltre alla globale
- [ ] Condivisione score su social media
- [ ] Achievement system (badge per milestone)
- [ ] Replay delle partite top-10

---

**✅ Setup completato! Ora compila e testa l'app.**

Se hai problemi, controlla prima:
1. File Swift aggiunti al target
2. Credenziali database corrette in score.php
3. ATS configurato in Info.plist (se HTTP)
4. Connessione internet attiva

🚀 **Buon divertimento con Orbitica Core!**
