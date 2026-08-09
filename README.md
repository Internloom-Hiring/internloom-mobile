# InternLoom Mobile — Developer & Build Guide

This guide provides step-by-step instructions for setting up, running, testing, and building the **InternLoom Mobile Flutter application** locally. It also explains how to generate and install an Android APK on a physical device.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1 — Environment Setup](#step-1--environment-setup)
3. [Step 2 — Running Locally](#step-2--running-locally)

   * [Option A — Android Emulator](#option-a--android-emulator)
   * [Option B — Physical Android Phone](#option-b--physical-android-phone)
4. [Step 3 — Building the Release APK](#step-3--building-the-release-apk)
5. [Step 4 — Installing the APK](#step-4--installing-the-apk-on-a-phone)

   * [Method 1 — ADB](#method-1--direct-usb-installation-via-adb)
   * [Method 2 — Manual Transfer](#method-2--manual-download--transfer)
6. [Troubleshooting](#troubleshooting-quick-reference)

---

# Prerequisites

Before starting, ensure your development machine has the following installed:

| Requirement                   | Version / Configuration                       |
| ----------------------------- | --------------------------------------------- |
| **Flutter SDK**               | 3.44.x or higher                              |
| **Dart**                      | 3.12.x or higher                              |
| **Android Studio**            | Latest stable version recommended             |
| **Android SDK**               | Platform 36 (API 36)                          |
| **JDK**                       | Version 17                                    |
| **Android Device / Emulator** | Android device with Developer Options enabled |

### Verify Flutter

Run:

```powershell
flutter --version
```

You should see a Flutter version compatible with the project requirements.

### Verify Java

Run:

```powershell
java -version
```

The project requires **JDK 17**.

### Verify Android Toolchain

Run:

```powershell
flutter doctor
```

Resolve any issues marked with a red `X` before continuing.

---

# Step 1 — Environment Setup

## 1. Clone the Repository

Clone the project repository:

```powershell
git clone <repository-url>
```

Navigate into the project directory:

```powershell
cd <folder name>
```

The project structure should look approximately like:

```text
<foldername>/
│
├── android/
├── assets/
├── ios/
├── lib/
├── test/
├── .env
├── pubspec.yaml
└── README.md
```

---

## 2. Configure Environment Variables

The application requires Supabase credentials.

Create a file named:

```text
.env
```

in the **project root**, at the same level as `pubspec.yaml`.

Example:

```env
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

### Important

Do **not** commit the `.env` file to Git.

Make sure `.env` is included in `.gitignore`:

```gitignore
.env
```

If the project uses environment variables as Flutter assets, verify that the `.env` file is also configured correctly in `pubspec.yaml`.

---

## 3. Install Flutter Dependencies

Run:

```powershell
flutter pub get
```

This downloads all dependencies specified in `pubspec.yaml`.

---

## 4. Verify the Project

Run:

```powershell
flutter analyze
```

If there are no blocking errors, the project is ready to run.

---

# Step 2 — Running Locally

The application can be run either on an Android emulator or a physical Android phone.

---

## Option A — Android Emulator

### 1. List Available Emulators

Run:

```powershell
flutter emulators
```

Example output:

```text
2 available emulators:

Pixel_7_API_34
Pixel_6_API_35
```

---

### 2. Launch an Emulator

Replace the emulator ID with the one available on your system:

```powershell
flutter emulators --launch Pixel_7_API_34
```

Wait until Android finishes booting.

---

### 3. Verify the Emulator

Run:

```powershell
flutter devices
```

The emulator should appear in the list.

Example:

```text
Pixel_7_API_34 • emulator-5554 • android-x64 • Android 14
```

---

### 4. Run the Application

Run:

```powershell
flutter run
```

Flutter will automatically select the connected emulator.

If multiple devices are connected, specify the device:

```powershell
flutter run -d <device-id>
```

---

# Option B — Physical Android Phone

## 1. Enable Developer Options

On your Android phone:

1. Open **Settings**.
2. Go to **About Phone**.
3. Find **Build Number**.
4. Tap **Build Number** approximately **7 times**.
5. Android will display a message indicating that Developer Options have been enabled.

The exact location can vary depending on the phone manufacturer.

---

## 2. Enable USB Debugging

Open:

```text
Settings
→ System
→ Developer Options
→ USB Debugging
```

Enable **USB Debugging**.

Some manufacturers may place Developer Options under:

```text
Settings
→ Additional Settings
→ Developer Options
```

---

## 3. Connect the Phone

Connect the phone to the computer using a USB cable.

If the phone displays:

> Allow USB debugging?

Select:

**Allow**

You can optionally select:

**Always allow from this computer**

---

## 4. Verify Device Connection

Run:

```powershell
flutter devices
```

Your phone should appear in the device list.

Example:

```text
SM-S921B • R5XXXXXXXXX • android-arm64 • Android 15
```

---

## 5. Run the Application

Run:

```powershell
flutter run
```

If multiple devices are connected:

```powershell
flutter run -d <device-id>
```

Flutter will install the debug version of the application on the phone.

---

# Step 3 — Building the Release APK

A release APK can be generated for testing and direct installation on Android devices.

## 1. Clean Previous Build Artifacts

Run:

```powershell
flutter clean
```

Then reinstall dependencies:

```powershell
flutter pub get
```

---

## 2. Generate the Release APK

Run:

```powershell
flutter build apk --release
```

Flutter will compile the application in release mode.

---

## 3. Locate the APK

After a successful build, the APK will be available at:

```text
build\app\outputs\flutter-apk\app-release.apk
```

This is the APK that can be transferred to an Android phone.

---

## Building Split APKs

If smaller APK files are required for individual CPU architectures, use:

```powershell
flutter build apk --split-per-abi
```

The generated files will typically be located in:

```text
build\app\outputs\flutter-apk\
```

You may see files such as:

```text
app-armeabi-v7a-release.apk
app-arm64-v8a-release.apk
app-x86_64-release.apk
```

### Which APK should be used?

For most modern physical Android phones, use:

```text
app-arm64-v8a-release.apk
```

If compatibility with different Android devices is more important than APK size, use the universal APK generated by:

```powershell
flutter build apk --release
```

---

# Step 4 — Installing the APK on a Phone

There are two common methods.

---

# Method 1 — Direct USB Installation via ADB

This is the fastest method when the phone is connected to the computer.

## 1. Verify ADB

Run:

```powershell
adb devices
```

Your phone should appear:

```text
List of devices attached
R5XXXXXXXXX    device
```

If the device shows:

```text
unauthorized
```

unlock your phone and accept the USB debugging prompt.

---

## 2. Install the APK

Run:

```powershell
adb install build\app\outputs\flutter-apk\app-release.apk
```

If an older version is already installed, you may need to uninstall it first:

```powershell
adb uninstall <package-name>
```

Then install the release APK again:

```powershell
adb install build\app\outputs\flutter-apk\app-release.apk
```

---

# Method 2 — Manual Download & Transfer

## 1. Transfer the APK to the Phone

### Option A — USB File Transfer

1. Connect the phone to the computer.
2. Select **File Transfer / MTP** on the phone.
3. Open the phone's storage from Windows File Explorer.
4. Copy:

```text
app-release.apk
```

to:

```text
Downloads/
```

---

### Option B — Wireless / Cloud Transfer

Upload the APK to a service such as:

* Google Drive
* OneDrive
* Slack
* WhatsApp
* Other trusted file-transfer services

Download the APK onto the phone.

---

## 2. Install the APK

On the Android phone:

1. Open **Files / My Files**.
2. Navigate to the **Downloads** folder.
3. Tap:

```text
app-release.apk
```

4. Android may display:

> For your security, your phone is not allowed to install unknown apps from this source.

If this happens:

1. Tap **Settings**.
2. Enable **Allow from this source**.
3. Press **Back**.
4. Tap **Install**.

After installation, open:

**InternLoom**

and begin testing.

---

# Troubleshooting Quick Reference

| Issue                                           | Solution                                                                                                         |
| ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `No file or variants found for asset: .env`     | Create `.env` in the project root and run `flutter clean` followed by `flutter pub get`.                         |
| `requires compileSdk 36`                        | Ensure Android is configured to compile against SDK 36.                                                          |
| `flutter: command not found`                    | Add the Flutter SDK's `bin` directory to the system PATH.                                                        |
| `adb is not recognized`                         | Install Android SDK Platform Tools and add its directory to PATH.                                                |
| Phone does not appear in `flutter devices`      | Enable USB Debugging, reconnect the USB cable, and accept the debugging authorization prompt.                    |
| Device shows `unauthorized` in `adb devices`    | Unlock the phone and accept the USB debugging authorization prompt.                                              |
| `No devices found`                              | Start an emulator or connect a physical Android device.                                                          |
| `App Not Installed`                             | Uninstall the existing version and install the release APK again.                                                |
| APK installation is blocked                     | Enable **Allow from this source** for the application used to open the APK.                                      |
| `flutter pub get` fails                         | Check Flutter/Dart versions with `flutter --version` and verify network connectivity.                            |
| Build fails after dependency changes            | Run `flutter clean`, then `flutter pub get`, and rebuild.                                                        |
| `Gradle` build errors                           | Verify JDK 17 and the Android Gradle/Gradle versions required by the project's Flutter version.                  |
| `.env` changes are not detected                 | Restart the Flutter build after modifying `.env`; run `flutter clean` if necessary.                              |
| Release APK builds but authentication fails     | Verify the release build has the required Supabase configuration and OAuth redirect configuration.               |
| Google/Apple OAuth does not work in release APK | Verify the Android OAuth redirect configuration, package/application ID, and provider configuration in Supabase. |

---

# Useful Flutter Commands

## Check Flutter Installation

```powershell
flutter doctor
```

## Check Flutter Version

```powershell
flutter --version
```

## List Connected Devices

```powershell
flutter devices
```

## List Emulators

```powershell
flutter emulators
```

## Launch Emulator

```powershell
flutter emulators --launch <emulator-id>
```

## Install Dependencies

```powershell
flutter pub get
```

## Analyze Project

```powershell
flutter analyze
```

## Run Application

```powershell
flutter run
```

## Clean Project

```powershell
flutter clean
```

## Build Debug APK

```powershell
flutter build apk --debug
```

## Build Release APK

```powershell
flutter build apk --release
```

## Build Split Release APKs

```powershell
flutter build apk --split-per-abi
```

## Install APK Through ADB

```powershell
adb install build\app\outputs\flutter-apk\app-release.apk
```

---

# Recommended Development Workflow

For normal development, use the following workflow:

```text
Clone Repository
       ↓
Create .env
       ↓
flutter pub get
       ↓
flutter doctor
       ↓
Connect Device / Start Emulator
       ↓
flutter devices
       ↓
flutter run
       ↓
Develop & Test
       ↓
flutter analyze
       ↓
flutter clean
       ↓
flutter pub get
       ↓
flutter build apk --release
       ↓
Test app-release.apk
```

---

# Important Notes

### 1. Do Not Commit Secrets

Never commit:

```text
.env
```

or any file containing private API keys, service-role keys, passwords, or other credentials.

The Supabase **anon/publishable key** is intended for client-side use, but the Supabase **service-role key must never be included in the Flutter application**.

### 2. Debug vs Release

`flutter run` normally runs the application in **debug mode**.

For testing the application in conditions closer to a distributed Android application, build and test:

```powershell
flutter build apk --release
```

### 3. Rebuild After Configuration Changes

After changing important Android configuration, environment variables, dependencies, or assets, it is often useful to run:

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

### 4. Keep Flutter and Android Versions Consistent

All developers working on the project should preferably use the same:

* Flutter version
* Dart version
* JDK version
* Android SDK version

This reduces environment-specific build errors.

---

# APK Output

The standard release APK is located at:

```text
build\app\outputs\flutter-apk\app-release.apk
```

This file can be:

* Installed using ADB
* Copied to an Android phone
* Uploaded to a trusted file-sharing service
* Used for internal testing

---

# Quick Start

For an already configured development machine, the minimum commands are:

```powershell
git clone <repository-url>
cd <folder name>

flutter pub get
flutter devices
flutter run
```

To generate the release APK:

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

APK location:

```text
build\app\outputs\flutter-apk\app-release.apk
```
