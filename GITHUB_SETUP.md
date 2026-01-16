# GitHub Setup Guide for Goodnight Journal

## Step 1: Create a GitHub Repository

1. Go to [GitHub.com](https://github.com) and sign in (or create an account)
2. Click the **"+"** button in the top right corner
3. Select **"New repository"**
4. Fill in the details:
   - **Repository name:** `goodnight-journal`
   - **Description:** "A private and secure iOS journaling app with breathing exercises and ambient sounds"
   - **Visibility:** Choose "Public" (your legal docs need to be publicly accessible)
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
5. Click **"Create repository"**

## Step 2: Connect Your Local Repository to GitHub

After creating the repository, GitHub will show you commands. Use these commands in your terminal:

```bash
# Navigate to your project
cd "/Users/haoyama/Desktop/Developer/Goodnight Journal"

# Add the remote repository
git remote add origin https://github.com/hirooaoy/goodnight-journal.git

# Add all files
git add .

# Commit your changes
git commit -m "Initial commit: Goodnight Journal iOS app with Terms and Privacy Policy"

# Push to GitHub
git push -u origin main
```

## Step 3: Verify Your Legal Documents

After pushing, your legal documents will be available at:
- **Terms of Service:** `https://github.com/hirooaoy/goodnight-journal/blob/main/docs/terms-of-service.md`
- **Privacy Policy:** `https://github.com/hirooaoy/goodnight-journal/blob/main/docs/privacy-policy.md`

## Step 4: Update Links in Your App (Optional)

Once you have the GitHub URLs, you can update the AuthenticationView to include clickable links to these documents if desired.

## Important Security Notes

⚠️ **Before pushing to GitHub:**

1. **GoogleService-Info.plist** is already in .gitignore (good!)
2. **Never commit API keys or secrets**
3. Review the files being committed with `git status`

## Repository Settings Recommendations

After creating the repository:

1. **Add a LICENSE:** Consider MIT or Apache 2.0 license
2. **Add topics:** iOS, Swift, SwiftUI, Journal, Meditation
3. **Add a good README.md** describing the project
4. **Enable GitHub Pages** (optional) if you want web-hosted versions of your legal docs

## Keeping Your Repository Updated

```bash
# When you make changes
git add .
git commit -m "Description of changes"
git push
```

## Need Help?

If you encounter any issues:
- Check that you're signed in to GitHub
- Verify your GitHub username in the remote URL
- Make sure you have write access to the repository

---

**Ready to push?** Just follow the commands in Step 2!
