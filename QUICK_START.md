# 🚀 Quick Start Guide - Goodnight Journal

## What's Been Added

Your app now has:
- ✅ **Apple Sign-In** & **Google Sign-In**
- ✅ **Local storage** with SwiftData (works offline)
- ✅ **Cloud sync** with Firebase Firestore
- ✅ **Auto-sync** when network is available
- ✅ **One journal per day** with edit capability
- ✅ **Privacy-first** with secure data storage

---

## 🎯 Quick Setup (15-20 minutes)

### Step 1: Install Firebase SDK

**Part A: Add Firebase SDK**

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies**
3. Paste this URL: `https://github.com/firebase/firebase-ios-sdk`
4. Version: "Up to Next Major Version" → `11.0.0`
5. Select these packages:
   - ✅ `FirebaseAuth`
   - ✅ `FirebaseFirestore`
6. Click **Add Package**

**Part B: Add Google Sign-In SDK**

7. Go to **File → Add Package Dependencies** again
8. Paste this URL: `https://github.com/google/GoogleSignIn-iOS`
9. Version: "Up to Next Major Version" → `7.0.0`
10. Select package:
    - ✅ `GoogleSignIn`
11. Click **Add Package**

### Step 2: Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **"Add project"**
3. Name: `Goodnight Journal`
4. Disable/Enable Google Analytics (your choice)
5. Click **"Create project"**

### Step 3: Add iOS App to Firebase

1. In Firebase Console, click the **iOS icon** (⊕)
2. **iOS bundle ID:** Get from Xcode → Target → General
   - Example: `com.yourname.GoodnightJournal`
3. **App nickname:** `Goodnight Journal` (optional)
4. Click **"Register app"**
5. **Download** `GoogleService-Info.plist`
6. **Drag** this file into Xcode project:
   - Location: `Goodnight Journal` folder (same level as `ContentView.swift`)
   - ✅ Check "Copy items if needed"
   - ✅ Add to target: Goodnight Journal

### Step 4: Enable Sign-In Methods

1. In Firebase Console → **Authentication** → **Sign-in method**
2. Enable **Apple:**
   - Click "Apple" → Toggle "Enable" → Save
3. Enable **Google:**
   - Click "Google" → Toggle "Enable"
   - Enter your support email → Save

### Step 5: Configure Xcode for Apple Sign-In

1. In Xcode, select your **project** (top of navigator)
2. Select your **target** → **Signing & Capabilities** tab
3. Click **"+ Capability"**
4. Add **"Sign in with Apple"**

### Step 6: Configure Google Sign-In URL Scheme

1. Open the `GoogleService-Info.plist` you added to Xcode
2. Find the **`REVERSED_CLIENT_ID`** value
   - Looks like: `com.googleusercontent.apps.123456789-abc123`
3. Copy this value
4. In Xcode: Target → **Info** tab
5. Expand **"URL Types"**
6. Click **"+"** to add new
7. **URL Schemes:** Paste the `REVERSED_CLIENT_ID` value

### Step 7: Setup Firestore Database

1. In Firebase Console → **Firestore Database**
2. Click **"Create database"**
3. Choose **"Start in production mode"**
4. Select **location** (e.g., `us-central1`)
5. Click **"Enable"**
6. Go to **"Rules"** tab
7. Copy-paste rules from `firestore.rules` file (in your project)
8. Click **"Publish"**

### Step 8: Build & Run! 🎉

1. In Xcode, select a simulator or device
2. Press **⌘ + R** to build and run
3. Sign in with Apple or Google
4. Complete breathing exercise
5. Write a journal entry
6. Tap ✓ to save
7. Check Firebase Console → Firestore to see your entry!

---

## 🧪 Testing Checklist

- [ ] Sign in with Apple works
- [ ] Sign in with Google works
- [ ] Create journal entry
- [ ] Entry appears in Firestore Console
- [ ] Close app, reopen → still signed in
- [ ] Edit today's entry → changes save
- [ ] Turn off WiFi → write entry → still saves locally
- [ ] Turn on WiFi → entry syncs to cloud

---

## 📁 Project Structure

```
Goodnight Journal/
├── Models/
│   └── JournalEntry.swift              ← Data model
├── Services/
│   ├── AuthenticationManager.swift     ← Auth logic
│   └── FirestoreSyncManager.swift      ← Sync logic
├── Views/
│   ├── AuthenticationView.swift        ← Sign-in screen
│   ├── ContentView.swift               ← Home screen
│   ├── BreatheView.swift               ← Breathing exercise
│   └── JournalView.swift               ← Journal editor
├── Goodnight_JournalApp.swift          ← App entry point
└── GoogleService-Info.plist            ← Firebase config (YOU ADD THIS)
```

---

## 🔍 Verify Setup

### Check Firebase Console:
1. **Authentication** → Users tab should show user after sign-in
2. **Firestore** → Data tab should show:
   ```
   users → {userId} → entries → {date} → journal data
   ```

### Check Xcode:
- [ ] `GoogleService-Info.plist` in project
- [ ] Firebase packages installed
- [ ] "Sign in with Apple" capability enabled
- [ ] URL Types includes `REVERSED_CLIENT_ID`

---

## ⚠️ Common Issues

### "Cannot find FirebaseAuth in scope"
→ Firebase SDK not installed. Go to File → Add Package Dependencies

### "No GoogleService-Info.plist found"
→ Make sure file is dragged into Xcode project with "Copy items if needed" checked

### Apple Sign-In button doesn't work
→ Check "Sign in with Apple" capability is enabled in Xcode

### Google Sign-In fails
→ Verify URL scheme matches `REVERSED_CLIENT_ID` from plist

### Build errors about missing modules
→ Clean build folder (Cmd + Shift + K) and rebuild

---

## 📚 Documentation Files

- **`FIREBASE_SETUP.md`** - Detailed setup instructions
- **`IMPLEMENTATION_SUMMARY.md`** - Technical details & architecture
- **`firestore.rules`** - Security rules for Firestore
- **`QUICK_START.md`** (this file) - Fast setup guide

---

## 🎨 Features Implemented

| Feature | Status |
|---------|--------|
| Apple Sign-In | ✅ |
| Google Sign-In | ✅ |
| Local storage (SwiftData) | ✅ |
| Cloud sync (Firestore) | ✅ |
| Offline support | ✅ |
| Auto-sync when online | ✅ |
| One entry per day | ✅ |
| Edit existing entries | ✅ |
| Save confirmation | ✅ |
| Privacy-first UI | ✅ |

---

## 🚀 Next Steps (Future)

You can add later:
- [ ] Browse past entries (calendar/list)
- [ ] Search entries
- [ ] Export to PDF/text
- [ ] Settings screen
- [ ] Delete account option
- [ ] Web version (Firebase is ready!)

---

## 💡 Tips

1. **Test on real device** for Apple Sign-In (simulator sometimes has issues)
2. **Check Firestore Console** to verify data syncs
3. **Test offline mode** to ensure local storage works
4. **Security rules** prevent unauthorized access - don't skip this!
5. **Bundle ID** must match exactly between Xcode and Firebase

---

## 🎉 You're Done!

Once setup is complete, your app is ready for:
- ✅ Production use
- ✅ TestFlight distribution
- ✅ App Store submission
- ✅ Future web expansion

**Have fun journaling!** 🌙✨
