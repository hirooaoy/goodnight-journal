//
//  ContentView.swift
//  Goodnight Journal
//
//  Created by Hiroo Aoyama on 1/13/26.
//

import SwiftUI

struct ContentView: View {
    @State private var showBreatheView: Bool = false
    @State private var showJournalView: Bool = false
    @State private var showSignOutConfirmation: Bool = false
    @Namespace private var circleAnimation
    @StateObject private var authManager = AuthenticationManager.shared
    let namespace: Namespace.ID
    
    var body: some View {
        ZStack {
            if showJournalView {
                // Journal View
                JournalView(onBack: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showJournalView = false
                    }
                })
            } else if !showBreatheView {
                // Home View
                HomeView(
                    namespace: circleAnimation,
                    onStart: {
                        showBreatheView = true
                    },
                    onLogout: {
                        showSignOutConfirmation = true
                    }
                )
                .transition(.opacity)
            } else {
                // Breathe View
                BreatheView(
                    namespace: circleAnimation,
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showBreatheView = false
                            showJournalView = true
                        }
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showBreatheView = false
                        }
                    },
                    onSkip: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showBreatheView = false
                            showJournalView = true
                        }
                    }
                )
            }
        }
        .confirmationDialog(
            "Are you sure you want to sign out?",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                do {
                    try authManager.signOut()
                } catch {
                    print("Error signing out: \(error)")
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    ContentView(namespace: namespace)
}
