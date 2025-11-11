//
//  ReplayManager.swift
//  Orbitica Core
//
//  Sistema di registrazione video usando ReplayKit
//

import Foundation
import ReplayKit
import UIKit

class ReplayManager: NSObject {
    static let shared = ReplayManager()
    
    private let recorder = RPScreenRecorder.shared()
    private var isRecording = false
    
    var onRecordingStatusChanged: ((Bool) -> Void)?
    
    private override init() {}
    
    // MARK: - Recording Control
    
    func startRecording(completion: @escaping (Error?) -> Void) {
        guard recorder.isAvailable else {
            let error = NSError(domain: "ReplayKit", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Screen recording not available on this device"])
            completion(error)
            return
        }
        
        guard !recorder.isRecording else {
            print("⚠️ Already recording")
            completion(nil)
            return
        }
        
        // Disabilita microfono per registrare solo audio di gioco
        recorder.isMicrophoneEnabled = false
        recorder.isCameraEnabled = false
        
        print("🎥 Starting screen recording...")
        
        recorder.startRecording { [weak self] error in
            if let error = error {
                print("❌ Recording start error: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            self?.isRecording = true
            self?.onRecordingStatusChanged?(true)
            print("✅ Recording started successfully")
            completion(nil)
        }
    }
    
    func stopRecording(completion: @escaping (URL?, Error?) -> Void) {
        guard recorder.isRecording else {
            print("⚠️ Not currently recording")
            completion(nil, nil)
            return
        }
        
        print("🛑 Stopping screen recording...")
        
        recorder.stopRecording { [weak self] previewController, error in
            self?.isRecording = false
            self?.onRecordingStatusChanged?(false)
            
            if let error = error {
                print("❌ Recording stop error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            // Mostra il preview per salvare il video - VERSIONE COMPATTA
            if let previewController = previewController {
                previewController.previewControllerDelegate = self
                
                // Trova il view controller corrente per mostrare il preview
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    
                    // Trova il view controller top-most
                    var topVC = rootVC
                    while let presentedVC = topVC.presentedViewController {
                        topVC = presentedVC
                    }
                    
                    // SOLUZIONE: Presenta il preview in un container custom con sfondo opaco
                    let containerVC = self?.createCustomPreviewContainer(with: previewController)
                    
                    if let containerVC = containerVC {
                        containerVC.modalPresentationStyle = .overFullScreen
                        containerVC.modalTransitionStyle = .crossDissolve
                        
                        print("✅ Showing CUSTOM CENTERED recording preview")
                        topVC.present(containerVC, animated: true) {
                            print("📹 Custom centered preview shown - user can save/share the video")
                        }
                    } else {
                        // Fallback: presenta normalmente
                        previewController.modalPresentationStyle = .pageSheet
                        topVC.present(previewController, animated: true)
                    }
                }
            }
            
            completion(nil, nil)
        }
    }
    
    func showPreview(from viewController: UIViewController) {
        // Questa funzione viene chiamata se vuoi mostrare il preview di ReplayKit
        // Per ora salviamo automaticamente
    }
    
    // MARK: - Status
    
    var isCurrentlyRecording: Bool {
        return recorder.isRecording
    }
    
    var isAvailable: Bool {
        return recorder.isAvailable
    }
    
    // MARK: - UI Helpers
    
    private func createCustomPreviewContainer(with previewController: RPPreviewViewController) -> UIViewController {
        let containerVC = UIViewController()
        
        // 1. SFONDO OPACO SCURO
        containerVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // 2. CALCOLA DIMENSIONI CONTENITORE (80% larghezza, 70% altezza max 600pt)
        let screenBounds = UIScreen.main.bounds
        let containerWidth = min(screenBounds.width * 0.85, 600)
        let containerHeight = min(screenBounds.height * 0.75, 700)
        
        let containerX = (screenBounds.width - containerWidth) / 2
        let containerY = (screenBounds.height - containerHeight) / 2
        
        // 3. CONTENITORE CARD con bordo
        let cardView = UIView(frame: CGRect(
            x: containerX,
            y: containerY,
            width: containerWidth,
            height: containerHeight
        ))
        cardView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        cardView.layer.cornerRadius = 20
        cardView.layer.borderWidth = 2
        cardView.layer.borderColor = UIColor.white.cgColor
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.5
        cardView.layer.shadowOffset = CGSize(width: 0, height: 10)
        cardView.layer.shadowRadius = 20
        containerVC.view.addSubview(cardView)
        
        // 4. LABEL HEADER "ANTEPRIMA VIDEO"
        let headerHeight: CGFloat = 55
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: headerHeight))
        headerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        
        let titleLabel = UILabel(frame: CGRect(x: 15, y: 0, width: containerWidth - 30, height: headerHeight))
        titleLabel.text = "📹 ANTEPRIMA VIDEO REGISTRATO"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        
        cardView.addSubview(headerView)
        
        // 5. AGGIUNGI IL PREVIEW CONTROLLER come child
        containerVC.addChild(previewController)
        
        let previewFrame = CGRect(
            x: 0,
            y: headerHeight,
            width: containerWidth,
            height: containerHeight - headerHeight
        )
        previewController.view.frame = previewFrame
        previewController.view.layer.cornerRadius = 15
        previewController.view.layer.masksToBounds = true
        
        cardView.addSubview(previewController.view)
        previewController.didMove(toParent: containerVC)
        
        // 6. TAP FUORI PER CHIUDERE (opzionale)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPreviewContainer))
        containerVC.view.addGestureRecognizer(tapGesture)
        
        print("🎨 Custom preview container created: \(Int(containerWidth))x\(Int(containerHeight))pt, centered with dimming")
        
        return containerVC
    }
    
    @objc private func dismissPreviewContainer() {
        // Chiudi solo se si tappa FUORI dal container
        // (Il gesture dovrebbe essere configurato per non interferire con i controlli interni)
        print("ℹ️ Tap outside detected, but preview controller handles its own dismissal")
    }
}

// MARK: - RPPreviewViewControllerDelegate

extension ReplayManager: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true, completion: nil)
    }
    
    func previewController(_ previewController: RPPreviewViewController,
                          didFinishWithActivityTypes activityTypes: Set<String>) {
        print("📹 Video saved with activities: \(activityTypes)")
        previewController.dismiss(animated: true, completion: nil)
    }
}
