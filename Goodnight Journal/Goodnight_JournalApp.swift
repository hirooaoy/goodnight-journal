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
    
    // Configure ModelContainer with migration support
    let modelContainer: ModelContainer = {
        let schema = Schema([JournalEntry.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // If migration fails, try to delete the old store and create a new one
            print("⚠️ Migration failed: \(error)")
            print("Attempting to reset the data store...")
            
            // Get the store URL
            let storeURL = configuration.url
            try? FileManager.default.removeItem(at: storeURL)
            
            // Also try to remove any related files
            let storeURLString = storeURL.path
            let storeSHMURL = URL(fileURLWithPath: storeURLString + "-shm")
            let storeWALURL = URL(fileURLWithPath: storeURLString + "-wal")
            try? FileManager.default.removeItem(at: storeSHMURL)
            try? FileManager.default.removeItem(at: storeWALURL)
            
            // Try to create the container again
            do {
                return try ModelContainer(for: schema, configurations: configuration)
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isAuthenticated {
                    ContentView(namespace: authTransition)
                        .transition(.opacity)
                        .onAppear {
                            // Set up model context for sync manager
                            FirestoreSyncManager.shared.setModelContext(modelContainer.mainContext)
                            
                            // Pull submitted entries from cloud on app launch
                            Task {
                                await FirestoreSyncManager.shared.pullSubmittedEntries()
                            }
                        }
                } else {
                    AuthenticationView(namespace: authTransition)
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 1.8, dampingFraction: 0.85), value: authManager.isAuthenticated)
        }
        .modelContainer(modelContainer)
    }
}
