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
    let initialDate: Date
    let initialIsReadOnly: Bool
    @State private var isReadOnly: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var journalText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    @State private var showContent: Bool = false
    @State private var currentEntry: JournalEntry?
    @State private var isSaving: Bool = false
    @State private var showSaveConfirmation: Bool = false
    @State private var generatedLetters: [String] = []
    @State private var autoSaveTask: Task<Void, Never>?
    @State private var showDeleteConfirmation: Bool = false
    @State private var showSuccessSheet: Bool = false
    @State private var selectedTab: Tab = .journal
    @State private var aiNotesState: AINotesState = .initial
    @State private var aiInsights: String = ""
    @State private var creditsRemaining: Int = 5 // TODO: Implement actual credit system
    @State private var isGeneratingInsights: Bool = false
    @State private var aiContentOpacity: Double = 1.0
    @State private var showAIBanner: Bool = true
    @State private var hasAnimatedInsights: Bool = false
    @State private var visibleParagraphs: Set<Int> = []
    @State private var showPromptLibrary: Bool = false
    @State private var currentPromptIndex: Int = 0
    
    enum Tab {
        case journal
        case aiNotes
    }
    
    // Prompt library data
    struct Prompt {
        let title: String
        let description: String
        let template: String
    }
    
    let prompts: [Prompt] = [
        Prompt(
            title: "Poem Starter Kit",
            description: "Activate your writing by writing a poem from 3 random letters.",
            template: "Today's poem\n\n[LETTERS]\n\n\n\n"
        ),
        Prompt(
            title: "Gratitude Focus",
            description: "Write about three things you're grateful for today.",
            template: "Today's gratitude\n\n1. \n2. \n3. \n\n"
        ),
        Prompt(
            title: "Daily Reflection",
            description: "Reflect on what went well and what you learned.",
            template: "What went well today:\n\n\nWhat I learned:\n\n"
        ),
        Prompt(
            title: "Future Letter",
            description: "Write a letter to your future self.",
            template: "Dear future me,\n\n"
        ),
        Prompt(
            title: "Free Write",
            description: "Let your thoughts flow without judgment.",
            template: ""
        )
    ]
    
    enum AINotesState {
        case initial
        case loading
        case insights
    }
    
    init(onBack: @escaping () -> Void, initialDate: Date, initialIsReadOnly: Bool) {
        self.onBack = onBack
        self.initialDate = initialDate
        self.initialIsReadOnly = initialIsReadOnly
        self._isReadOnly = State(initialValue: initialIsReadOnly)
    }
    
    var placeholderText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(initialDate) {
            return "Enter journal for today"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Enter journal for \(formatter.string(from: initialDate))"
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with back button and checkmark/menu
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            onBack()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                    }
                    
                    Spacer()
                    
                    if isReadOnly {
                        // Read-only mode: show ••• menu
                        Menu {
                            if selectedTab == .journal {
                                // Journal tab: Edit and Delete
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isReadOnly = false
                                    }
                                    // Focus the text editor
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isTextEditorFocused = true
                                    }
                                }) {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive, action: {
                                    showDeleteConfirmation = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            } else if selectedTab == .aiNotes && aiNotesState == .insights {
                                // AI Notes tab: Report and Give Feedback
                                Button(action: {
                                    // TODO: Implement report functionality
                                }) {
                                    Label("Report", systemImage: "exclamationmark.bubble")
                                }
                                
                                Button(action: {
                                    // TODO: Implement feedback functionality
                                }) {
                                    Label("Give Feedback", systemImage: "bubble.left.and.bubble.right")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                        }
                        // Only show menu if on journal tab or on AI notes with insights
                        .opacity((selectedTab == .journal || (selectedTab == .aiNotes && aiNotesState == .insights)) ? 1 : 0)
                        .disabled(!(selectedTab == .journal || (selectedTab == .aiNotes && aiNotesState == .insights)))
                    } else {
                        // Edit mode: show ••• menu and checkmark
                        HStack(spacing: 0) {
                            // ••• menu for prompts and delete draft
                            Menu {
                                Button(action: {
                                    // Hide keyboard
                                    isTextEditorFocused = false
                                    // Show prompt library
                                    showPromptLibrary = true
                                }) {
                                    Label("View prompts", systemImage: "plus")
                                }
                                
                                Button(role: .destructive, action: {
                                    showDeleteConfirmation = true
                                }) {
                                    Label("Delete draft", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                            }
                            
                            // Checkmark to submit
                            Button(action: {
                                Task {
                                    await completeAndSave()
                                }
                            }) {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(width: 56, height: 56)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 56, height: 56)
                                }
                            }
                            .disabled(isSaving)
                        }
                    }
                }
                .frame(height: 56)
                
                // Content area with native TabView
                if isReadOnly {
                    TabView(selection: $selectedTab) {
                        // Journal tab
                        ScrollView {
                            Text(journalText)
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .textSelection(.enabled)
                                .contextMenu {
                                    Button(action: {
                                        UIPasteboard.general.string = journalText
                                    }) {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(showContent ? 1 : 0)
                        .tabItem {
                            Label("Journal", systemImage: "book")
                        }
                        .tag(Tab.journal)
                        
                        // AI Notes tab
                        ZStack {
                            if aiNotesState == .initial {
                                // Initial state: Icon + Explanation + Credits + Proceed button
                                VStack(spacing: 0) {
                                    Spacer()
                                    
                                    VStack(spacing: 20) {
                                        // Lightbulb icon
                                        Image(systemName: "lightbulb")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white)
                                            .frame(width: 24, height: 24)
                                        
                                        Text("This AI will analyze your journal and write a reflection for you.")
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 40)
                                        
                                        Text("You have \(creditsRemaining) credit\(creditsRemaining == 1 ? "" : "s") left")
                                            .font(.footnote)
                                            .foregroundColor(.white.opacity(0.5))
                                        
                                        Button(action: {
                                            generateAIInsights()
                                        }) {
                                            Text("Try for free")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                                .frame(width: 220, height: 44)
                                                .background(Color(white: 0.16))
                                                .clipShape(Capsule())
                                        }
                                        .padding(.top, 20)
                                    }
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .opacity(showContent ? aiContentOpacity : 0)
                            } else if aiNotesState == .loading {
                                // Loading state: Breathing white ball + "Loading..."
                                VStack(spacing: 40) {
                                    Spacer()
                                    
                                    BreathingCircleView()
                                    
                                    Text("Loading...")
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .opacity(aiContentOpacity)
                            } else if aiNotesState == .insights {
                                // Insights state: Banner + AI text with paragraph-by-paragraph fade-in
                                ScrollView {
                                    VStack(spacing: 20) {
                                        // Disclaimer banner (dismissible)
                                        if showAIBanner {
                                            VStack(spacing: 12) {
                                                HStack(alignment: .top, spacing: 12) {
                                                    Image(systemName: "info.circle.fill")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.white.opacity(0.8))
                                                        .padding(.top, 2)
                                                    
                                                    Text("These AI notes are here to support your reflection, but not to replace professional help. Everyone deserves support.")
                                                        .font(.footnote)
                                                        .foregroundColor(.white.opacity(0.8))
                                                        .multilineTextAlignment(.leading)
                                                    
                                                    Spacer(minLength: 0)
                                                    
                                                    // Close button
                                                    Button(action: {
                                                        withAnimation(.easeInOut(duration: 0.3)) {
                                                            showAIBanner = false
                                                        }
                                                    }) {
                                                        Image(systemName: "xmark")
                                                            .font(.system(size: 12, weight: .medium))
                                                            .foregroundColor(.white.opacity(0.6))
                                                            .frame(width: 20, height: 20)
                                                    }
                                                }
                                                
                                                // Link to mental health resources
                                                Button(action: {
                                                    if let url = URL(string: "https://www.samhsa.gov/mental-health") {
                                                        UIApplication.shared.open(url)
                                                    }
                                                }) {
                                                    Text("Explore professional help")
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.white)
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.vertical, 10)
                                                        .background(Color.white.opacity(0.1))
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                            }
                                            .padding(16)
                                            .background(Color(white: 0.16))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .padding(.horizontal, 20)
                                            .padding(.top, 16)
                                            .transition(.move(edge: .top).combined(with: .opacity))
                                        }
                                        
                                        // AI-generated insights text with paragraph animation
                                        VStack(alignment: .leading, spacing: 16) {
                                            ForEach(Array(aiInsights.components(separatedBy: "\n\n").enumerated()), id: \.offset) { index, paragraph in
                                                if !paragraph.isEmpty {
                                                    Text(paragraph)
                                                        .font(.title3)
                                                        .foregroundColor(.white)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .opacity(hasAnimatedInsights ? 1 : (visibleParagraphs.contains(index) ? 1 : 0))
                                                        .animation(hasAnimatedInsights ? nil : .easeInOut(duration: 0.6), value: visibleParagraphs)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, showAIBanner ? 0 : 16)
                                        .padding(.bottom, 20)
                                        .textSelection(.enabled)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .opacity(aiContentOpacity)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tabItem {
                            Label("AI Notes", systemImage: "lightbulb")
                        }
                        .tag(Tab.aiNotes)
                    }
                    .toolbar(isReadOnly ? .visible : .hidden, for: .tabBar)
                } else {
                    // Edit mode - show text editor with placeholder
                    ZStack(alignment: .topLeading) {
                        // Placeholder text
                        if journalText.isEmpty {
                            Text(placeholderText)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                        
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
                                if !isReadOnly {
                                    handleTextChange(oldValue: oldValue, newValue: newValue)
                                    scheduleAutoSave()
                                }
                            }
                    }
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Save to local storage when app goes to background
                if !isReadOnly {
                    Task {
                        await saveLocally()
                    }
                }
            }
        }
        .onAppear {
            isReadOnly = initialIsReadOnly
            
            // Reset AI state when opening a journal entry
            aiNotesState = .initial
            aiInsights = ""
            showAIBanner = true
            hasAnimatedInsights = false
            visibleParagraphs = []
            
            Task {
                await loadOrCreateEntry()
            }
        }
        .onDisappear {
            // Cancel any pending auto-save task
            autoSaveTask?.cancel()
        }
        .alert("Journal saved", isPresented: $showSaveConfirmation) {
            Button("Continue") {
                onBack()
            }
        } message: {
            Text("Your entry has been saved and synced securely.")
        }
        .confirmationDialog(
            isReadOnly ? "Delete this journal entry?" : "Delete this draft?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(isReadOnly ? "Delete" : "Delete draft", role: .destructive) {
                Task {
                    await deleteEntry()
                    onBack()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showSuccessSheet) {
            VStack(spacing: 16) {
                Spacer()
                
                // Checkmark icon (same size as HomeView white dot)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                // Title
                Text("Submitted")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Subtitle
                Text("You did amazing today.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Done button
                Button(action: {
                    showSuccessSheet = false
                }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 220, height: 44)
                        .background(Color(white: 0.16))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.98))
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showPromptLibrary) {
            PromptLibraryView(
                prompts: prompts,
                currentIndex: $currentPromptIndex,
                onSelect: { selectedPrompt in
                    insertPrompt(selectedPrompt)
                    showPromptLibrary = false
                    // Re-focus the text editor after prompt insertion
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isTextEditorFocused = true
                    }
                },
                onDismiss: {
                    showPromptLibrary = false
                    // Re-focus the text editor when dismissing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isTextEditorFocused = true
                    }
                }
            )
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
    
    private func scheduleAutoSave() {
        // Cancel any existing auto-save task
        autoSaveTask?.cancel()
        
        // Schedule a new auto-save after 1 second of inactivity
        autoSaveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            if !Task.isCancelled {
                await saveLocally()
            }
        }
    }
    
    private func saveLocally() async {
        // Parse the journal text
        let (poemContent, journalContent) = parseJournalText()
        
        guard let userId = AuthenticationManager.shared.user?.uid else {
            return
        }
        
        // Use the initialDate instead of Date() to respect the date being edited
        let targetDate = Calendar.current.startOfDay(for: initialDate)
        
        if let existing = currentEntry {
            // Update existing entry
            existing.poemContent = poemContent
            existing.journalContent = journalContent
            existing.lastModified = Date()
            existing.letters = generatedLetters
            // Note: Don't mark needsSync here - drafts stay local until submitted
        } else {
            // Create new entry with the target date
            let newEntry = JournalEntry(
                date: targetDate,
                poemContent: poemContent,
                letters: generatedLetters,
                journalContent: journalContent,
                userId: userId
            )
            modelContext.insert(newEntry)
            currentEntry = newEntry
        }
        
        // Save to local storage only (drafts don't sync to cloud)
        do {
            try modelContext.save()
        } catch {
            print("Error saving locally: \(error)")
        }
    }
    
    private func completeAndSave() async {
        isSaving = true
        
        // Ensure latest changes are saved locally
        await saveLocally()
        
        if let entry = currentEntry {
            // Mark as submitted and trigger cloud sync
            entry.isCompleted = true
            entry.needsSync = true
            entry.lastModified = Date()
            
            do {
                try modelContext.save()
                
                // Try to sync to cloud in background
                do {
                    try await FirestoreSyncManager.shared.saveEntry(entry)
                    // Successfully synced
                    entry.needsSync = false
                    try modelContext.save()
                } catch {
                    // Cloud sync failed - will retry automatically
                    print("Cloud sync failed, will retry: \(error)")
                }
                
                isSaving = false
                
                // Show success and switch to read-only mode
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isReadOnly = true
                    }
                    showSuccessSheet = true
                }
            } catch {
                // Local save failed - this is serious
                print("Error saving locally: \(error)")
                isSaving = false
            }
        } else {
            isSaving = false
        }
    }
    
    private func deleteEntry() async {
        guard let entry = currentEntry else { return }
        
        // Delete from Firestore if entry was submitted
        if entry.isCompleted {
            do {
                try await FirestoreSyncManager.shared.deleteEntry(entry)
            } catch {
                print("Error deleting from Firestore: \(error)")
            }
        }
        
        // Delete from local storage
        modelContext.delete(entry)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting locally: \(error)")
        }
    }
    
    private func loadOrCreateEntry() async {
        let targetDate = Calendar.current.startOfDay(for: initialDate)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        
        // Load entry from local storage
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date >= targetDate && entry.date < nextDay
            }
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            if let existingEntry = entries.first {
                // Load existing entry from local storage
                currentEntry = existingEntry
                journalText = reconstructJournalText(from: existingEntry)
                generatedLetters = existingEntry.letters
            } else if !isReadOnly {
                // Create new entry if in edit mode
                createNewEntry()
            } else {
                // Read-only mode with no entry
                currentEntry = nil
                journalText = ""
                generatedLetters = []
            }
            
            // Slow fade-in animation
            withAnimation(.easeInOut(duration: 1.5)) {
                showContent = true
            }
        } catch {
            print("Error loading entry: \(error)")
            if !isReadOnly {
                createNewEntry()
            }
            withAnimation(.easeInOut(duration: 1.5)) {
                showContent = true
            }
        }
    }
    
    private func createNewEntry() {
        // Start with blank canvas
        journalText = ""
        generatedLetters = []
    }
    
    private func insertPrompt(_ prompt: Prompt) {
        // For poem starter kit, generate random letters
        var textToInsert = prompt.template
        if prompt.title == "Poem Starter Kit" {
            let availableLetters = "ABCDEFGHIKLMNOPRSTW"
            let letter1 = String(availableLetters.randomElement()!)
            let letter2 = String(availableLetters.randomElement()!)
            let letter3 = String(availableLetters.randomElement()!)
            generatedLetters = [letter1, letter2, letter3]
            
            let letters = "\(letter1)\n\(letter2)\n\(letter3)"
            textToInsert = textToInsert.replacingOccurrences(of: "[LETTERS]", with: letters)
        }
        
        // Insert at the end
        if journalText.isEmpty {
            journalText = textToInsert
        } else {
            // Add spacing if text already exists
            if !journalText.hasSuffix("\n") {
                journalText += "\n\n"
            } else if !journalText.hasSuffix("\n\n") {
                journalText += "\n"
            }
            journalText += textToInsert
        }
    }
    
    private func reconstructJournalText(from entry: JournalEntry) -> String {
        // If there's poem content, reconstruct with the old format for backwards compatibility
        if !entry.poemContent.isEmpty {
            let letters = entry.letters.joined(separator: "\n")
            return "Today's poem\n\n\(letters)\n\n\n\nToday's journal\n\n\(entry.journalContent)"
        } else {
            // New format: just return the journal content
            return entry.journalContent
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
    
    // MARK: - AI Insights
    
    private func generateAIInsights() {
        // Fade out initial content
        withAnimation(.easeInOut(duration: 0.5)) {
            aiContentOpacity = 0
        }
        
        // Wait for fade out, then switch to loading and fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            aiNotesState = .loading
            withAnimation(.easeInOut(duration: 0.5)) {
                aiContentOpacity = 1
            }
            
            // TODO: Implement actual AI generation
            // For now, simulate with a delay
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                
                // Mock AI insights
                let mockInsights = """
                Reflection on your journal entry:
                
                Your writing today shows thoughtfulness and self-awareness. The themes you explored reveal a journey of personal growth.
                
                Key insights:
                • You're processing experiences in a healthy way
                • There's evidence of resilience in your thoughts
                • Consider what patterns you notice over time
                
                Remember, these reflections are meant to support your own thinking, not to provide answers. Your insights matter most.
                """
                
                await MainActor.run {
                    // Fade out loading
                    withAnimation(.easeInOut(duration: 0.5)) {
                        aiContentOpacity = 0
                    }
                    
                    // Wait for fade out, then show insights and fade in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        aiInsights = mockInsights
                        creditsRemaining = max(0, creditsRemaining - 1)
                        aiNotesState = .insights
                        showAIBanner = true // Reset banner visibility when new insights load
                        hasAnimatedInsights = false // Reset animation flag for new insights
                        visibleParagraphs = [] // Clear visible paragraphs
                        
                        withAnimation(.easeInOut(duration: 0.5)) {
                            aiContentOpacity = 1
                        }
                        
                        // Trigger paragraph-by-paragraph animation
                        animateParagraphs()
                    }
                }
            }
        }
    }
    
    private func animateParagraphs() {
        let paragraphs = aiInsights.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        
        for (index, _) in paragraphs.enumerated() {
            // Stagger each paragraph by 0.4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.4) {
                visibleParagraphs.insert(index)
                
                // Mark as animated after the last paragraph
                if index == paragraphs.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        hasAnimatedInsights = true
                    }
                }
            }
        }
    }
}

// MARK: - Breathing Circle View for Loading

struct BreathingCircleView: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 24, height: 24)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 2.5
                    opacity = 0.4
                }
            }
    }
}

// MARK: - Prompt Library View

struct PromptLibraryView: View {
    let prompts: [JournalView.Prompt]
    @Binding var currentIndex: Int
    let onSelect: (JournalView.Prompt) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Swipeable prompt cards
            TabView(selection: $currentIndex) {
                ForEach(0..<prompts.count, id: \.self) { index in
                    VStack(spacing: 20) {
                        // Title
                        Text(prompts[index].title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        // Description
                        Text(prompts[index].description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Use this prompt button
                        Button(action: {
                            onSelect(prompts[index])
                        }) {
                            Text("Use this prompt")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 220, height: 44)
                                .background(Color(white: 0.16))
                                .clipShape(Capsule())
                        }
                        .padding(.top, 20)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.98))
        .presentationDetents([.height(350)])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    JournalView(onBack: {}, initialDate: Date(), initialIsReadOnly: false)
}
