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
    
    static let shared = FirestoreSyncManager()
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                Task { @MainActor in
                    await self?.syncAll()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - Sync Operations
    
    func syncAll() async {
        guard AuthenticationManager.shared.user?.uid != nil else { return }
        
        await MainActor.run {
            isSyncing = true
            syncError = nil
        }
        
        // This will be implemented with ModelContext
        // For now, just mark sync as complete
        await MainActor.run {
            lastSyncDate = Date()
            isSyncing = false
        }
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
