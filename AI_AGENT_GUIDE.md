# AI Agent Technical Guide - Orbitica Core

> **🎯 Purpose**: Knowledge transfer document for AI agents across different sessions/computers.  
> **📖 When to read**: User says "Check AI_AGENT_GUIDE.md" at start of session.  
> **✏️ When to update**: After fixing bugs, adding features, or discovering patterns.  
> **📏 Format rules**: Keep compact (save tokens), update Recent Changes, mark TODOs done.

## 📝 How to Update This Document

**Always update when:**
- Fixing a bug → Add to "Common Mistakes" table
- Discovering a pattern → Add to "Critical Patterns" 
- Making architectural changes → Update "File Structure" or "Key Functions"
- Completing work → Check off TODOs, add to "Recent Changes"

**Format rules:**
- Use tables for comparisons (saves tokens vs paragraphs)
- Code snippets: inline or minimal blocks only
- One-liners preferred over explanations
- Keep "Recent Changes" to last 5 entries max
- Update version date at bottom

**Style:**
- Emoji section headers for quick visual scanning
- ✅/❌ for right/wrong patterns
- [ ] checkboxes for TODOs
- Keep it DRY - don't repeat info

---

## 🎯 Project State

**Type**: Swift/SpriteKit iOS game  
**Name**: "Orbitica Core - GRAVITY SHIELD"  
**Status**: Physics & camera fixed, enhanced visuals active  
**Main File**: GameScene.swift (8300+ lines)

---

## ⚠️ CRITICAL PATTERNS (Read First!)

### 1. Initialization Timing
```swift
private var isInitialized: Bool = false
// update() is called BEFORE didMove(to:) completes!
// ALWAYS guard isInitialized at start of update()
```

### 2. Implicitly Unwrapped Optionals
```swift
private var planet: SKShapeNode!  // Can be nil at startup
// ❌ WRONG: guard planet != nil
// ✅ RIGHT: guard let planet = planet
```

### 3. Enhanced Visuals Mode (ACTIVE)
```swift
useEnhancedVisuals = true
// Planet exists in TWO nodes:
// - enhancedPlanet: EnhancedPlanetNode (visible, has physicsBody)
// - planet: SKShapeNode (invisible, alpha=0, used for calculations)
// Both MUST exist! Gravity/distance use planet.position
```

### 4. Physics Collisions
```swift
// Player setup (correct):
player.physicsBody?.collisionBitMask = 0  // NO auto-collisions!
player.physicsBody?.contactTestBitMask = atmosphere | asteroid | planet
// Bounce = MANUAL in handleAtmosphereBounce()

// Projectile setup (correct):
projectile.physicsBody?.collisionBitMask = 0
projectile.physicsBody?.restitution = 0  // Prevents recoil
projectile.physicsBody?.friction = 0
```

---

## 🚫 Common Mistakes & Fixes

| Problem | Cause | Solution |
|---------|-------|----------|
| Camera not working | planet = nil | Create invisible planet reference in setupPlanet() |
| Player passes through planet | collisionBitMask set | Must be 0, use manual bounce |
| Nil crash | Accessing before init | guard let binding, check isInitialized |
| Update crashes | Called before didMove done | guard isInitialized first line |
| Recoil on shooting | Physics interaction | restitution=0, friction=0, offset=30 |

---

## 📋 Active TODOs

### High Priority
- [ ] Test camera zoom behavior at distances
- [ ] Verify atmosphere bounce consistency across speeds
- [ ] Test all power-up types after physics changes

### Medium Priority
- [ ] Performance optimization: particle systems
- [ ] Add asteroid type variety
- [ ] Improve replay system timing

### Low Priority
- [ ] Visual polish on enhanced planet
- [ ] Sound effect variations

---

## 🔑 Key Functions Reference

### Guards Pattern
```swift
func update(_ currentTime: TimeInterval) {
    guard isInitialized else { return }  // ALWAYS first
    // ...
}

private func updateCameraZoom() {
    guard let player = player, let planet = planet else { return }
    guard gameCamera != nil else { return }
    // ...
}
```

### Collision Handlers
```swift
// Bounce for player/projectiles
handleAtmosphereBounce(contact: SKPhysicsContact, isPlayer: Bool)

// Bounce for asteroids (different signature!)
handlePlanetBounce(contact: SKPhysicsContact, asteroid: SKShapeNode)

// Damage
damageAsteroid(_ asteroid: SKShapeNode)
damageAtmosphere(amount: CGFloat)
// Planet: planetHealth -= 1; updatePlanetHealthLabel()
```

### Power-ups
```swift
activatePowerup(type: String, currentTime: TimeInterval)
// Types: V=vulcan, B=bigAmmo, A=atmosphere, G=gravity, M=missile, W=wave
```

---

## 📦 File Structure

```
Orbitica Core/
├── GameScene.swift          # Main (8300+ lines)
├── PlanetVisuals.swift      # Enhanced rendering + earth.jpg
├── PlayerController.swift   # Input & AI control
├── AIEngine.swift           # AI decision system
├── DroneNode.swift          # Drone entities (NEW)
├── RegiaScene.swift         # Recording mode
├── ReplayManager.swift      # Replay system
└── Immagini/earth.jpg       # 256×176px (scrolls horizontal)
```

---

## 🔄 Development History (Chronological)

> Keep last 10 entries. Format: **YYYY-MM-DD: Brief title** → Changes list

**2025-11-12b**: Drone Movement System Overhaul
- Rewrote DroneNode to use AIController (same as player)
- Removed fixed orbital path - now uses elegant AI maneuvers
- Drone physics matches player: mass=0.5, damping=0.3, inerzia realistica
- Movement: figure-8, spiral, zigzag patterns + ramming asteroids
- **Asset loading fixed**: Converted drone.svg → drone.png, use SKTexture(imageNamed:)
- Rotation: slow constant rotation (3s per revolution) on sprite child
- **Bug fixed**: Removed safety repositioning causing teleport jumps
- **Bug fixed**: DeltaTime now calculated correctly with instance var
- NO shooting capability, pure ramming defense
- **Lesson**: iOS doesn't support SVG - always convert to PNG for SpriteKit

**2025-11-12**: Physics & Camera System Fixed
- Added invisible planet reference node for enhanced visuals compatibility
- Fixed player penetration: collisionBitMask=0, manual bounce via handleAtmosphereBounce()
- Camera tracking implemented with lerp interpolation (speed=0.1)
- Removed projectile recoil: restitution=0, friction=0, spawn offset=30
- Added guard protections in updateCameraZoom() for nil access
- **Lesson**: collisionBitMask must be 0 for manual physics control

**2025-11-11**: Enhanced Planet Visuals
- Implemented earth.jpg texture (256×176px) with horizontal scrolling animation
- Created EnhancedPlanetNode system with realistic rendering
- Fixed missing particle textures: 4×4 white circle programmatic fallback
- Discovered: planet rotation should be texture scroll, not geometric rotation
- **Lesson**: When useEnhancedVisuals=true, need both enhancedPlanet and planet nodes

**2025-11-07**: Initial Compilation & Runtime Fixes
- Fixed updateEnergy/updateHealth parameter labels (current:, max:)
- Resolved multiple nil crashes with isInitialized flag pattern
- Discovered: update() called BEFORE didMove(to:) completes
- Implemented three-layer safety: isInitialized + function guards + async guards
- **Lesson**: Implicitly unwrapped optionals need `guard let`, not `guard != nil`

**Earlier**: Project Setup
- Base game mechanics: gravity, orbital rings, atmosphere system
- AI engine modular architecture
- Wave system with multiple asteroid types
- Power-up system (V/B/A/G/M/W types)

---

## 💡 Performance Notes

- Max small debris: 25 (limit for performance)
- Physics iterations: reduced to 5 from default 10
- Target FPS: 60
- Particle systems: Use cached textures
- Background: Discrete parallax layers in worldLayer

## 📁 Asset Loading Rules

**CRITICAL**: Asset paths in Xcode/iOS projects:
```swift
// ❌ WRONG - Don't include folder names or use Bundle paths for images
UIImage(named: "Immagini/earth.jpg")
Bundle.main.path(forResource: "earth", ofType: "jpg")

// ✅ RIGHT - Use SKTexture(imageNamed:) for game assets
let texture = SKTexture(imageNamed: "earth.jpg")
let texture = SKTexture(imageNamed: "drone.png")

// ✅ RIGHT - For audio, use Bundle.main.url
Bundle.main.url(forResource: "sparo1", withExtension: "m4a")
```

**Why**: 
- Xcode flattens resource folders during build
- SKTexture handles caching and GPU upload automatically
- **iOS doesn't support SVG** - convert to PNG first
- All image assets go directly into app bundle root

**Applies to**: Images (SKTexture), audio (Bundle.main.url), any resource file.

---

---

## 🎮 Game Constants

**Gravity**: 100 (gravitationalConstant)  
**Camera Zoom**: 1.0 / 1.6 / 2.5 (close/medium/far)  
**Atmosphere**: Radius 96→144, recharges from shots  
**Orbital Rings**: 200 / 300 / 430 px, spiral descent active  
**Player Mass**: 0.5, **Projectile Mass**: 0.01  

---

## 🧪 Testing Checklist

When making changes:
- [ ] Build succeeds (no compile errors)
- [ ] Run game, press "Play Now"
- [ ] Camera follows player
- [ ] Player bounces on atmosphere/planet
- [ ] Shooting works, no recoil
- [ ] Asteroids spawn and collide correctly
- [ ] Power-ups collectible
- [ ] Check console for crashes/warnings

---

## 📝 Code Style Notes

- Use `debugLog()` for conditional prints (respects debugMode flag)
- Physics categories: Use PhysicsCategory struct constants
- Guard early, return early pattern preferred
- Comment complex physics calculations
- Node names: Use descriptive strings ("enhancedPlanet", "playerReference")

---

*Version: 2025-11-12*  
*Optimized for AI agent context efficiency*
