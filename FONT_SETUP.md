# Istruzioni per Aggiungere il Font Zerovelo

## Passi da seguire in Xcode:

### 1. Aggiungi il file font al progetto
1. In Xcode, nel Project Navigator, fai click destro sulla cartella "Orbitica Core"
2. Seleziona "Add Files to 'Orbitica Core'..."
3. Naviga a `/Users/a.grassi/app-projects/Orbitica Core/zerovelo.ttf`
4. Assicurati che sia spuntato "Copy items if needed"
5. Assicurati che sia spuntato il target "Orbitica Core"
6. Click su "Add"

### 2. Verifica che il font sia nel Bundle
1. Nel Project Navigator, seleziona il progetto "Orbitica Core" (icona blu in alto)
2. Seleziona il target "Orbitica Core"
3. Vai al tab "Build Phases"
4. Espandi "Copy Bundle Resources"
5. Verifica che `zerovelo.ttf` sia nella lista
6. Se non c'è, usa il bottone "+" per aggiungerlo

### 3. Registra il font nell'Info.plist
1. Nel Project Navigator, trova il file `Info.plist` (potrebbe essere in Orbitica Core/Supporting Files)
2. Se non esiste, crealo facendo click destro > New File > Property List
3. Aggiungi una nuova riga:
   - Key: `Fonts provided by application` (o `UIAppFonts`)
   - Type: Array
4. Aggiungi un Item all'array:
   - Type: String
   - Value: `zerovelo.ttf`

**Oppure in modalità Source Code** (click destro su Info.plist > Open As > Source Code):
```xml
<key>UIAppFonts</key>
<array>
    <string>zerovelo.ttf</string>
</array>
```

### 4. Verifica il nome del font
Per verificare che il font sia registrato correttamente, puoi temporaneamente aggiungere questo codice in `viewDidLoad` di `GameViewController.swift`:

```swift
// Debug: stampa tutti i font disponibili
for family in UIFont.familyNames.sorted() {
    print("Family: \(family)")
    for name in UIFont.fontNames(forFamilyName: family) {
        print("  - \(name)")
    }
}
```

Cerca "Zerovelo" nell'output della console. Il nome esatto potrebbe essere diverso (es. "Zerovelo-Regular").

### 5. Clean Build
1. In Xcode, vai su Product > Clean Build Folder (Shift + Cmd + K)
2. Ricompila il progetto (Cmd + B)

## Troubleshooting

Se il font non viene caricato:
1. Verifica che il nome del font sia esatto (potrebbe essere "Zerovelo-Regular" invece di "Zerovelo")
2. Assicurati che il file .ttf sia effettivamente nel bundle
3. Controlla la console per eventuali errori di caricamento font
4. Prova a usare un font di sistema come fallback: `"Helvetica-Bold"`

## Fallback temporaneo
Se hai problemi, puoi temporaneamente usare un font di sistema modificando in tutti i file:
- Da: `fontNamed: "Zerovelo"`
- A: `fontNamed: "Helvetica-Bold"`
