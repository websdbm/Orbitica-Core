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
        
        if let view = self.view as! SKView? {
            // Crea la scena di gioco
            let scene = GameScene(size: view.bounds.size)
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
        // Landscape per esperienza ottimale
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
