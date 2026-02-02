# Behavioral Consistency Fixes - Summary

## Date: January 24, 2026

## Issues Addressed

### ✅ 1. Circle Button Removed from Interaction
**File:** `HomeView.swift`

**Problem:** Circle button and "Start journal" button had different behaviors:
- Circle always went through breathing
- Button skipped breathing

**Solution:** Made circle visual-only (not interactive). All interactions now go through the main button.

**Changes:**
- Removed `Button` wrapper around circle
- Circle is now just a `ZStack` with visual states (checkmark, dimmed, normal)
- Consistent behavior through one button only

---

### ✅ 2. Breathing Flow Consistency
**File:** `HomeView.swift`

**Problem:** Inconsistent breathing exercise behavior across different entry states.

**Solution:** Implemented clear, consistent rules:

| Entry State | Button Text | Breathing? | Mode |
|------------|-------------|-----------|------|
| **New entry (no draft)** | "Start journal" | ✅ YES | Edit |
| **Draft exists** | "Continue journal" | ❌ NO | Edit |
| **Completed entry** | "Read journal" | ❌ NO | Read-only |
| **Expired (2+ days, no entry)** | "Expired" | N/A | Disabled |

**Logic:**
```swift
if entryExists && isCompleted {
    // Skip breathing → Read-only
    onStart(true, true, selectedDate)
} else if entryExists && !isCompleted {
    // Skip breathing → Edit mode (Continue)
    onStart(true, false, selectedDate)
} else {
    // Go through breathing → Edit mode (Start new)
    onStart(false, false, selectedDate)
}
```

---

### ✅ 3. Button Text Clarity
**File:** `HomeView.swift`

**Problem:** Button always said "Start journal" for both new entries and drafts.

**Solution:** Updated `buttonText` property to distinguish:
- **"Start journal"** - New entry (requires breathing)
- **"Continue journal"** - Draft exists (skip breathing)
- **"Read journal"** - Completed entry (skip breathing)
- **"Expired"** - 2+ days old with no entry (disabled)

---

### ✅ 4. Calendar Navigation Entry Status Check
**File:** `ContentView.swift`

**Problem:** Calendar always opened entries in read-only mode, even for drafts or non-existent entries.

**Solution:** Added database query to check entry status before navigation:

```swift
// Query database for the tapped date
let descriptor = FetchDescriptor<JournalEntry>(...)
let entries = try modelContext.fetch(descriptor)

if let entry = entries.first {
    // Entry exists - check completion status
    isJournalReadOnly = entry.isCompleted  // true for completed, false for draft
} else {
    // No entry - open in edit mode to allow creation
    isJournalReadOnly = false
}
```

**Now handles:**
- ✅ Completed entries → Read-only mode
- ✅ Draft entries → Edit mode
- ✅ Non-existent entries → Edit mode (allows creation)

---

### ✅ 5. AI Notes State Reset
**File:** `JournalView.swift`

**Problem:** AI insights persisted across different journal entries, showing stale data from previous entries.

**Example Bug:**
1. Open Jan 23 journal → Generate AI insights
2. Navigate to Jan 22 journal → AI tab shows Jan 23's insights (wrong!)

**Solution:** Reset all AI state variables in `.onAppear`:

```swift
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
```

**Result:** Each journal entry now starts with clean AI state.

---

## Additional Context for Identified Issues

### Issue #6: Auto-save vs Manual Save (NOT FIXED - Clarification Needed)

**Current Design:**
- **Drafts:** Auto-saved locally only, NOT synced to cloud
- **Completed entries:** Synced to cloud with `needsSync = true`

**Implication:**
If a user writes a draft on Device A and switches to Device B, the draft won't be available (because drafts don't sync).

**Question for User:**
Is this intentional? Should drafts remain local-only until submission, or should they sync across devices?

**If drafts should sync:**
We need to modify `saveLocally()` to set `needsSync = true` for drafts as well, not just completed entries.

---

### Issue #8: Expired Entry Editing (CLARIFIED - No Fix Needed)

**User Clarification:**
- "Expired" means you can't CREATE new entries 2+ days in the past
- If an entry EXISTS (even 2+ days old), you can still read/edit it
- This is correct behavior - the expiration only applies to NEW journal creation

---

## Testing Checklist

### Test Scenario 1: New Journal Flow
1. ✅ Open app on today's date with no entry
2. ✅ Verify button says "Start journal"
3. ✅ Tap button → Goes through breathing exercise
4. ✅ After breathing → Opens journal in edit mode

### Test Scenario 2: Draft Continuation
1. ✅ Write partial journal entry (don't submit)
2. ✅ Go back to HomeView
3. ✅ Verify button says "Continue journal"
4. ✅ Verify circle is dimmed (opacity 0.5)
5. ✅ Tap button → Skips breathing, opens in edit mode

### Test Scenario 3: Read Completed Entry
1. ✅ Complete and submit a journal entry
2. ✅ Go back to HomeView
3. ✅ Verify button says "Read journal"
4. ✅ Verify circle shows checkmark
5. ✅ Tap button → Skips breathing, opens in read-only mode

### Test Scenario 4: Calendar Navigation
1. ✅ Open calendar view
2. ✅ Tap a ball for a completed entry → Opens in read-only mode
3. ✅ Go back, tap a ball for a draft → Opens in edit mode
4. ✅ Go back, tap a date with no entry → Opens in edit mode (allows creation)

### Test Scenario 5: AI Notes Isolation
1. ✅ Open today's journal
2. ✅ Generate AI insights
3. ✅ Go back to HomeView
4. ✅ Navigate to yesterday's journal
5. ✅ Open AI Notes tab → Verify it shows "initial" state (not today's insights)

### Test Scenario 6: Circle Button Non-Interactive
1. ✅ Tap/long-press circle → Nothing happens
2. ✅ Only the "Start/Continue/Read journal" button triggers actions

---

## Files Modified

1. **HomeView.swift**
   - Removed circle button interactivity
   - Updated button action logic for breathing consistency
   - Updated `buttonText` to distinguish Start/Continue/Read

2. **ContentView.swift**
   - Added `@Environment(\.modelContext)` for database queries
   - Added entry status check before calendar navigation
   - Added `import SwiftData`

3. **JournalView.swift**
   - Added AI state reset in `.onAppear`
   - Ensures fresh AI state for each journal entry

---

## Remaining Questions

### Question 1: Draft Sync Behavior
Should drafts sync across devices, or remain local-only until submission?

**Current:** Local-only  
**Implication:** Device switch = lost drafts  
**User preference:** ?

### Question 2: AI Credits System
The code shows `creditsRemaining = 5` with a TODO comment. Is this being implemented?

---

## Notes on Intentional Behaviors (Not Bugs)

1. ✅ **Drafts show in calendar** - User confirmed this is desired
2. ✅ **Edit expired entries** - User confirmed you can edit existing entries from 2+ days ago
3. ✅ **"Today" label fixed height** - Minor UI quirk, not a functional issue
4. ✅ **Prompt library persistence** - Minor UX detail, not critical

---

## Commit Message Suggestion

```
fix: Resolve behavioral inconsistencies in journal flow

- Remove circle button interactivity in HomeView (visual only)
- Implement consistent breathing logic:
  * New entries: go through breathing
  * Drafts: skip breathing (Continue journal)
  * Completed: skip breathing (Read journal)
- Add proper entry status check for calendar navigation
- Reset AI state when opening different journal entries
- Update button text to show Start/Continue/Read appropriately

Fixes breathing flow inconsistency, stale AI data, and calendar navigation issues.
```
