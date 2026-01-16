//
//  SoundManager.swift
//  Goodnight Journal
//
//  Created by Hiroo Aoyama on 1/15/26.
//

import AVFoundation
import SwiftUI
import Combine

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled")
        }
    }
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        // Load saved preference or default to true
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        setupAudioSession()
        setupAudioPlayer()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "fireplace-sound", withExtension: "mp3") else {
            print("Failed to find fireplace sound file")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 0.5 // Set to 50% volume
        } catch {
            print("Failed to initialize audio player: \(error)")
        }
    }
    
    func startBreathingSound() {
        guard isSoundEnabled, let player = audioPlayer else { return }
        
        if !player.isPlaying {
            player.currentTime = 0
            player.play()
        }
    }
    
    func stopBreathingSound() {
        audioPlayer?.stop()
    }
    
    func toggleSound() {
        isSoundEnabled.toggle()
    }
}
