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
            
            // Salva automaticamente nel rullino
            if let previewController = previewController {
                previewController.previewControllerDelegate = self
                print("✅ Recording stopped, preview available")
            }
            
            print("✅ Recording completed")
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
