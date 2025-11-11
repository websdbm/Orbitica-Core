# Sistema di Punteggio - Orbitica Core

## Punti Base per Dimensione

| Dimensione | Punti Base |
|------------|------------|
| **Large**  | 20         |
| **Medium** | 15         |
| **Small**  | 10         |

## Moltiplicatori per Tipo

| Tipo Asteroide | Colore | Vita | Moltiplicatore | Note |
|----------------|--------|------|----------------|------|
| **Normal** | Bianco | 1 | **1.0x** | Asteroide standard |
| **Fast** | Ciano | 1 | **1.3x** | Velocità 2.4x |
| **Armored** | Grigio | 2 | **1.5x** | Resistente, 2 colpi |
| **Explosive** | Rosso | 1 | **1.5x** | Esplode in molti frammenti |
| **Repulsor** | Viola | 2 | **2.0x** | Respinge il player |
| **Square** | Arancione | 2 | **2.0x** | Cambia direzione, 2x danno atmosfera |
| **Heavy** | Verde acido | 3 | **3.0x** | Molto resistente, 4x danno atmosfera |

## Esempi di Calcolo

### Heavy Large (Verde)
- Base: 20 punti
- Moltiplicatore: 3.0x
- **Totale: 60 punti**
- Richiede: 3 colpi per distruggere

### Heavy Medium (Verde)
- Base: 15 punti
- Moltiplicatore: 3.0x
- **Totale: 45 punti**
- Richiede: 3 colpi per distruggere

### Heavy Small (Verde)
- Base: 10 punti
- Moltiplicatore: 3.0x
- **Totale: 30 punti**
- Richiede: 3 colpi per distruggere

### Square Large (Arancione)
- Base: 20 punti
- Moltiplicatore: 2.0x
- **Totale: 40 punti**
- Richiede: 2 colpi per distruggere

### Armored Large (Grigio)
- Base: 20 punti
- Moltiplicatore: 1.5x
- **Totale: 30 punti**
- Richiede: 2 colpi per distruggere

### Fast Large (Ciano)
- Base: 20 punti
- Moltiplicatore: 1.3x
- **Totale: 26 punti**
- Richiede: 1 colpo per distruggere

### Normal Large (Bianco)
- Base: 20 punti
- Moltiplicatore: 1.0x
- **Totale: 20 punti**
- Richiede: 1 colpo per distruggere

## Modificatori Aggiuntivi

### Damage Multiplier
Il punteggio finale viene ulteriormente moltiplicato per il `damageMultiplier`:
- **Colpo normale**: 1.0x
- **BigAmmo power-up**: 4.0x (punti quadruplicati)
- **Wave Blast**: 2.0x (punti raddoppiati)

### Esempio con Power-up
**Heavy Large + BigAmmo:**
- Base: 20
- Type: 3.0x = 60
- BigAmmo: 4.0x
- **Totale: 240 punti!**

## Bilanciamento

Gli asteroidi più difficili da distruggere offrono punteggi proporzionalmente più alti:

- **Heavy (verde)**: 3 colpi → 3x punti ✅
- **Square/Repulsor**: 2 colpi → 2x punti ✅
- **Armored**: 2 colpi → 1.5x punti ✅
- **Fast**: 1 colpo ma difficile da colpire → 1.3x punti ✅

Gli asteroidi **Heavy** sono stati bilanciati:
- Vita ridotta da 4 a 3 colpi
- Punteggio aumentato da 1x a 3x
- Risultato: Più soddisfacente distruggerli!
