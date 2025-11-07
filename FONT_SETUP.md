# Istruzioni per Aggiungere il Font Zerovelo

## Il progetto NON ha Info.plist separato - usa configurazione moderna

### Opzione 1: Tramite Xcode UI (Più Semplice) ✅

1. **Aggiungi il file font al progetto**
   - In Xcode, nel Project Navigator, trascina il file `zerovelo 2.ttf` dentro la cartella "Orbitica Core"
   - Oppure: click destro sulla cartella "Orbitica Core" → "Add Files to 'Orbitica Core'..."
   - ✅ Spunta "Copy items if needed"
   - ✅ Spunta il target "Orbitica Core"
   - Click su "Add"

2. **Verifica che il font sia nel Copy Bundle Resources**
   - Nel Project Navigator, seleziona il progetto "Orbitica Core" (icona blu in alto)
   - Seleziona il target "Orbitica Core"
   - Vai al tab "Build Phases"
   - Espandi "Copy Bundle Resources"
   - ✅ Verifica che `zerovelo 2.ttf` sia nella lista
   - Se non c'è, usa il bottone "+" per aggiungerlo

3. **Aggiungi il font alle Info.plist Keys**
   - Seleziona il target "Orbitica Core"
   - Vai al tab "Info"
   - Cerca la sezione "Custom iOS Target Properties"
   - Click sul "+" in basso per aggiungere una nuova proprietà
   - Nella dropdown, cerca e seleziona: **"Fonts provided by application"** 
   - Questo creerà una proprietà di tipo Array
   - Click sulla freccia per espandere l'array
   - Click sul "+" per aggiungere un item
   - Inserisci come valore: `zerovelo 2.ttf` (nome ESATTO del file)

4. **Clean Build e Ricompila**
   - Product → Clean Build Folder (Shift + Cmd + K)
   - Product → Build (Cmd + B)

---

### Opzione 2: Manualmente nel project.pbxproj (Avanzato)

Se preferisci editare manualmente:

1. Apri il file `Orbitica Core.xcodeproj/project.pbxproj` in un editor di testo
2. Cerca la sezione con `INFOPLIST_KEY` per il target principale
3. Aggiungi questa riga:
   ```
   INFOPLIST_KEY_UIAppFonts = "zerovelo 2.ttf";
   ```

---

## Verifica il nome corretto del font

Il **nome del file** è `zerovelo 2.ttf` (con spazio)  
Ma il **nome del font** potrebbe essere diverso!

Aggiungi temporaneamente questo codice in `GameViewController.swift` nella funzione `viewDidLoad()`:

```swift
// Debug: stampa tutti i font disponibili
print("=== AVAILABLE FONTS ===")
for family in UIFont.familyNames.sorted() {
    print("Family: \(family)")
    for name in UIFont.fontNames(forFamilyName: family) {
        print("  - \(name)")
    }
}
```

Compila ed esegui, poi cerca "Zerovelo" nella console di Xcode. Il nome potrebbe essere:
- `Zerovelo`
- `Zerovelo-Regular`
- `zerovelo`
- Altro...

Usa il nome ESATTO che appare nella console nei tuoi SKLabelNode.

---

## Troubleshooting

### Il font non appare?
1. ✅ Verifica che il file sia in "Copy Bundle Resources"
2. ✅ Verifica che il nome in "Fonts provided by application" sia esatto: `zerovelo 2.ttf`
3. ✅ Fai Clean Build Folder
4. ✅ Controlla la console per errori tipo "Could not load font"
5. ✅ Verifica il nome del font con il codice debug sopra

### Fallback temporaneo
Se hai problemi urgenti, puoi usare un font di sistema modificando nei file:
- Da: `fontNamed: "Zerovelo"`
- A: `fontNamed: "Helvetica-Bold"` o `"AvenirNext-Bold"`

Questi font sono sempre disponibili su iOS.

