//
//  Goodnight_JournalApp.swift
//  Goodnight Journal
//
//  Created by Hiroo Aoyama on 1/13/26.
//

import SwiftUI
import SwiftData
import FirebaseCore

// AppDelegate class to properly handle Firebase configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        return true
    }
}

@main
struct Goodnight_JournalApp: App {
    // Connect AppDelegate to SwiftUI App
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager.shared
    @Namespace private var authTransition
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isLoading {
                    LoadingView()
                        .transition(.opacity)
                } else if authManager.isAuthenticated {
                    ContentView(namespace: authTransition)
                        .transition(.opacity)
                } else {
                    AuthenticationView(namespace: authTransition)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: authManager.isAuthenticated)
            .animation(.easeInOut(duration: 0.6), value: authManager.isLoading)
        }
        .modelContainer(for: JournalEntry.self)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
        }
    }
}
