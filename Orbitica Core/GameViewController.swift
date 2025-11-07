//
//  GameViewController.swift
//  Orbitica Core
//
//  Created by Alessandro Grassi on 07/11/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // DEBUG: Stampa tutti i font disponibili
        print("=== AVAILABLE FONTS ===")
        for family in UIFont.familyNames.sorted() {
            let fonts = UIFont.fontNames(forFamilyName: family)
            if !fonts.isEmpty {
                print("Family: \(family)")
                for name in fonts {
                    print("  - \(name)")
                }
            }
        }
        print("======================")
        
        if let view = self.view as! SKView? {
            // Forza dimensioni LANDSCAPE (inverti se necessario)
            let viewSize = view.bounds.size
            let sceneSize: CGSize
            if viewSize.width < viewSize.height {
                // Se la view è portrait, scambia le dimensioni per landscape
                sceneSize = CGSize(width: viewSize.height, height: viewSize.width)
            } else {
                sceneSize = viewSize
            }
            
            // Mostra prima il MainMenu invece di GameScene
            let scene = MainMenuScene(size: sceneSize)
            scene.scaleMode = .aspectFill
            
            // Present the scene
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            
            // Mostra statistiche di debug
            view.showsFPS = true
            view.showsNodeCount = true
            view.showsPhysics = false
            
            // IMPORTANTE: consente multi-touch per joystick + fire simultanei
            view.isMultipleTouchEnabled = true
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // FORZA landscape per il gioco
        return .landscape
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
