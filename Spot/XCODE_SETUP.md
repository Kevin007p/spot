# Xcode Project Setup Guide

Since the source files were created on Linux, you'll need to create the Xcode project on your Mac and import these files.

## Prerequisites

1. **macOS** (Ventura 13.5+ recommended)
2. **Xcode 15+** — Download from the Mac App Store (free)
3. **Apple ID** — You'll need one for Xcode (free, no developer account needed to run in Simulator)

## Step 1: Create the Xcode Project

1. Open Xcode
2. Click **Create New Project** (or File → New → Project)
3. Select **iOS** → **App** → Next
4. Fill in:
   - **Product Name:** `Spot`
   - **Team:** Your personal team (or None)
   - **Organization Identifier:** `com.yourname` (e.g. `com.johndoe`)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** SwiftData
5. Click **Next**, choose a location (NOT inside the MySavedPlaces/Spot folder — create it somewhere fresh)
6. Click **Create**

## Step 2: Replace the Generated Files

1. In Finder, open the Xcode project folder — you'll see a `Spot/` folder inside it
2. **Delete** the auto-generated `SpotApp.swift` and `ContentView.swift` from the Xcode project folder
3. **Copy** all files from `MySavedPlaces/Spot/Spot/` into the Xcode project's `Spot/` folder:
   - `SpotApp.swift`
   - `Models/` folder
   - `Views/` folder
   - `ViewModels/` folder
   - `Services/` folder
   - `Theme/` folder
   - `Extensions/` folder
   - `Info.plist`
4. Copy the `Resources/Assets.xcassets/` contents (AccentColor, AppIcon) into the existing Assets.xcassets in the Xcode project

## Step 3: Add Files to Xcode

1. In Xcode, right-click the `Spot` folder in the Project Navigator (left sidebar)
2. Select **Add Files to "Spot"...**
3. Select all the folders you just copied (Models, Views, ViewModels, Services, Theme, Extensions)
4. Make sure **"Copy items if needed"** is UNCHECKED (files are already in place)
5. Make sure **"Create groups"** is selected
6. Click **Add**

## Step 4: Add Swift Package Dependencies

1. In Xcode, click on the **Spot** project (blue icon) in the Project Navigator
2. Select the **Spot** project (not target) in the center panel
3. Click the **Package Dependencies** tab
4. Click the **+** button to add packages:

### Supabase Swift SDK
- URL: `https://github.com/supabase/supabase-swift`
- Dependency Rule: **Up to Next Major Version** → `2.0.0`
- Click **Add Package**
- When prompted, add the **Supabase** library to the Spot target

### Google Sign-In
- URL: `https://github.com/google/GoogleSignIn-iOS`
- Dependency Rule: **Up to Next Major Version** → `7.0.0`
- Click **Add Package**
- When prompted, add **GoogleSignIn** and **GoogleSignInSwift** to the Spot target

## Step 5: Configure Signing

1. Click the **Spot** target in the project settings
2. Go to the **Signing & Capabilities** tab
3. Check **Automatically manage signing**
4. Select your **Team** (Personal Team is fine for Simulator testing)

## Step 6: Build & Run

1. Select **iPhone 15** (or any) Simulator from the device dropdown at the top
2. Press **Cmd + R** to build and run
3. The app should launch showing the onboarding screens

## Troubleshooting

- **"No such module"** errors: Make sure packages finished resolving (File → Packages → Resolve Package Versions)
- **Signing errors**: Make sure a team is selected in Signing & Capabilities
- **Build errors in Services/**: The Service files have `fatalError()` placeholders — this is expected until Supabase is configured in Phase 2
