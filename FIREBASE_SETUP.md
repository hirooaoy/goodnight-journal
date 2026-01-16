# Firebase Setup Instructions

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter project name: **Goodnight Journal**
4. Disable Google Analytics (for privacy) or keep it if you want basic analytics
5. Click "Create project"

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click the iOS icon to add an iOS app
2. Enter your iOS bundle ID (found in Xcode: Target → General → Bundle Identifier)
   - Example: `com.yourname.GoodnightJournal`
3. App nickname (optional): Goodnight Journal
4. App Store ID (optional, leave blank for now)
5. Click "Register app"

## Step 3: Download Configuration File

1. Download the `GoogleService-Info.plist` file
2. **IMPORTANT:** Drag this file into your Xcode project
   - Make sure "Copy items if needed" is checked
   - Add to target: Goodnight Journal
3. Place it in: `/Users/haoyama/Desktop/Developer/Goodnight Journal/Goodnight Journal/`

## Step 4: Enable Authentication Methods

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Apple** sign-in:
   - Click on Apple
   - Toggle "Enable"
   - Click "Save"
3. Enable **Google** sign-in:
   - Click on Google
   - Toggle "Enable"
   - Enter project support email
   - Click "Save"

## Step 5: Configure Apple Sign-In in Xcode

1. In Xcode, select your project in the navigator
2. Select your target: **Goodnight Journal**
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** button
5. Add **Sign in with Apple**

## Step 6: Setup Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Start in **production mode** (we'll add custom rules)
4. Choose a location (closest to your users, e.g., `us-central`)
5. Click **Enable**

## Step 7: Add Firestore Security Rules

In Firebase Console → Firestore Database → Rules, replace with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User's journal entries
      match /entries/{entryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

Click **Publish**

## Step 8: Add Firebase SDK to Xcode

**Part A: Firebase SDK**

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Version: Up to Next Major Version (11.0.0 or latest)
4. Click **Add Package**
5. Select these libraries to add:
   - **FirebaseAuth**
   - **FirebaseFirestore**
6. Click **Add Package**

**Part B: Google Sign-In SDK**

7. Go to **File** → **Add Package Dependencies** again
8. Enter URL: `https://github.com/google/GoogleSignIn-iOS`
9. Version: Up to Next Major Version (7.0.0 or latest)
10. Select library:
    - **GoogleSignIn**
11. Click **Add Package**

## Step 9: Configure URL Schemes for Google Sign-In

1. In Xcode project navigator, open `GoogleService-Info.plist`
2. Find `REVERSED_CLIENT_ID` value (looks like: `com.googleusercontent.apps.123456-abc`)
3. In Xcode, select your project → Target → Info tab
4. Expand **URL Types** section
5. Click **+** to add a new URL Type
6. Set **URL Schemes** to the `REVERSED_CLIENT_ID` value from step 2

## Step 10: Build and Test!

You're all set! Build and run the app.

---

## Firestore Data Structure

Your data will be organized as:

```
users/
  {userId}/
    entries/
      {YYYY-MM-DD}/
        id: string
        date: timestamp
        poemContent: string
        letters: [string]
        journalContent: string
        lastModified: timestamp
        userId: string
```

---

## Privacy & Security

- ✅ All data is encrypted in transit and at rest
- ✅ Firestore rules ensure users can only access their own data
- ✅ No server-side code reads or processes journal entries
- ✅ Authentication is handled securely by Firebase
- ✅ Offline data is stored locally with SwiftData and auto-syncs when online

---

## Next Steps After Setup

After completing Firebase setup, you can:
1. Test sign-in with Apple ID
2. Test sign-in with Google
3. Create a journal entry
4. Verify it saves and syncs to Firestore Console
5. Test offline mode (turn off wifi, write entry, turn on wifi)

