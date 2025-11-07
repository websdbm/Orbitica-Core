# Font Setup - Orbitron

## Font Information
- **Font Name**: Orbitron (Google Fonts)
- **File**: Orbitron-Bold.ttf
- **Source**: https://fonts.google.com/specimen/Orbitron
- **Style**: Bold, geometric, sci-fi aesthetic
- **License**: SIL Open Font License (free for commercial use)

## Installation Steps

1. ✅ Font file downloaded to: `Orbitica Core/Orbitron-Bold.ttf`
2. ✅ Updated `project.pbxproj` with `INFOPLIST_KEY_UIAppFonts = "Orbitron-Bold.ttf"`
3. ✅ Updated code to use font names: `["Orbitron-Bold", "Orbitron", "Orbitron-Regular"]`
4. ⚠️ **NEXT STEP**: Add `Orbitron-Bold.ttf` to Xcode target in Build Phases → Copy Bundle Resources

## Manual Steps Required

### In Xcode:
1. Apri `Orbitica Core.xcodeproj` in Xcode
2. Trascina il file `Orbitron-Bold.ttf` dalla cartella `Orbitica Core/` nel navigatore del progetto
3. Nella finestra che appare:
   - ✅ Seleziona "Copy items if needed"
   - ✅ Seleziona il target "Orbitica Core"
   - Click "Finish"
4. Verifica in Build Phases → Copy Bundle Resources che `Orbitron-Bold.ttf` sia presente
5. Build e Run

## Font Names to Test

Il codice prova questi nomi in ordine:
1. `Orbitron-Bold` (nome preferito)
2. `Orbitron` (variante)
3. `Orbitron-Regular` (fallback)
4. `AvenirNext-Bold` (fallback di sistema)

## Verification

Dopo il build, controlla la console per:
- ✅ Success: `"✅ Font found: Orbitron-Bold"`
- ❌ Failure: `"⚠️ Orbitron font not found, using fallback: AvenirNext-Bold"`

## Why Orbitron?

Orbitron è perfetto per giochi spaziali/sci-fi:
- Design geometrico e futuristico
- Ottima leggibilità anche a piccole dimensioni
- Supporto completo per caratteri latini
- Testato e compatibile con iOS
- Licenza open source (SIL OFL)

## Files Updated

- `Orbitica Core/MainMenuScene.swift` - Title and button font
- `Orbitica Core/GameScene.swift` - Score and wave messages font
- `Orbitica Core.xcodeproj/project.pbxproj` - INFOPLIST_KEY_UIAppFonts registration
