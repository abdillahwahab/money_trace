Money Tracer - Minimal Android-only Flutter app

This repository contains a minimal Flutter app that implements transaction recording per project requirements:
- Transaction list ordered by date (newest on top)
- Visible balance at top (IDR)
- Add transactions with fields: Date, Rekening Sumber, Type (in/out), Nominal (IDR), Category, Catatan

Important constraints (project policy):
- Android-only: app targets Android.
- Docker-only local runs: do NOT run Flutter, Gradle, emulator, or Android tooling on the host. Use Docker.
- APK output acceptable if you don't want to run a container locally.
- Android Studio is forbidden.

## Building APK

### Method 1: GitHub Actions (Recommended for Apple Silicon/M1/M2 Macs)

The easiest way to build the APK is using GitHub Actions:

1. Push your code to GitHub:
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/money_tracer.git
git push -u origin main
```

2. The build will start automatically. Go to:
   - Your repo on GitHub → **Actions** tab
   - Click the latest workflow run
   - Wait ~2-3 minutes for the build to complete
   - Download the APK from **Artifacts** section

3. Or manually trigger a build:
   - Go to **Actions** → **Build Android APK** workflow
   - Click **Run workflow** → **Run workflow**

### Method 2: Local Docker build (x86_64 hosts only)

**Note:** This method does NOT work on Apple Silicon (M1/M2/M3) Macs due to architecture incompatibility. Use Method 1 instead.

```bash
# For Intel/AMD x86_64 systems only
bash scripts/build_and_install.sh
```

## Installing APK

After downloading the APK (from GitHub Actions or local build):

### Option A: Via USB and adb
```bash
# Install adb if needed (without Android Studio)
brew install android-platform-tools

# Connect device via USB (enable USB debugging)
adb devices

# Install APK
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Option B: Direct install on device
1. Transfer APK to your Android device (email, cloud, USB)
2. On device: enable "Install unknown apps" for your file manager
3. Open the APK file and install

## App Features

- Launch the app on an Android device
- The main screen shows the current balance (IDR) and a list of transactions (newest first)
- Tap **+** to add a transaction
- Fill: Date, Rekening Sumber, Type (in/out), Nominal (IDR), Category, Catatan
- Swipe left on any transaction to delete

## Development

All development and builds must happen inside Docker containers or via CI (GitHub Actions). Do not install Flutter, Android SDK, or Android Studio on your local machine per project policy.

