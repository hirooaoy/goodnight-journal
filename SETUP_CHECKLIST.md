# ✅ Firebase Setup Checklist

Use this checklist to ensure everything is configured correctly before building the app.

---

## 🔥 Firebase Console Setup

### Create Firebase Project
- [ ] Go to [console.firebase.google.com](https://console.firebase.google.com)
- [ ] Click "Add project"
- [ ] Name: "Goodnight Journal"
- [ ] Google Analytics: Disabled or Enabled (your choice)
- [ ] Project created successfully

### Add iOS App
- [ ] Click iOS+ icon in Firebase Console
- [ ] iOS bundle ID entered (from Xcode)
- [ ] App nickname: "Goodnight Journal" (optional)
- [ ] Click "Register app"
- [ ] Download `GoogleService-Info.plist`
- [ ] `GoogleService-Info.plist` added to Xcode project
  - [ ] File is in project navigator
  - [ ] "Copy items if needed" was checked
  - [ ] Target "Goodnight Journal" is selected

### Enable Authentication
- [ ] Go to Authentication → Sign-in method
- [ ] Apple Sign-In:
  - [ ] Enabled ✅
  - [ ] Saved
- [ ] Google Sign-In:
  - [ ] Enabled ✅
  - [ ] Support email entered
  - [ ] Saved

### Create Firestore Database
- [ ] Go to Firestore Database
- [ ] Click "Create database"
- [ ] Mode: Production mode selected
- [ ] Location: Selected (e.g., us-central1)
- [ ] Database created successfully

### Add Security Rules
- [ ] Go to Firestore Database → Rules tab
- [ ] Copy rules from `firestore.rules` file
- [ ] Paste into Firebase Console
- [ ] Click "Publish"
- [ ] Rules published successfully

---

## 🛠️ Xcode Setup

### Install Firebase SDK
- [ ] In Xcode: File → Add Package Dependencies
- [ ] URL: `https://github.com/firebase/firebase-ios-sdk`
- [ ] Version: "Up to Next Major Version" → 11.0.0+
- [ ] Selected packages:
  - [ ] FirebaseAuth
  - [ ] FirebaseFirestore
- [ ] Click "Add Package"
- [ ] Firebase packages installed successfully

### Install Google Sign-In SDK
- [ ] In Xcode: File → Add Package Dependencies (again)
- [ ] URL: `https://github.com/google/GoogleSignIn-iOS`
- [ ] Version: "Up to Next Major Version" → 7.0.0+
- [ ] Selected package:
  - [ ] GoogleSignIn
- [ ] Click "Add Package"
- [ ] GoogleSignIn package installed successfully

### Configure App Capabilities
- [ ] Project selected in navigator
- [ ] Target: "Goodnight Journal" selected
- [ ] Go to "Signing & Capabilities" tab
- [ ] Click "+ Capability"
- [ ] Add "Sign in with Apple"
- [ ] Capability added successfully

### Configure Google Sign-In URL Scheme
- [ ] Open `GoogleService-Info.plist` in Xcode
- [ ] Find `REVERSED_CLIENT_ID` value
- [ ] Copy the value (looks like: `com.googleusercontent.apps.123456...`)
- [ ] Go to Target → Info tab
- [ ] Expand "URL Types" section
- [ ] Click "+" to add new URL Type
- [ ] Paste `REVERSED_CLIENT_ID` value into "URL Schemes"
- [ ] URL Type added successfully

### Verify Project Files
- [ ] `Models/JournalEntry.swift` exists
- [ ] `Services/AuthenticationManager.swift` exists
- [ ] `Services/FirestoreSyncManager.swift` exists
- [ ] `Views/AuthenticationView.swift` exists
- [ ] `Goodnight_JournalApp.swift` updated
- [ ] `JournalView.swift` updated
- [ ] `GoogleService-Info.plist` in project root

---

## 🧪 Build & Test

### Initial Build
- [ ] Select a simulator (iPhone 15 Pro or newer)
- [ ] Press ⌘+B to build
- [ ] Build succeeds with no errors
- [ ] If errors, check:
  - [ ] Firebase packages installed
  - [ ] `GoogleService-Info.plist` in project
  - [ ] All new files are in target
  - [ ] iOS Deployment Target is 17.0+

### Test Sign-In (Apple)
- [ ] Run app (⌘+R)
- [ ] Authentication screen appears
- [ ] Tap "Sign in with Apple"
- [ ] Apple sign-in sheet appears
- [ ] Complete sign-in
- [ ] App navigates to home screen
- [ ] Check Firebase Console → Authentication → Users
- [ ] New user appears in list ✅

### Test Sign-In (Google)
- [ ] Sign out (if needed)
- [ ] Tap "Continue with Google"
- [ ] Google sign-in sheet appears
- [ ] Select Google account
- [ ] Complete sign-in
- [ ] App navigates to home screen
- [ ] Check Firebase Console → Authentication → Users
- [ ] Google user appears in list ✅

### Test Journal Creation
- [ ] Complete breathing exercise
- [ ] Journal view appears
- [ ] Template text is pre-filled
- [ ] Three random letters appear (A-W, excluding Q,V,X,Y,Z)
- [ ] Can type in journal
- [ ] Tap ✓ (checkmark) to save
- [ ] "Saving" spinner appears briefly
- [ ] "Saved" confirmation alert appears
- [ ] Tap "OK"
- [ ] Returns to home screen

### Verify Firestore Data
- [ ] Go to Firebase Console → Firestore Database → Data
- [ ] See structure: `users/{userId}/entries/{date}`
- [ ] Click on today's date entry
- [ ] See fields:
  - [ ] id
  - [ ] date
  - [ ] poemContent
  - [ ] letters (array)
  - [ ] journalContent
  - [ ] lastModified
  - [ ] userId
- [ ] Data matches what you typed ✅

### Test Edit Existing Entry
- [ ] Run app again (same day)
- [ ] Complete breathing exercise
- [ ] Journal view loads previous entry ✅
- [ ] Can edit the text
- [ ] Save again
- [ ] Check Firestore - entry updated ✅

### Test Offline Mode
- [ ] Turn off WiFi on device/simulator
- [ ] Open app
- [ ] Create or edit journal entry
- [ ] Save (✓ button)
- [ ] Should save successfully (no error)
- [ ] Turn WiFi back on
- [ ] Wait 5-10 seconds
- [ ] Check Firestore Console
- [ ] Offline entry now appears ✅

### Test Persistence
- [ ] Close app completely
- [ ] Reopen app
- [ ] Should be signed in (no auth screen) ✅
- [ ] Should load today's entry if exists ✅

---

## 🔍 Troubleshooting

### Build Errors

#### "Cannot find 'FirebaseAuth' in scope"
- [ ] Firebase SDK not installed → Add packages again
- [ ] Clean build folder (⌘+Shift+K)
- [ ] Restart Xcode

#### "No such module 'GoogleSignIn'"
- [ ] GoogleSignIn not selected in package → Add it
- [ ] Clean build folder
- [ ] Rebuild

#### "GoogleService-Info.plist not found"
- [ ] File not in project → Drag it into Xcode
- [ ] Make sure "Copy items if needed" is checked
- [ ] Make sure target is selected

### Sign-In Errors

#### Apple Sign-In fails
- [ ] "Sign in with Apple" capability enabled?
- [ ] Test on real device (simulator can be flaky)
- [ ] Check Apple ID is signed in on device
- [ ] Firebase Apple auth is enabled?

#### Google Sign-In fails
- [ ] URL scheme configured correctly?
- [ ] `REVERSED_CLIENT_ID` matches plist?
- [ ] Google auth enabled in Firebase?
- [ ] Support email set in Firebase?

### Sync Errors

#### Data doesn't appear in Firestore
- [ ] Firestore database created?
- [ ] Security rules published?
- [ ] Network connection active?
- [ ] Check Xcode console for errors

#### "Permission denied" errors
- [ ] Security rules published correctly?
- [ ] User is authenticated?
- [ ] userId matches in rules?

---

## 📱 Device Testing Recommendations

### Test on Real Device
- [ ] Apple Sign-In works better on real device
- [ ] Biometric auth (Face ID/Touch ID) feels native
- [ ] Network switching (WiFi/Cellular) more realistic

### Test on Multiple iOS Versions
- [ ] iOS 17.0 (minimum supported)
- [ ] iOS 17.5+ (latest stable)
- [ ] iOS 18.0 beta (if applicable)

---

## 🎯 Success Criteria

All of these should work:

- [ ] ✅ Sign in with Apple works
- [ ] ✅ Sign in with Google works
- [ ] ✅ Create journal entry
- [ ] ✅ Entry appears in Firestore
- [ ] ✅ Edit entry persists
- [ ] ✅ Offline save works
- [ ] ✅ Auto-sync when back online
- [ ] ✅ Close/reopen stays signed in
- [ ] ✅ One entry per day enforced
- [ ] ✅ UI matches original design

---

## 🚀 Ready to Ship?

### Pre-Launch Checklist

- [ ] All tests pass ✅
- [ ] Firestore rules secure ✅
- [ ] Bundle ID matches production
- [ ] App icons added
- [ ] Launch screens configured
- [ ] Privacy policy (if submitting to App Store)
- [ ] Terms of service (if needed)
- [ ] App Store screenshots
- [ ] App description
- [ ] Keywords for ASO

---

## 📞 Need Help?

If stuck, check in this order:

1. [ ] This checklist - did I miss a step?
2. [ ] `QUICK_START.md` - step-by-step guide
3. [ ] Xcode console - what's the error?
4. [ ] Firebase Console - configuration correct?
5. [ ] `IMPLEMENTATION_SUMMARY.md` - technical details
6. [ ] Clean build folder + restart Xcode
7. [ ] Delete derived data + reinstall packages

---

## 🎊 All Done?

If all checkboxes are ✅, you're ready!

**Your app is production-ready for:**
- ✅ TestFlight beta testing
- ✅ App Store submission
- ✅ Real user journaling

**Next step:** Add app icon, screenshots, and ship! 🚀

---

**Last updated:** January 15, 2026
