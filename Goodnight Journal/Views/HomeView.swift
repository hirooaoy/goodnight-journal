//
//  HomeView.swift
//  Goodnight Journal
//
//  Created by Hiroo Aoyama on 1/13/26.
//

import SwiftUI
import SwiftData

struct Quote: Codable {
    let text: String
}

struct HomeView: View {
    let namespace: Namespace.ID
    let onStart: (Bool, Bool, Date) -> Void  // Pass (isEditing, isReadOnly, selectedDate)
    let onSignOut: () -> Void
    let onCalendarTap: (Date) -> Void  // Pass the selectedDate to parent
    @Binding var selectedDate: Date  // Changed to Binding to preserve state
    @State private var currentQuote: String = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasTodayEntry: Bool = false
    @State private var isTodayEntryCompleted: Bool = false
    @State private var showMenu: Bool = false
    @State private var isTransitioningToCalendar: Bool = false
    @State private var hasSelectedDateEntry: Bool = false
    @State private var isSelectedDateCompleted: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with menu button
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showMenu.toggle()
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                    }
                    .confirmationDialog("", isPresented: $showMenu, titleVisibility: .hidden) {
                        Button("Sign Out", role: .destructive) {
                            onSignOut()
                        }
                        
                        Button("Cancel", role: .cancel) {}
                    }
                }
                .frame(height: 56)
                .opacity(isTransitioningToCalendar ? 0 : 1)
                
                Spacer()
                
                // Small circle with matched geometry (or checkmark when completed)
                // Only show if shouldShowButton is true
                // Circle is now visual only - not interactive
                if shouldShowButton {
                    ZStack {
                        if isSelectedDateCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else if hasSelectedDateEntry {
                            // Draft exists - show dimmer circle
                            Circle()
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                                .opacity(0.5)
                                .matchedGeometryEffect(id: "breatheCircle", in: namespace)
                        } else {
                            // No entry - show normal circle
                            Circle()
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                                .matchedGeometryEffect(id: "breatheCircle", in: namespace)
                        }
                    }
                    .frame(width: 24, height: 24)
                    .opacity(isTransitioningToCalendar ? 0 : 1)
                }
                
                // Quote text
                Text(currentQuote)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, shouldShowButton ? 20 : 0)
                    .opacity(isTransitioningToCalendar ? 0 : 1)
                
                // Start button - only show if shouldShowButton is true
                if shouldShowButton {
                    Button(action: {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        let isViewingToday = Calendar.current.isDate(selectedDate, inSameDayAs: Date())
                        
                        if isViewingToday {
                            if isTodayEntryCompleted {
                                // Completed entry - skip breathing, go directly to read-only mode
                                onStart(true, true, selectedDate)
                            } else if hasTodayEntry {
                                // Continue journal (draft) - skip breathing, go to edit mode
                                onStart(true, false, selectedDate)
                            } else {
                                // Start new journal - go through breathing first
                                onStart(false, false, selectedDate)
                            }
                        } else {
                            // Viewing a past date
                            if hasSelectedDateEntry && isSelectedDateCompleted {
                                // Completed entry - skip breathing, go directly to read-only mode
                                onStart(true, true, selectedDate)
                            } else if hasSelectedDateEntry && !isSelectedDateCompleted {
                                // Continue journal (draft) - skip breathing, go to edit mode
                                onStart(true, false, selectedDate)
                            } else {
                                // Start new journal for yesterday - go through breathing first
                                onStart(false, false, selectedDate)
                            }
                        }
                    }
                    }) {
                        Text(buttonText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isExpired ? .white.opacity(0.3) : .white)
                            .frame(width: 220, height: 44)
                            .background(Color(white: 0.16))
                            .clipShape(Capsule())
                    }
                    .disabled(isExpired)
                    .padding(.top, 40)
                    .opacity(isTransitioningToCalendar ? 0 : 1)
                }
                
                Spacer()
                
                // "Today" label above date when viewing today
                VStack(spacing: 8) {
                    Text(isViewingToday ? "Today" : "")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .opacity(isTransitioningToCalendar ? 0 : 1)
                        .frame(height: 17)  // Fixed height to prevent layout shifts
                    
                    // Date navigation with chevrons - keeps < date > centered
                    HStack {
                        // Left side spacer
                        Spacer()
                        
                        // Centered navigation: < date >
                        HStack(spacing: 20) {
                            // Left chevron - navigate to previous day
                            Button(action: {
                                navigateToPreviousDay()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            .opacity(isTransitioningToCalendar ? 0 : 1)
                            
                            // Date display - clickable for calendar
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isTransitioningToCalendar = true
                                }
                                
                                // Trigger navigation after animation starts
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    onCalendarTap(selectedDate)
                                }
                            }) {
                                HStack(spacing: 0) {
                                    Text(monthString(for: selectedDate))
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    
                                    if !isTransitioningToCalendar {
                                        Text(" \(dayString(for: selectedDate)), \(yearString(for: selectedDate))")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    } else {
                                        Text(" \(yearString(for: selectedDate))")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    }
                                }
                                .matchedGeometryEffect(id: "dateLabel", in: namespace)
                            }
                            .frame(minWidth: 120)
                            
                            // Right chevron - navigate to next day (disabled if viewing today)
                            Button(action: {
                                navigateToNextDay()
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(isViewingToday ? .white.opacity(0.3) : .white)
                            }
                            .disabled(isViewingToday)
                            .opacity(isTransitioningToCalendar ? 0 : 1)
                        }
                        .overlay(alignment: .trailing) {
                            // ">>" indicator when viewing dates older than yesterday
                            if !isViewingToday && !isViewingYesterday {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedDate = Date()
                                        checkForSelectedDateEntry()
                                    }
                                }) {
                                    HStack(spacing: -2) {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    }
                                }
                                .offset(x: 60)
                                .opacity(isTransitioningToCalendar ? 0 : 1)
                                .transition(.opacity)
                            }
                        }
                        
                        // Right side spacer - balances the left to keep center aligned
                        Spacer()
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .task {
            loadQuoteOfTheDay()
            checkForTodayEntry()
            isTransitioningToCalendar = false
        }
        .onAppear {
            // Listen for day change notifications (fires at midnight)
            NotificationCenter.default.addObserver(
                forName: .NSCalendarDayChanged,
                object: nil,
                queue: .main
            ) { _ in
                checkForTodayEntry()
                loadQuoteOfTheDay()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                checkForTodayEntry()
                loadQuoteOfTheDay()
            }
        }
    }
    
    private var buttonText: String {
        let isViewingToday = Calendar.current.isDate(selectedDate, inSameDayAs: Date())
        
        // Check if date is 2+ days in the past (expired)
        if !isViewingToday && !isViewingYesterday {
            return "Expired"
        }
        
        if isViewingToday {
            if isTodayEntryCompleted {
                return "Read journal"
            } else if hasTodayEntry {
                return "Continue journal"
            } else {
                return "Start journal"
            }
        } else {
            // Viewing a past date (must be yesterday since we checked for 2+ days above)
            if hasSelectedDateEntry && isSelectedDateCompleted {
                return "Read journal"
            } else if hasSelectedDateEntry {
                return "Continue journal"
            } else {
                return "Start journal"
            }
        }
    }
    
    private var isViewingToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }
    
    private var isViewingYesterday: Bool {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
            return false
        }
        return Calendar.current.isDate(selectedDate, inSameDayAs: yesterday)
    }
    
    private var isExpired: Bool {
        // Date is expired if it's 2 or more days in the past
        // AND there's no existing entry to read
        if hasSelectedDateEntry {
            return false // Can always read existing entries
        }
        return !isViewingToday && !isViewingYesterday
    }
    
    private var shouldShowButton: Bool {
        // Always show button/circle regardless of date
        return true
    }
    
    private func checkForTodayEntry() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date >= today && entry.date < tomorrow
            }
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            if let entry = entries.first {
                hasTodayEntry = true
                isTodayEntryCompleted = entry.isCompleted
            } else {
                hasTodayEntry = false
                isTodayEntryCompleted = false
            }
        } catch {
            print("Error checking for today's entry: \(error)")
            hasTodayEntry = false
            isTodayEntryCompleted = false
        }
        
        // Also check selected date entry
        checkForSelectedDateEntry()
    }
    
    private func checkForSelectedDateEntry() {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date >= startOfDay && entry.date < endOfDay
            }
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            if let entry = entries.first {
                hasSelectedDateEntry = true
                isSelectedDateCompleted = entry.isCompleted
            } else {
                hasSelectedDateEntry = false
                isSelectedDateCompleted = false
            }
        } catch {
            print("Error checking for selected date entry: \(error)")
            hasSelectedDateEntry = false
            isSelectedDateCompleted = false
        }
    }
    
    private func loadQuoteOfTheDay() {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let quotes = try? JSONDecoder().decode([Quote].self, from: data),
              !quotes.isEmpty else {
            currentQuote = "You are not alone."
            return
        }
        
        // Calculate days since a reference date (Jan 1, 2020)
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        let today = calendar.startOfDay(for: Date())
        let daysSinceReference = calendar.dateComponents([.day], from: referenceDate, to: today).day ?? 0
        
        // Use modulo to cycle through quotes
        let quoteIndex = daysSinceReference % quotes.count
        currentQuote = quotes[quoteIndex].text
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private func formattedSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: Date())
    }
    
    private func monthString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func dayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func yearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    
    // MARK: - Date Navigation
    
    private func navigateToPreviousDay() {
        guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = previousDay
            checkForSelectedDateEntry()
        }
    }
    
    private func navigateToNextDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let currentSelectedDay = Calendar.current.startOfDay(for: selectedDate)
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentSelectedDay),
              nextDay <= today else {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = nextDay
            checkForSelectedDateEntry()
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    @Previewable @State var selectedDate = Date()
    HomeView(namespace: namespace, onStart: { _, _, _ in }, onSignOut: {}, onCalendarTap: { _ in }, selectedDate: $selectedDate)
}
