//
//  CalendarView.swift
//  Goodnight Journal
//
//  Created by Hiroo Aoyama on 1/16/26.
//

import SwiftUI
import SwiftData

// MARK: - Physics Ball Model
struct PhysicsBall: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    let radius: CGFloat = 12 // 24pt diameter / 2
    var isFalling: Bool = true
    var isSettled: Bool = false
    var isDragging: Bool = false
    let entryDate: Date // Associated journal entry date
    
    init(x: CGFloat, y: CGFloat = -50, entryDate: Date) {
        self.position = CGPoint(x: x, y: y)
        self.velocity = CGVector(dx: 0, dy: 400) // Initial fall speed (will accelerate)
        self.entryDate = entryDate
    }
}

struct CalendarView: View {
    let namespace: Namespace.ID
    let onBack: () -> Void
    let selectedDate: Date
    let onBallTap: (Date) -> Void // Navigate to specific journal entry
    @State private var isTransitioningBack: Bool = false
    @State private var isTransitioningOut: Bool = false // Track when we're leaving the view
    
    // Physics state
    @State private var balls: [PhysicsBall] = []
    @State private var screenSize: CGSize = .zero
    @State private var spawnTimer: Timer?
    @State private var physicsTimer: Timer?
    @State private var monthEntries: [JournalEntry] = [] // Store actual entries
    @State private var entriesSpawned: Int = 0
    @Environment(\.modelContext) private var modelContext
    
    // Drag state
    @State private var draggedBallId: UUID?
    @State private var dragStartPosition: CGPoint?
    @State private var dragStartTime: Date?
    @State private var dragHistory: [(position: CGPoint, time: Date)] = []
    @State private var longPressedBallId: UUID? // Track which ball is being held
    @State private var tooltipPosition: CGPoint = .zero // Position for tooltip
    @State private var touchStartTime: [UUID: Date] = [:] // Track touch timing for tap vs long press
    
    // Empty state
    @State private var showEmptyState: Bool = false
    
    // Constants
    let ballDiameter: CGFloat = 24
    let gravity: CGFloat = 2400 // Stronger gravity for realistic arc
    let fallingGravity: CGFloat = 1600 // Gravity during initial fall (increased for faster drop)
    let maxFallVelocity: CGFloat = 1800 // Terminal velocity for falling (increased)
    let floorOffset: CGFloat = 90 // Distance above "Jan 2026"
    let bounceRestitution: CGFloat = 0.65 // Increased bounce from ground
    let friction: CGFloat = 0.97 // High friction to stop movement
    let collisionRestitution: CGFloat = 0.6 // Off-center collision bounciness
    let fps: Double = 60
    let dragVelocityMultiplier: CGFloat = 0.3 // Scale throw strength (reduced for more controlled throws)
    let maxThrowVelocity: CGFloat = 900 // Cap max speed (reduced)
    let maxThrowVelocityY: CGFloat = 1200 // Cap vertical throw speed
    let wallBounceRestitution: CGFloat = 0.7 // Wall bounce dampening (increased to maintain momentum)
    let quickTapThreshold: TimeInterval = 0.2 // 200ms - tap vs long press threshold
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Back button - top left
                    HStack {
                        Button(action: {
                            handleBackAction()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(20)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Month and year at bottom - animates from full date
                    Button(action: {
                        handleBackAction()
                    }) {
                        HStack(spacing: 0) {
                            Text(monthString())
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            
                            if isTransitioningBack {
                                Text(" \(dayString()), \(yearString())")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            } else {
                                Text(" \(yearString())")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                        .matchedGeometryEffect(id: "dateLabel", in: namespace)
                    }
                    .frame(minWidth: 120)
                    .padding(.bottom, 40)
                }
                
                // Falling balls layer
                ForEach(balls) { ball in
                    let canInteract = canInteractWithBall(ball)
                    let entry = monthEntries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: ball.entryDate) })
                    let isDraft = entry?.isCompleted == false
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: ballDiameter, height: ballDiameter)
                        .scaleEffect(ball.isDragging ? 1.15 : 1.0)
                        .opacity(isTransitioningOut ? 0 : (ball.isDragging ? 1.0 : (isDraft ? 0.5 : 0.85)))
                        .position(ball.position)
                        .onLongPressGesture(minimumDuration: 0.2) {
                            // Long press threshold reached - show tooltip with haptic
                            if canInteract && !isTransitioningOut {
                                handleLongPressReached(ballId: ball.id, ballPosition: ball.position)
                            }
                        } onPressingChanged: { isPressing in
                            if canInteract && !isTransitioningOut {
                                handleBallPress(isPressing: isPressing, ballId: ball.id, ballPosition: ball.position, entryDate: ball.entryDate)
                            }
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    // Allow drag if ball can initially interact OR is already being dragged
                                    if (canInteract || ball.isDragging) && !isTransitioningOut {
                                        longPressedBallId = nil // Hide tooltip when dragging
                                        handleDragChanged(ballId: ball.id, location: value.location)
                                    }
                                }
                                .onEnded { value in
                                    // Allow drag end if ball is being dragged
                                    if (canInteract || ball.isDragging) && !isTransitioningOut {
                                        handleDragEnded(ballId: ball.id)
                                    }
                                }
                        )
                        .allowsHitTesting(!isTransitioningOut) // Disable interaction during transition
                }
                
                // Date tooltip overlay (rendered on top of all balls)
                if let pressedId = longPressedBallId,
                   let ball = balls.first(where: { $0.id == pressedId }),
                   !isTransitioningOut {
                    Text(formatDate(ball.entryDate))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(6)
                        .position(x: ball.position.x, y: ball.position.y - 40)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
                
                // Empty state message
                if showEmptyState && !isTransitioningOut {
                    Text("No journals found")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .transition(.opacity)
                }
            }
            .onAppear {
                isTransitioningBack = false
                isTransitioningOut = false
                screenSize = geometry.size
                showEmptyState = false
                
                // Start immediately, no delay
                startPhysicsSimulation()
            }
            .onDisappear {
                // Clean up physics when view is removed from hierarchy
                stopPhysics()
            }
        }
    }
    
    // MARK: - Physics Simulation
    
    private func startPhysicsSimulation() {
        // Get journal entries for this month
        monthEntries = getMonthEntries()
        entriesSpawned = 0
        balls = []
        
        guard !monthEntries.isEmpty else {
            // No entries - show empty state with fade-in animation after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeIn(duration: 0.4)) {
                    showEmptyState = true
                }
            }
            return
        }
        
        // Start spawn timer - spawn balls rapidly one after another (0.1s interval)
        let spawnInterval = 0.1
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { _ in
            spawnBall()
        }
        
        // Start physics update loop
        physicsTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { _ in
            updatePhysics()
        }
    }
    
    private func stopPhysics() {
        spawnTimer?.invalidate()
        physicsTimer?.invalidate()
        spawnTimer = nil
        physicsTimer = nil
    }
    
    private func getMonthEntries() -> [JournalEntry] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        
        guard let year = components.year,
              let month = components.month,
              let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth),
              let nextMonth = calendar.date(byAdding: .day, value: 1, to: endOfMonth) else {
            return []
        }
        
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date >= startOfMonth && entry.date < nextMonth
            },
            sortBy: [SortDescriptor(\.date)]
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            return Array(entries.prefix(31)) // Cap at 31
        } catch {
            print("Error fetching month entries: \(error)")
            return []
        }
    }
    
    private func spawnBall() {
        guard entriesSpawned < monthEntries.count else {
            spawnTimer?.invalidate()
            spawnTimer = nil
            return
        }
        
        let entry = monthEntries[entriesSpawned]
        
        // Random X position across screen width (with padding)
        let padding: CGFloat = 24
        let randomX = CGFloat.random(in: padding...(screenSize.width - padding))
        
        let newBall = PhysicsBall(x: randomX, y: -50, entryDate: entry.date)
        balls.append(newBall)
        entriesSpawned += 1
    }
    
    private func updatePhysics() {
        let deltaTime = 1.0 / fps
        let floorY = screenSize.height - floorOffset
        
        for i in 0..<balls.count {
            // Skip if ball is being dragged
            if balls[i].isDragging {
                continue
            }
            
            // Skip if ball has settled
            if balls[i].isSettled {
                continue
            }
            
            // Phase 1: Falling straight down with acceleration
            if balls[i].isFalling {
                // Apply gravity acceleration
                balls[i].velocity.dy += fallingGravity * deltaTime
                
                // Cap at terminal velocity
                if balls[i].velocity.dy > maxFallVelocity {
                    balls[i].velocity.dy = maxFallVelocity
                }
                
                // Update position
                balls[i].position.y += balls[i].velocity.dy * deltaTime
                
                // Check if hit floor
                if balls[i].position.y + balls[i].radius >= floorY {
                    balls[i].position.y = floorY - balls[i].radius
                    balls[i].velocity.dy = -balls[i].velocity.dy * bounceRestitution // Small bounce
                    balls[i].isFalling = false
                    
                    // If bounce is too small, stop immediately
                    if abs(balls[i].velocity.dy) < 50 {
                        balls[i].velocity = CGVector(dx: 0, dy: 0)
                    }
                }
            }
            // Phase 2: Landed - apply gravity and physics
            else {
                // Apply gravity
                balls[i].velocity.dy += gravity * deltaTime
                
                // Update position
                balls[i].position.x += balls[i].velocity.dx * deltaTime
                balls[i].position.y += balls[i].velocity.dy * deltaTime
                
                // Floor collision
                if balls[i].position.y + balls[i].radius >= floorY {
                    balls[i].position.y = floorY - balls[i].radius
                    balls[i].velocity.dy = -balls[i].velocity.dy * bounceRestitution
                    
                    // Stop if velocity is very small
                    if abs(balls[i].velocity.dy) < 30 && abs(balls[i].velocity.dx) < 30 {
                        balls[i].velocity = CGVector(dx: 0, dy: 0)
                        balls[i].isSettled = true
                    }
                }
                
                // Screen edge collision
                if balls[i].position.x - balls[i].radius <= 0 {
                    balls[i].position.x = balls[i].radius
                    balls[i].velocity.dx = -balls[i].velocity.dx * wallBounceRestitution
                } else if balls[i].position.x + balls[i].radius >= screenSize.width {
                    balls[i].position.x = screenSize.width - balls[i].radius
                    balls[i].velocity.dx = -balls[i].velocity.dx * wallBounceRestitution
                }
                
                // Apply friction
                balls[i].velocity.dx *= friction
            }
        }
        
        // Check collisions between landed balls
        checkCollisions()
    }
    
    private func checkCollisions() {
        for i in 0..<balls.count {
            // Skip dragged balls
            if balls[i].isDragging {
                continue
            }
            
            // Check for balls that have landed (including settled ones)
            guard !balls[i].isFalling else { continue }
            
            for j in (i+1)..<balls.count {
                // Skip dragged balls
                if balls[j].isDragging {
                    continue
                }
                
                // Check collisions with other landed balls (including settled)
                guard !balls[j].isFalling else { continue }
                
                let dx = balls[j].position.x - balls[i].position.x
                let dy = balls[j].position.y - balls[i].position.y
                let distance = sqrt(dx * dx + dy * dy)
                let minDistance = balls[i].radius + balls[j].radius
                
                // Collision detected
                if distance < minDistance && distance > 0 {
                    // Calculate collision normal
                    let nx = dx / distance
                    let ny = dy / distance
                    
                    // Separate overlapping balls
                    let overlap = minDistance - distance
                    let separationX = nx * overlap * 0.5
                    let separationY = ny * overlap * 0.5
                    
                    balls[i].position.x -= separationX
                    balls[i].position.y -= separationY
                    balls[j].position.x += separationX
                    balls[j].position.y += separationY
                    
                    // Calculate relative velocity
                    let dvx = balls[j].velocity.dx - balls[i].velocity.dx
                    let dvy = balls[j].velocity.dy - balls[i].velocity.dy
                    let dvn = dvx * nx + dvy * ny
                    
                    // Only apply impulse if balls moving toward each other
                    // (but always separate them to prevent overlap)
                    if dvn < 0 {
                        // Apply impulse
                        let impulse = (1 + collisionRestitution) * dvn / 2
                        
                        balls[i].velocity.dx += impulse * nx
                        balls[i].velocity.dy += impulse * ny
                        balls[j].velocity.dx -= impulse * nx
                        balls[j].velocity.dy -= impulse * ny
                        
                        // Wake up settled balls if hit hard enough
                        if balls[i].isSettled && abs(impulse) > 5 {
                            balls[i].isSettled = false
                        }
                        if balls[j].isSettled && abs(impulse) > 5 {
                            balls[j].isSettled = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Interaction Check
    
    private func canInteractWithBall(_ ball: PhysicsBall) -> Bool {
        let floorY = screenSize.height - floorOffset
        let distanceFromFloor = floorY - (ball.position.y + ball.radius)
        let speed = sqrt(ball.velocity.dx * ball.velocity.dx + ball.velocity.dy * ball.velocity.dy)
        
        // Ball must:
        // 1. Not be in initial falling phase
        // 2. Be very close to the floor (within 15 points)
        // 3. Not be moving too fast (speed < 150)
        return !ball.isFalling && 
               distanceFromFloor < 15 && 
               speed < 150
    }
    
    // MARK: - Drag Handling
    
    private func handleDragChanged(ballId: UUID, location: CGPoint) {
        guard let index = balls.firstIndex(where: { $0.id == ballId }) else { return }
        
        // First time dragging this ball
        if !balls[index].isDragging {
            draggedBallId = ballId
            balls[index].isDragging = true
            balls[index].isFalling = false
            balls[index].isSettled = false
            balls[index].velocity = CGVector(dx: 0, dy: 0)
            dragStartPosition = location
            dragStartTime = Date()
            dragHistory = []
            
            // Clear touch timer to prevent tap action after drag
            touchStartTime.removeValue(forKey: ballId)
        }
        
        // Update ball position to follow finger
        balls[index].position = location
        
        // Record position history for velocity calculation (keep last 5 positions)
        dragHistory.append((position: location, time: Date()))
        if dragHistory.count > 5 {
            dragHistory.removeFirst()
        }
    }
    
    private func handleDragEnded(ballId: UUID) {
        guard let index = balls.firstIndex(where: { $0.id == ballId }) else { return }
        
        balls[index].isDragging = false
        
        // Calculate throw velocity from drag history
        if dragHistory.count >= 2 {
            let recent = dragHistory.suffix(3) // Use last 3 positions
            
            if recent.count >= 2 {
                let first = recent.first!
                let last = recent.last!
                
                let dx = last.position.x - first.position.x
                let dy = last.position.y - first.position.y
                let dt = last.time.timeIntervalSince(first.time)
                
                if dt > 0 {
                    var velocityX = (dx / dt) * dragVelocityMultiplier
                    var velocityY = (dy / dt) * dragVelocityMultiplier
                    
                    // Cap vertical velocity separately (prevent throwing too high)
                    if velocityY < 0 { // Negative = upward
                        velocityY = max(velocityY, -maxThrowVelocityY)
                    }
                    
                    // Cap total velocity
                    let speed = sqrt(velocityX * velocityX + velocityY * velocityY)
                    if speed > maxThrowVelocity {
                        let scale = maxThrowVelocity / speed
                        velocityX *= scale
                        velocityY *= scale
                    }
                    
                    balls[index].velocity = CGVector(dx: velocityX, dy: velocityY)
                }
            }
        }
        
        // Reset drag state
        draggedBallId = nil
        dragStartPosition = nil
        dragStartTime = nil
        dragHistory = []
    }
    
    private func handleBallTap(entryDate: Date) {
        // Navigate to the journal entry for this date
        onBallTap(entryDate)
    }
    
    private func handleBallPress(isPressing: Bool, ballId: UUID, ballPosition: CGPoint, entryDate: Date) {
        if isPressing {
            // Touch started - record the time
            touchStartTime[ballId] = Date()
        } else {
            // Touch ended - check if it was a quick tap or long press
            if let startTime = touchStartTime[ballId] {
                let duration = Date().timeIntervalSince(startTime)
                
                // Only treat as tap if it was quick AND ball wasn't being dragged
                if duration < quickTapThreshold && draggedBallId != ballId {
                    // Quick tap - navigate (no haptic)
                    onBallTap(entryDate)
                }
                // else: Long press - do nothing, tooltip will fade on its own
                
                // Clean up
                touchStartTime.removeValue(forKey: ballId)
            }
            
            // Hide tooltip
            withAnimation(.easeInOut(duration: 0.15)) {
                longPressedBallId = nil
            }
        }
    }
    
    private func handleLongPressReached(ballId: UUID, ballPosition: CGPoint) {
        // Long press threshold reached - show tooltip with haptic
        withAnimation(.easeInOut(duration: 0.15)) {
            longPressedBallId = ballId
            tooltipPosition = ballPosition
            
            // Haptic feedback for long press
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    // MARK: - Date Formatting
    
    private func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private func monthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: selectedDate)
    }
    
    private func dayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: selectedDate)
    }
    
    private func yearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: selectedDate)
    }
    
    // MARK: - Navigation
    
    private func handleBackAction() {
        // Prevent multiple taps
        guard !isTransitioningOut else { return }
        
        // Start transition animation
        withAnimation(.easeInOut(duration: 0.5)) {
            isTransitioningBack = true
            isTransitioningOut = true
        }
        
        // Hide tooltip immediately if shown
        longPressedBallId = nil
        
        // Trigger navigation callback after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onBack()
            // Physics will be stopped in onDisappear
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    CalendarView(namespace: namespace, onBack: {}, selectedDate: Date(), onBallTap: { _ in })
}
