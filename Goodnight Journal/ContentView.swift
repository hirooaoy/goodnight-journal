//
//  ContentView.swift
//  Goodnight Journal
//
//  Created by Hiroo Aoyama on 1/13/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showBreatheView: Bool = false
    @State private var showJournalView: Bool = false
    @State private var showCalendarView: Bool = false
    @State private var isJournalReadOnly: Bool = false
    @State private var showSignOutConfirmation: Bool = false
    @State private var selectedJournalDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var homeViewSelectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var cameFromCalendar: Bool = false // Track if we navigated from calendar
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.modelContext) private var modelContext
    let namespace: Namespace.ID
    
    var body: some View {
        ZStack {
            // Persistent black background to prevent white flash
            Color.black.ignoresSafeArea()
            
            if showCalendarView {
                // Calendar View
                CalendarView(
                    namespace: namespace,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showCalendarView = false
                        }
                    },
                    selectedDate: homeViewSelectedDate,
                    onBallTap: { entryDate in
                        // Navigate to journal entry for this date
                        selectedJournalDate = entryDate
                        homeViewSelectedDate = entryDate
                        
                        // Check if entry exists and is completed
                        let startOfDay = Calendar.current.startOfDay(for: entryDate)
                        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
                        
                        let descriptor = FetchDescriptor<JournalEntry>(
                            predicate: #Predicate { entry in
                                entry.date >= startOfDay && entry.date < endOfDay
                            }
                        )
                        
                        do {
                            let entries = try modelContext.fetch(descriptor)
                            if let entry = entries.first {
                                // Entry exists - open in read-only if completed, edit if draft
                                isJournalReadOnly = entry.isCompleted
                            } else {
                                // No entry exists - open in edit mode to create new
                                isJournalReadOnly = false
                            }
                        } catch {
                            print("Error fetching entry: \(error)")
                            // Default to read-only on error
                            isJournalReadOnly = true
                        }
                        
                        cameFromCalendar = true
                        
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showCalendarView = false
                            showJournalView = true
                        }
                    }
                )
                .transition(.opacity)
            } else if showJournalView {
                // Journal View
                JournalView(
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showJournalView = false
                            isJournalReadOnly = false
                            
                            // Return to calendar if we came from there
                            if cameFromCalendar {
                                showCalendarView = true
                                cameFromCalendar = false
                            }
                        }
                    },
                    initialDate: selectedJournalDate,
                    initialIsReadOnly: isJournalReadOnly
                )
                .transition(.opacity)
            } else if !showBreatheView {
                // Home View
                HomeView(
                    namespace: namespace,
                    onStart: { isEditing, isReadOnly, selectedDate in
                        isJournalReadOnly = isReadOnly
                        selectedJournalDate = selectedDate
                        cameFromCalendar = false // Coming from home, not calendar
                        if isEditing {
                            // If editing/reading existing entry, skip breathing
                            showJournalView = true
                        } else {
                            // If new entry, go through breathing first
                            showBreatheView = true
                        }
                    },
                    onSignOut: {
                        showSignOutConfirmation = true
                    },
                    onCalendarTap: { dateToView in
                        showCalendarView = true
                    },
                    selectedDate: $homeViewSelectedDate
                )
                .transition(.opacity)
            } else {
                // Breathe View
                BreatheView(
                    namespace: namespace,
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
            "Are you sure?",
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
        } message: {
            Text("Your journals will still be securely stored.")
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    ContentView(namespace: namespace)
}
