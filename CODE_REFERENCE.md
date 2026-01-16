# Goodnight Journal - Code Reference Guide

## Quick Navigation

### 📱 UI Views
```
Views/
├── AuthenticationView.swift    → Login screen (Apple/Google sign in)
└── HomeView.swift             → Main home with quote and "Start" button

Root Level:
├── BreatheView.swift          → Breathing exercise (4 cycles)
├── JournalView.swift          → Journal entry editor
└── ContentView.swift          → Main navigation coordinator
```

### 🔧 Services & Logic
```
Services/
├── AuthenticationManager.swift  → Firebase Auth (Apple, Google)
└── FirestoreSyncManager.swift  → Cloud sync for journal entries
```

### 📦 Data Models
```
Models/
└── JournalEntry.swift          → Journal entry data structure
                                  (SwiftData + Firestore compatible)
```

### 🎨 Design System

#### Colors
- **Background:** `Color.black` (all screens)
- **Text:** `Color.white` with opacity variations
- **Buttons:** `Color(white: 0.16)` for dark gray backgrounds
- **Circle:** `Color.white` for breathing circle

#### Typography
- **Titles:** `.system(size: 16, weight: .semibold)`
- **Body:** `.system(size: 16, weight: .medium)`
- **Small Text:** `.system(size: 14)` or `.system(size: 12)`
- **Captions:** `.system(size: 11)`
- **Journal:** `.title3`

#### Spacing
- **Button Height:** 44pt (standard iOS touch target)
- **Corner Radius:** 22pt (pill-shaped buttons)
- **Horizontal Padding:** 20-40pt
- **VStack Spacing:** 0-40pt depending on context

## Key Features

### 🔐 Authentication
- **Apple Sign In:** Native `SignInWithAppleButton`
- **Google Sign In:** Custom button using `GoogleSignIn` SDK
- **State Management:** `@StateObject` AuthenticationManager
- **Auto-login:** Checks for existing session on launch

### 🫁 Breathing Exercise
- **Pattern:** 3-4 breathing (3 sec inhale, 4 sec exhale)
- **Cycles:** 4 total (last one is longer: 6-7 seconds)
- **Animation:** Circle scales from 1.0 to 6.0
- **Encouragements:** "3 more to go", "You're doing great", "Last big one"
- **Screen Lock:** Disabled during breathing session

### ✍️ Journal Entry
- **Auto-save:** Local (SwiftData) + Cloud (Firestore)
- **Structure:** 
  - Today's poem (3 random letters)
  - Today's journal (free text)
- **Smart Lists:**
  - `- ` auto-converts to `• `
  - Bullet points continue on new line
  - Number lists auto-increment (1. 2. 3.)
  - Empty bullets/numbers disappear on double-enter
- **One Entry Per Day:** Loads existing or creates new

### ☁️ Cloud Sync
- **Storage:** Firebase Firestore
- **Structure:** `/users/{userId}/entries/{YYYY-MM-DD}`
- **Security:** Firestore rules ensure users only access their own data
- **Auto-sync:** Saves on checkmark tap
- **Network Monitoring:** Auto-syncs when connection available

## Architecture Patterns

### State Management
- **Singleton Services:** AuthenticationManager, FirestoreSyncManager
- **@StateObject:** For view-owned observable objects
- **@State:** For view-local UI state
- **@Published:** For reactive properties in services

### Navigation
- **State-based:** Boolean flags control view visibility
- **Animations:** `.easeInOut(duration: 0.5)` for transitions
- **Matched Geometry:** Circle animates from auth → home → breathe

### Data Flow
1. **Local First:** All data saved to SwiftData immediately
2. **Cloud Backup:** Synced to Firestore after local save
3. **Read:** Try local first, fall back to cloud if needed

## File Organization

```
Goodnight Journal/
├── App Entry
│   └── Goodnight_JournalApp.swift
│
├── Main Views (alphabetical)
│   ├── BreatheView.swift
│   ├── ContentView.swift
│   └── JournalView.swift
│
├── Views/ (organized screens)
│   ├── AuthenticationView.swift
│   └── HomeView.swift
│
├── Services/
│   ├── AuthenticationManager.swift
│   └── FirestoreSyncManager.swift
│
├── Models/
│   └── JournalEntry.swift
│
├── Assets.xcassets/
│   └── AppIcon, Colors
│
└── Supporting Files
    ├── quotes.json
    └── GoogleService-Info.plist
```

## Testing Quick Start

### Run the App
1. Open `Goodnight Journal.xcodeproj` in Xcode
2. Select target device (iPhone)
3. Press Cmd+R to run

### Test Authentication
1. Tap "Sign in with Apple" or "Continue with Google"
2. Complete sign-in flow
3. Should land on HomeView with quote

### Test Breathing
1. From HomeView, tap "Start"
2. Watch circle breathe (4 cycles, ~45 seconds)
3. Can skip with right arrow
4. Can go back with left arrow

### Test Journaling
1. Complete breathing or skip to journal
2. Type in text editor
3. Test list features (`- ` → `• `, numbered lists)
4. Tap checkmark to save
5. Restart app, should load saved entry

## Common Tasks

### Add a New Color
```swift
// Use native SwiftUI colors
Color.white
Color.black
Color(white: 0.16)  // for grays
Color.red.opacity(0.5)  // with transparency
```

### Modify Breathing Pattern
In `BreatheView.swift`:
```swift
let inhaleDuration: Double = 5.0  // seconds
let exhaleDuration: Double = 6.0  // seconds
let totalCycles: Int = 4          // number of cycles
```

### Change Button Style
```swift
.frame(height: 44)           // touch target
.background(Color(white: 0.16))  // dark gray
.cornerRadius(22)            // pill shape
```

### Add New Quote
Edit `quotes.json`:
```json
{"text": "Your new quote here"}
```

## Security Notes

### Firestore Rules
- Users can only read/write their own data
- All access requires authentication
- Entry userId must match authenticated user

### Local Storage
- SwiftData stores encrypted on device
- Automatic iCloud backup (if enabled)
- Secure by default

### Authentication
- Tokens managed by Firebase SDK
- No passwords stored locally
- Secure nonce for Apple Sign In

## Performance Tips

1. **Images:** None currently, but compress if adding
2. **Animations:** Already optimized at 0.5-1.5s
3. **Lists:** Not paginated (assumes reasonable # of entries)
4. **Sync:** Happens in background, non-blocking

## Troubleshooting

### Build Errors
- Clean build folder: Cmd+Shift+K
- Reset package dependencies
- Check `GoogleService-Info.plist` is in project

### Auth Not Working
- Verify Firebase configuration
- Check bundle ID matches Firebase console
- Enable auth methods in Firebase console

### Sync Not Working
- Check Firestore rules are deployed
- Verify network connection
- Check console for error messages

---

**Last Updated:** January 15, 2026
**Version:** 1.0
**Swift Version:** 5.9+
**iOS Target:** 17.0+
