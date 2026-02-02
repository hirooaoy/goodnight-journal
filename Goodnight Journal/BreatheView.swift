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
    
    // MARK: - Configuration
    private enum Config {
        static let totalCycles = 4
        static let initialDelay = 0.5
        static let textFadeInDuration = 1.5
        static let textFadeDelay = 0.5
        static let inhaleNormal = 5.0
        static let exhaleNormal = 6.0
        static let inhaleLastCycle = 6.0
        static let exhaleLastCycle = 7.0
        static let encouragementFadeDuration = 0.6
        static let completionDelay = 2.0
        static let completionFadeOut = 0.5
    }
    
    private enum BreathPhase {
        case initial
        case inhale
        case exhale
        case complete
    }
    
    // MARK: - State
    @State private var currentPhase: BreathPhase = .initial
    @State private var currentCycle: Int = 0
    @State private var circleScale: CGFloat = 1.0
    @State private var circleOpacity: Double = 0.6
    @State private var phaseText: String = "Breathe in"
    @State private var encouragementText: String = ""
    @State private var showEncouragement: Bool = false
    @State private var showText: Bool = false
    @State private var sessionTimer: Timer?
    @State private var viewID: UUID = UUID()
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation buttons
                HStack {
                    Button(action: handleBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(20)
                    }
                    
                    Spacer()
                    
                    Button(action: handleSkip) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(20)
                    }
                }
                
                Spacer()
                
                // Breathing circle with matched geometry
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .scaleEffect(circleScale)
                    .opacity(circleOpacity)
                    .matchedGeometryEffect(id: "breatheCircle", in: namespace)
                
                // Phase text
                VStack(spacing: 8) {
                    Text(phaseText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(encouragementText)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(showEncouragement ? 1 : 0)
                        .frame(height: 20)
                }
                .padding(.top, 100)
                .opacity(showText ? 1 : 0)
                
                Spacer()
            }
        }
        .id(viewID)
        .onAppear(perform: startSession)
        .onDisappear(perform: endSession)
    }
    
    // MARK: - Session Management
    private func startSession() {
        resetState()
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Initial delay
        scheduleNextPhase(after: Config.initialDelay) {
            withAnimation(.easeInOut(duration: Config.textFadeInDuration)) {
                showText = true
            }
            scheduleNextPhase(after: Config.textFadeDelay) {
                startInhale()
            }
        }
    }
    
    private func endSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func handleBack() {
        sessionTimer?.invalidate()
        withAnimation(.easeInOut(duration: 0.5)) {
            onBack()
        }
    }
    
    private func handleSkip() {
        sessionTimer?.invalidate()
        onSkip()
    }
    
    // MARK: - Breathing Cycles
    private func startInhale() {
        guard currentCycle < Config.totalCycles else {
            completeSession()
            return
        }
        
        currentPhase = .inhale
        phaseText = "Breathe in"
        
        // Update encouragement text
        updateEncouragementForInhale()
        
        // Animate circle
        let duration = isLastCycle ? Config.inhaleLastCycle : Config.inhaleNormal
        withAnimation(.easeInOut(duration: duration)) {
            circleScale = 6.0
            circleOpacity = 1.0
        }
        
        // Schedule exhale
        scheduleNextPhase(after: duration) {
            startExhale()
        }
    }
    
    private func startExhale() {
        currentPhase = .exhale
        phaseText = "Breathe out"
        
        // Update encouragement text
        updateEncouragementForExhale()
        
        // Animate circle
        let duration = isLastCycle ? Config.exhaleLastCycle : Config.exhaleNormal
        withAnimation(.easeInOut(duration: duration)) {
            circleScale = 1.0
            circleOpacity = 0.6
        }
        
        // Schedule next cycle
        scheduleNextPhase(after: duration) {
            currentCycle += 1
            startInhale()
        }
    }
    
    private func completeSession() {
        currentPhase = .complete
        phaseText = "Well done"
        
        scheduleNextPhase(after: Config.completionDelay) {
            withAnimation(.easeInOut(duration: Config.completionFadeOut)) {
                showText = false
            }
            scheduleNextPhase(after: Config.completionFadeOut) {
                onComplete()
            }
        }
    }
    
    // MARK: - Helpers
    private var isLastCycle: Bool {
        currentCycle == Config.totalCycles - 1
    }
    
    private func updateEncouragementForInhale() {
        switch currentCycle {
        case 1:
            encouragementText = "3 more to go"
            withAnimation(.easeInOut(duration: Config.encouragementFadeDuration)) {
                showEncouragement = true
            }
        case 3:
            encouragementText = "Last big one"
            withAnimation(.easeInOut(duration: Config.encouragementFadeDuration)) {
                showEncouragement = true
            }
        default:
            break
        }
    }
    
    private func updateEncouragementForExhale() {
        switch currentCycle {
        case 1:
            encouragementText = "You're doing great"
        case 2, 3:
            withAnimation(.easeInOut(duration: Config.encouragementFadeDuration)) {
                showEncouragement = false
            }
        default:
            break
        }
    }
    
    private func scheduleNextPhase(after delay: TimeInterval, action: @escaping () -> Void) {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            action()
        }
    }
    
    private func resetState() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        currentPhase = .initial
        currentCycle = 0
        circleScale = 1.0
        circleOpacity = 0.6
        phaseText = "Breathe in"
        encouragementText = ""
        showEncouragement = false
        showText = false
        viewID = UUID()
    }
}

#Preview {
    @Previewable @Namespace var namespace
    BreatheView(namespace: namespace, onComplete: {}, onBack: {}, onSkip: {})
}
