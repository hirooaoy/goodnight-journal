//
//  JournalEntry.swift
//  Goodnight Journal
//
//  Created by Hiroo Aoyama on 1/15/26.
//

import Foundation
import SwiftData
import FirebaseFirestore

@Model
final class JournalEntry {
    @Attribute(.unique) var id: String
    var date: Date
    var poemContent: String
    var letters: [String]
    var journalContent: String
    var lastModified: Date
    var userId: String
    var isCompleted: Bool
    var needsSync: Bool
    
    init(id: String = UUID().uuidString,
         date: Date = Date(),
         poemContent: String = "",
         letters: [String] = [],
         journalContent: String = "",
         lastModified: Date = Date(),
         userId: String = "",
         isCompleted: Bool = false,
         needsSync: Bool = false) {
        self.id = id
        self.date = date
        self.poemContent = poemContent
        self.letters = letters
        self.journalContent = journalContent
        self.lastModified = lastModified
        self.userId = userId
        self.isCompleted = isCompleted
        self.needsSync = needsSync
    }
    
    // Helper to get date string for Firestore key (YYYY-MM-DD)
    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "date": Timestamp(date: date),
            "poemContent": poemContent,
            "letters": letters,
            "journalContent": journalContent,
            "lastModified": Timestamp(date: lastModified),
            "userId": userId,
            "isCompleted": isCompleted,
            "needsSync": needsSync
        ]
    }
    
    // Create from Firestore dictionary
    static func fromDictionary(_ dict: [String: Any]) -> JournalEntry? {
        guard let id = dict["id"] as? String,
              let dateTimestamp = dict["date"] as? Timestamp,
              let poemContent = dict["poemContent"] as? String,
              let letters = dict["letters"] as? [String],
              let journalContent = dict["journalContent"] as? String,
              let lastModifiedTimestamp = dict["lastModified"] as? Timestamp,
              let userId = dict["userId"] as? String else {
            return nil
        }
        
        let isCompleted = dict["isCompleted"] as? Bool ?? false
        let needsSync = dict["needsSync"] as? Bool ?? false
        
        return JournalEntry(
            id: id,
            date: dateTimestamp.dateValue(),
            poemContent: poemContent,
            letters: letters,
            journalContent: journalContent,
            lastModified: lastModifiedTimestamp.dateValue(),
            userId: userId,
            isCompleted: isCompleted,
            needsSync: needsSync
        )
    }
}
