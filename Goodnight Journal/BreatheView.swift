//
//  BreatheView.swift
//  Goodnight Journal
//
//  Created by Hiroo Aoyama on 1/13/26.
//

import SwiftUI

struct BreatheView: View {
    let namespace: Namespace.ID
    let onComplete: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void
    
    @State private var circleScale: CGFloat = 1.0
    @State private var circleOpacity: Double = 0.6
    @State private var phaseText: String = "Breathe in"
    @State private var phaseTextOpacity: Double = 1.0
    @State private var encouragementText: String = ""
    @State private var showEncouragement: Bool = false
    @State private var showText: Bool = false
    @State private var currentCycle: Int = 0
    private let totalCycles: Int = 4
    @StateObject private var soundManager = SoundManager.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Breathing circle with matched geometry
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .scaleEffect(circleScale)
                    .opacity(circleOpacity)
                    .matchedGeometryEffect(id: "breatheCircle", in: namespace)
                
                // Phase text - positioned lower to avoid overlap
                VStack(spacing: 8) {
                    Text(phaseText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .opacity(phaseTextOpacity)
                    
                    // Always reserve space for encouragement text
                    Text(encouragementText)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(showEncouragement ? 1 : 0)
                }
                .padding(.top, 100)
                .opacity(showText ? 1 : 0)
                .frame(minHeight: 44)
                
                Spacer()
            }
            
            // Back button - top left, Skip button - top right
            VStack {
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            onBack()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(20)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        onSkip()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(20)
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            // Keep screen awake during breathing session
            UIApplication.shared.isIdleTimerDisabled = true
            // Start the fireplace sound
            soundManager.startBreathingSound()
            startBreathingCycle()
        }
        .onDisappear {
            // Re-enable screen auto-lock when leaving
            UIApplication.shared.isIdleTimerDisabled = false
            // Stop the fireplace sound
            soundManager.stopBreathingSound()
        }
    }
    
    private func startBreathingCycle() {
        // Brief pause - circle sits alone for 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Fade in "Breathe in" text slowly
            withAnimation(.easeInOut(duration: 1.5)) {
                showText = true
            }
            
            // Start the breathing animation while text is still fading (0.5s after text starts)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                performBreathingCycles()
            }
        }
    }
    
    private func performBreathingCycles() {
        guard currentCycle < totalCycles else {
            // Breathing complete
            completeSession()
            return
        }
        
        // Determine if this is the last cycle
        let isLastCycle = (currentCycle == 3)
        let inhaleDuration: Double = isLastCycle ? 6.0 : 5.0
        let exhaleDuration: Double = isLastCycle ? 7.0 : 6.0
        
        // Fade out current text instantly
        withAnimation(.easeOut(duration: 0.2)) {
            phaseTextOpacity = 0.0
        }
        
        // Change text and fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            phaseText = "Breathe in"
            
            // Add encouragement on 2nd cycle (index 1) and last cycle (index 3)
            if currentCycle == 1 {
                encouragementText = "3 more to go"
                showEncouragement = true
            } else if currentCycle == 3 {
                encouragementText = "Last big one"
                showEncouragement = true
            } else {
                showEncouragement = false
            }
            
            withAnimation(.easeIn(duration: 0.2)) {
                phaseTextOpacity = 1.0
            }
        }
        
        withAnimation(.easeInOut(duration: inhaleDuration)) {
            circleScale = 6.0
            circleOpacity = 1.0
        }
        
        // Exhale phase
        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleDuration) {
            // Fade out current text
            withAnimation(.easeOut(duration: 0.2)) {
                phaseTextOpacity = 0.0
            }
            
            // Change text and fade in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                phaseText = "Breathe out"
                
                // Add encouragement on 2nd cycle
                if currentCycle == 1 {
                    encouragementText = "You're doing great"
                    showEncouragement = true
                } else {
                    showEncouragement = false
                }
                
                withAnimation(.easeIn(duration: 0.2)) {
                    phaseTextOpacity = 1.0
                }
            }
            
            withAnimation(.easeInOut(duration: exhaleDuration)) {
                circleScale = 1.0
                circleOpacity = 0.6
            }
            
            // Move to next cycle
            DispatchQueue.main.asyncAfter(deadline: .now() + exhaleDuration) {
                currentCycle += 1
                performBreathingCycles()
            }
        }
    }
    
    private func completeSession() {
        phaseText = "Well done"
        
        // Return to home after a brief pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showText = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    BreatheView(namespace: namespace, onComplete: {}, onBack: {}, onSkip: {})
}
