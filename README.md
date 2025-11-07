# 🚀 GRAVITY SHIELD - Orbitica Core

Un gioco arcade a fisica orbitale ispirato ai classici come Asteroids, ambientato in un micro-sistema planetario dinamico.

## 🎮 Concept

**Orbitica Core** è un gioco arcade che fonde la chiarezza di Asteroids con una fisica orbitale elegante. Il giocatore deve proteggere un pianeta dotato di atmosfera difensiva dagli asteroidi in caduta orbitale, pilotando una piccola astronave attratta anch'essa dalla gravità del pianeta.

## ✨ Caratteristiche Principali

### Fisica Orbitale
- **Attrazione gravitazionale centrale** dal pianeta che influenza tutti i corpi
- **Orbite ellittiche** con decadimento graduale verso il pianeta
- **Gravità locale** esercitata dagli asteroidi grandi sui frammenti più piccoli
- **Movimento realistico** con inerzia e forze applicate

### Entità di Gioco

#### 🌍 Pianeta
- Corpo statico al centro dello schermo
- Protetto da un'atmosfera che funge da scudo
- Può subire 3 impatti diretti prima di essere distrutto

#### 💫 Atmosfera Difensiva
- Anello luminoso azzurro che cresce e si riduce in base agli impatti
- I rimbalzi sull'atmosfera riducono il suo raggio
- Può essere rigenerata colpendola con proiettili o rimbalzandoci sopra
- Effetto pulsante per maggiore visibilità

#### 🛸 Astronave
- Forma triangolare inscritta in barriera circolare
- **Salute infinita** - il giocatore non può morire
- Controllo intuitivo tramite touch
- Spara proiettili automaticamente tenendo premuto

#### 🌑 Asteroidi
- **3 taglie**: Grandi (40px), Medi (25px), Piccoli (15px)
- Si frammentano quando colpiti (2-3 frammenti per asteroide)
- Gli asteroidi grandi generano attrazione gravitazionale locale
- Movimento orbitale ellittico discendente

### Meccaniche di Gioco

#### Sistema di Onde
- Onde progressive con difficoltà crescente
- Ogni onda aumenta numero, velocità e resistenza degli asteroidi
- Messaggio "WAVE X" ad ogni nuova ondata
- Sblocco di nuovi scenari con tavolozze di colori diverse

#### Collisioni
- **Asteroide vs Proiettile**: Frammentazione
- **Asteroide vs Pianeta**: Danno se atmosfera debole
- **Asteroide vs Atmosfera**: Rimbalzo e riduzione atmosfera
- **Asteroide vs Asteroide**: Deflessione e possibile frammentazione

#### Punteggio
- Asteroidi grandi: 20 punti
- Asteroidi medi: 15 punti
- Asteroidi piccoli: 10 punti
- Rimbalzi atmosfera: +5 punti bonus

### Mondo di Gioco

#### Spazio Toroidale
- Gli oggetti che escono da un lato ricompaiono dall'altro
- Mantiene direzione e velocità durante il wrapping
- Crea sensazione di continuità spaziale

#### Camera Dinamica
- Segue il giocatore con smoothing
- **Zoom progressivo** fino a 3x quando ci si allontana dal pianeta
- Preserva sempre la visibilità del pianeta centrale

### Estetica

#### Grafica Vettoriale Retrò
- Stile monocromatico minimalista
- Atmosfera azzurra luminosa
- Pianeta bianco centrale
- Asteroidi e astronave in stile wireframe

#### Effetti Visivi
- Esplosioni con particelle
- Flash di impatto sull'atmosfera
- Pulsazione atmosfera
- Glow effects

## 🎯 Obiettivi

1. **Sopravvivere** proteggendo il pianeta
2. **Distruggere asteroidi** per accumulare punti
3. **Gestire l'atmosfera** bilanciando difesa e rigenerazione
4. **Progredire** attraverso onde sempre più difficili

## 🕹️ Controlli

- **Touch e Hold**: Muovi la nave verso il punto toccato
- **Touch prolungato**: Spara automaticamente
- La nave si orienta automaticamente verso la direzione di movimento

## 📱 Supporto Piattaforme

- iPhone (orientamento landscape consigliato)
- iPad
- iOS 13.0+

## 🔧 Tecnologie

- **SpriteKit** per rendering e fisica
- **Swift** per la logica di gioco
- **Physics Engine** personalizzato per gravità orbitale

## 🎨 Design Philosophy

*"Ogni colpo, rimbalzo e frammentazione contribuisce a un sistema coerente e dinamico, in cui l'obiettivo non è solo distruggere, ma mantenere l'equilibrio di un piccolo mondo in balia del caos cosmico."*

## 📝 Note di Sviluppo

- Il gioco è ottimizzato per gameplay orizzontale
- Debug FPS e Node Count visibili in modalità sviluppo
- Fisica personalizzata per gravità centrale e locale
- Sistema di collisioni ottimizzato per performance

## 🚀 Come Eseguire

1. Apri `Orbitica Core.xcodeproj` in Xcode
2. Seleziona un simulatore iPhone o iPad
3. Build e Run (⌘R)
4. Divertiti a difendere il pianeta! 🌍

---

**Developed by Alessandro Grassi** | Novembre 2025
