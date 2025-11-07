// Test rapido per verificare il font Zerovelo
// Esegui questo in un Playground o come test

import UIKit

// Stampa tutti i font
print("=== ALL FONTS ===")
for family in UIFont.familyNames.sorted() {
    print("Family: \(family)")
    for name in UIFont.fontNames(forFamilyName: family) {
        print("  - \(name)")
    }
}

// Test caricamento Zerovelo
print("\n=== ZEROVELO TEST ===")
let testNames = ["Zerovelo", "zerovelo", "Zerovelo-Regular", "ZeroVelo"]
for name in testNames {
    if let font = UIFont(name: name, size: 12) {
        print("✅ SUCCESS: '\(name)' loads correctly")
        print("   Font family: \(font.familyName)")
        print("   Font name: \(font.fontName)")
    } else {
        print("❌ FAILED: '\(name)' not found")
    }
}
