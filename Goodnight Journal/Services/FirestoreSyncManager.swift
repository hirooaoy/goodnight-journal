//
//  FirestoreSyncManager.swift
//  Goodnight Journal
//
//  Created by Hiroo Aoyama on 1/15/26.
//

import Foundation
import Combine
import SwiftData
import FirebaseAuth
import FirebaseFirestore
import Network

@MainActor
class FirestoreSyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private let db = Firestore.firestore()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var modelContext: ModelContext?
    
    static let shared = FirestoreSyncManager()
    
    // Track last sync timestamp for incremental sync
    private var lastPullTimestamp: Date? {
        get {
            UserDefaults.standard.object(forKey: "lastPullTimestamp") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastPullTimestamp")
        }
    }
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // Set model context for syncing pending entries
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                Task { @MainActor in
                    await self?.syncPendingEntries()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - Sync Operations
    
    func syncPendingEntries() async {
        guard let modelContext = modelContext else { return }
        guard AuthenticationManager.shared.user?.uid != nil else { return }
        
        await MainActor.run {
            isSyncing = true
            syncError = nil
        }
        
        // Fetch all entries that need syncing, ordered by date (oldest first)
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.needsSync == true
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            let entriesToSync = try modelContext.fetch(descriptor)
            
            guard !entriesToSync.isEmpty else {
                await MainActor.run {
                    lastSyncDate = Date()
                    isSyncing = false
                }
                return
            }
            
            print("Syncing \(entriesToSync.count) pending entries...")
            
            // Sync each entry in order
            for entry in entriesToSync {
                do {
                    try await saveEntry(entry)
                    // Mark as synced
                    entry.needsSync = false
                    try modelContext.save()
                    print("Synced entry for \(entry.dateKey)")
                } catch {
                    print("Failed to sync entry \(entry.dateKey): \(error)")
                    // Keep needsSync = true, will retry later
                    // Continue with other entries
                }
            }
            
            await MainActor.run {
                lastSyncDate = Date()
                isSyncing = false
            }
        } catch {
            print("Error fetching pending entries: \(error)")
            await MainActor.run {
                isSyncing = false
            }
        }
    }
    
    func syncAll() async {
        // Alias for syncPendingEntries
        await syncPendingEntries()
    }
    
    // MARK: - Save Entry to Firestore
    
    func saveEntry(_ entry: JournalEntry) async throws {
        guard let userId = AuthenticationManager.shared.user?.uid else {
            throw SyncError.notAuthenticated
        }
        
        let docRef = db.collection("users")
            .document(userId)
            .collection("entries")
            .document(entry.dateKey)
        
        var entryDict = entry.toDictionary()
        entryDict["userId"] = userId
        
        try await docRef.setData(entryDict, merge: true)
    }
    
    // MARK: - Fetch Entry from Firestore
    
    func fetchEntry(for date: Date) async throws -> JournalEntry? {
        guard let userId = AuthenticationManager.shared.user?.uid else {
            throw SyncError.notAuthenticated
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)
        
        let docRef = db.collection("users")
            .document(userId)
            .collection("entries")
            .document(dateKey)
        
        let snapshot = try await docRef.getDocument()
        
        guard let data = snapshot.data() else {
            return nil
        }
        
        return JournalEntry.fromDictionary(data)
    }
    
    // MARK: - Fetch All Entries
    
    func fetchAllEntries() async throws -> [JournalEntry] {
        guard let userId = AuthenticationManager.shared.user?.uid else {
            throw SyncError.notAuthenticated
        }
        
        let querySnapshot = try await db.collection("users")
            .document(userId)
            .collection("entries")
            .order(by: "date", descending: true)
            .getDocuments()
        
        var entries: [JournalEntry] = []
        
        for document in querySnapshot.documents {
            if let entry = JournalEntry.fromDictionary(document.data()) {
                entries.append(entry)
            }
        }
        
        return entries
    }
    
    // MARK: - Pull Submitted Entries from Cloud
    
    func pullSubmittedEntries() async {
        guard let modelContext = modelContext else {
            print("ModelContext not set")
            return
        }
        guard AuthenticationManager.shared.user?.uid != nil else {
            print("User not authenticated")
            return
        }
        
        await MainActor.run {
            isSyncing = true
            syncError = nil
        }
        
        do {
            guard let userId = AuthenticationManager.shared.user?.uid else {
                throw SyncError.notAuthenticated
            }
            
            var query = db.collection("users")
                .document(userId)
                .collection("entries")
                .whereField("isCompleted", isEqualTo: true)
            
            // Incremental sync: only fetch entries modified since last sync
            if let lastPull = lastPullTimestamp {
                print("📥 Incremental sync: Fetching entries modified since \(lastPull)")
                query = query.whereField("lastModified", isGreaterThan: Timestamp(date: lastPull))
            } else {
                print("📥 First sync: Fetching all submitted entries")
            }
            
            let querySnapshot = try await query
                .order(by: "lastModified", descending: true)
                .getDocuments()
            
            var submittedEntries: [JournalEntry] = []
            
            for document in querySnapshot.documents {
                if let entry = JournalEntry.fromDictionary(document.data()) {
                    submittedEntries.append(entry)
                }
            }
            
            print("Found \(submittedEntries.count) submitted entries to sync")
            
            // Merge each cloud entry into local storage
            for cloudEntry in submittedEntries {
                // Check if entry already exists locally
                let startOfDay = Calendar.current.startOfDay(for: cloudEntry.date)
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let descriptor = FetchDescriptor<JournalEntry>(
                    predicate: #Predicate { entry in
                        entry.date >= startOfDay && entry.date < endOfDay
                    }
                )
                
                let localEntries = try modelContext.fetch(descriptor)
                
                if let localEntry = localEntries.first {
                    // Entry exists locally
                    // If local is NOT submitted, cloud wins (user submitted from another device)
                    if !localEntry.isCompleted {
                        print("Updating local draft with submitted entry from cloud: \(cloudEntry.dateKey)")
                        localEntry.poemContent = cloudEntry.poemContent
                        localEntry.letters = cloudEntry.letters
                        localEntry.journalContent = cloudEntry.journalContent
                        localEntry.lastModified = cloudEntry.lastModified
                        localEntry.isCompleted = true
                        localEntry.needsSync = false
                    } else {
                        // Both submitted - update if cloud is newer
                        if cloudEntry.lastModified > localEntry.lastModified {
                            print("Updating local with newer cloud version: \(cloudEntry.dateKey)")
                            localEntry.poemContent = cloudEntry.poemContent
                            localEntry.letters = cloudEntry.letters
                            localEntry.journalContent = cloudEntry.journalContent
                            localEntry.lastModified = cloudEntry.lastModified
                            localEntry.needsSync = false
                        }
                    }
                } else {
                    // New entry from cloud, add to local
                    print("Adding new entry from cloud: \(cloudEntry.dateKey)")
                    let newEntry = JournalEntry(
                        id: cloudEntry.id,
                        date: cloudEntry.date,
                        poemContent: cloudEntry.poemContent,
                        letters: cloudEntry.letters,
                        journalContent: cloudEntry.journalContent,
                        lastModified: cloudEntry.lastModified,
                        userId: cloudEntry.userId,
                        isCompleted: cloudEntry.isCompleted,
                        needsSync: false
                    )
                    modelContext.insert(newEntry)
                }
            }
            
            // Save all changes to local storage
            try modelContext.save()
            
            // Update last pull timestamp
            lastPullTimestamp = Date()
            
            await MainActor.run {
                lastSyncDate = Date()
                isSyncing = false
            }
            
            print("✅ Successfully synced \(submittedEntries.count) entries from cloud")
        } catch {
            print("❌ Error pulling submitted entries: \(error)")
            await MainActor.run {
                syncError = "Failed to sync from cloud"
                isSyncing = false
            }
        }
    }
    
    // MARK: - Delete Entry
    
    func deleteEntry(_ entry: JournalEntry) async throws {
        guard let userId = AuthenticationManager.shared.user?.uid else {
            throw SyncError.notAuthenticated
        }
        
        let docRef = db.collection("users")
            .document(userId)
            .collection("entries")
            .document(entry.dateKey)
        
        try await docRef.delete()
    }
    
    // MARK: - Check for Today's Entry
    
    func hasTodaysEntry() async throws -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let entry = try await fetchEntry(for: today)
        return entry != nil
    }
}

// MARK: - Sync Errors

enum SyncError: LocalizedError {
    case notAuthenticated
    case networkUnavailable
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .networkUnavailable:
            return "Network unavailable"
        case .invalidData:
            return "Invalid data format"
        }
    }
}
