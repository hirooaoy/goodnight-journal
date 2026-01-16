//
//  JournalView.swift
//  Goodnight Journal
//
//  Created by Hiroo Aoyama on 1/13/26.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct JournalView: View {
    let onBack: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var journalText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    @State private var showContent: Bool = false
    @State private var currentEntry: JournalEntry?
    @State private var isSaving: Bool = false
    @State private var showSaveConfirmation: Bool = false
    @State private var generatedLetters: [String] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with back button and checkmark
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
                        Task {
                            await saveEntry()
                        }
                    }) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                                .padding(20)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(20)
                        }
                    }
                    .disabled(isSaving)
                }
                
                // Journal text editor
                TextEditor(text: $journalText)
                    .font(.title3)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 20)
                    .focused($isTextEditorFocused)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(showContent ? 1 : 0)
                    .onChange(of: journalText) { oldValue, newValue in
                        handleTextChange(oldValue: oldValue, newValue: newValue)
                    }
            }
        }
        .onAppear {
            Task {
                await loadOrCreateEntry()
            }
        }
        .alert("Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {
                onBack()
            }
        } message: {
            Text("Your journal entry has been saved and synced.")
        }
    }
    
    private func handleTextChange(oldValue: String, newValue: String) {
        // Auto-convert "- " to "• "
        if newValue.hasSuffix("- ") && !oldValue.hasSuffix("- ") {
            let trimmed = String(newValue.dropLast(2))
            journalText = trimmed + "• "
            return
        }
        
        // Check if user pressed return (newline added at the end)
        guard newValue.count == oldValue.count + 1 else { return }
        guard newValue.last == "\n" else { return }
        
        let lines = newValue.components(separatedBy: "\n")
        guard lines.count > 1 else { return }
        
        // Get the previous line (second to last)
        let previousLineIndex = lines.count - 2
        guard previousLineIndex >= 0 else { return }
        
        let previousLine = lines[previousLineIndex]
        let trimmedPrevious = previousLine.trimmingCharacters(in: .whitespaces)
        
        // Check if previous line is just an empty bullet "• "
        if trimmedPrevious == "•" {
            // Remove the empty bullet from previous line
            var allLines = lines
            allLines[previousLineIndex] = ""
            journalText = allLines.joined(separator: "\n")
            return
        }
        
        // Check if previous line is just an empty number "1. " or "2. " etc
        if trimmedPrevious.firstMatch(of: /^(\d+)\.$/) != nil {
            // It's just a number with dot, no text after
            var allLines = lines
            allLines[previousLineIndex] = ""
            journalText = allLines.joined(separator: "\n")
            return
        }
        
        // Check if previous line starts with bullet (and has text)
        if trimmedPrevious.hasPrefix("• ") {
            journalText += "• "
        }
        // Check if previous line starts with number (and has text)
        else if let match = trimmedPrevious.firstMatch(of: /^(\d+)\./) {
            let numberStr = match.1
            if let number = Int(numberStr) {
                journalText += "\(number + 1). "
            }
        }
    }
    
    // MARK: - Data Management
    
    private func loadOrCreateEntry() async {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // Try to load existing entry from local storage
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date >= today && entry.date < tomorrow
            }
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            if let existingEntry = entries.first {
                // Load existing entry
                currentEntry = existingEntry
                journalText = reconstructJournalText(from: existingEntry)
                generatedLetters = existingEntry.letters
            } else {
                // Create new entry
                createNewEntry()
            }
            
            // Slow fade-in animation
            withAnimation(.easeInOut(duration: 1.5)) {
                showContent = true
            }
        } catch {
            print("Error loading entry: \(error)")
            createNewEntry()
            withAnimation(.easeInOut(duration: 1.5)) {
                showContent = true
            }
        }
    }
    
    private func createNewEntry() {
        // Generate pre-filled content with random letters (excluding J, Q, U, V, X, Y, Z)
        let availableLetters = "ABCDEFGHIKLMNOPRSTW"
        let letter1 = String(availableLetters.randomElement()!)
        let letter2 = String(availableLetters.randomElement()!)
        let letter3 = String(availableLetters.randomElement()!)
        
        generatedLetters = [letter1, letter2, letter3]
        
        // Structure: Today's poem, one empty line, X Y Z, two empty lines, Today's journal, one empty line
        journalText = "Today's poem\n\n\(letter1)\n\(letter2)\n\(letter3)\n\n\nToday's journal\n\n"
    }
    
    private func reconstructJournalText(from entry: JournalEntry) -> String {
        let letters = entry.letters.joined(separator: "\n")
        return "Today's poem\n\n\(letters)\n\n\nToday's journal\n\n\(entry.journalContent)"
    }
    
    private func saveEntry() async {
        isSaving = true
        
        // Parse the journal text
        let (poemContent, journalContent) = parseJournalText()
        
        guard let userId = AuthenticationManager.shared.user?.uid else {
            isSaving = false
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existing = currentEntry {
            // Update existing entry
            existing.poemContent = poemContent
            existing.journalContent = journalContent
            existing.lastModified = Date()
            existing.letters = generatedLetters
        } else {
            // Create new entry
            let newEntry = JournalEntry(
                date: today,
                poemContent: poemContent,
                letters: generatedLetters,
                journalContent: journalContent,
                userId: userId
            )
            modelContext.insert(newEntry)
            currentEntry = newEntry
        }
        
        // Save to local storage
        do {
            try modelContext.save()
            
            // Sync to Firestore
            if let entryToSync = currentEntry {
                try await FirestoreSyncManager.shared.saveEntry(entryToSync)
            }
            
            isSaving = false
            showSaveConfirmation = true
        } catch {
            print("Error saving entry: \(error)")
            isSaving = false
        }
    }
    
    private func parseJournalText() -> (poem: String, journal: String) {
        let sections = journalText.components(separatedBy: "Today's journal")
        
        if sections.count > 1 {
            let poemSection = sections[0]
                .replacingOccurrences(of: "Today's poem", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let journalSection = sections[1]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return (poemSection, journalSection)
        }
        
        return ("", journalText)
    }
}

#Preview {
    JournalView(onBack: {})
}
