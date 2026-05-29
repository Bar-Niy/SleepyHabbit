# Google Play Data Safety Declaration

This document describes how to fill out the Google Play Data Safety Form for SleepyHabbit.

## Overview

SleepyHabbit is a **privacy-first** app. All user data is stored locally on-device.
No data is transmitted to our servers because **we have no servers**.

---

## Data Safety Form Answers

### "Does your app collect or share any of the required user data types?"

**Answer: NO** — with caveats documented below.

---

### Data Types Breakdown

| Data Type | Collected? | Shared? | Notes |
|-----------|-----------|---------|-------|
| Location | No | No | Not used at all |
| Personal info (name) | Locally only | No | Stored in SharedPreferences on device |
| Health info (sleep) | Locally only | No | SQLite database on device |
| Audio (voice) | Locally only | No | Transcribed on-device, audio discarded |
| Photos (meals) | Locally only | No | Stored in app-private directory |
| App activity | No | No | No analytics, no crash reporting |
| Device info | No | No | No device fingerprinting |

---

### Network Communication

| Destination | When | What's sent | User control |
|-------------|------|-------------|--------------|
| Google Drive | User-initiated backup | Encrypted DB file | User must explicitly enable |
| Local LLM (localhost) | During conversations | Conversation text | Default, on-device only |
| External LLM (if configured) | During conversations | Conversation text | User must manually configure |

---

### Key Declarations for the Form

1. **"Is all of the user data collected by your app encrypted in transit?"**
   - For Google Drive: YES (HTTPS)
   - For local LLM: N/A (localhost, never leaves device)
   - For external LLM: depends on user config (we enforce HTTPS for public URLs)

2. **"Do you provide a way for users to request that their data is deleted?"**
   - YES: Settings → Clear Data (deletes all local data)
   - Uninstalling the app also removes all data

3. **"Does your app share user data with any third parties?"**
   - NO. We have no servers. Data only leaves the device when:
     a) User enables Google Drive backup (goes to THEIR account)
     b) User configures an external LLM API (their choice)

---

## Dependency Audit — No Tracking SDKs

These packages are confirmed to NOT collect or transmit user data:

| Package | Verdict | Reason |
|---------|---------|--------|
| flutter_riverpod | ✅ Safe | Pure state management, no network |
| go_router | ✅ Safe | Navigation only |
| drift / sqlite3_flutter_libs | ✅ Safe | Local database only |
| flutter_tts | ✅ Safe | On-device text-to-speech |
| speech_to_text | ⚠️ Note | Uses OS speech recognition (on-device on modern Android/iOS). May use Google servers on older devices — document this |
| image_picker | ✅ Safe | Local file access only |
| dio / http | ✅ Safe | HTTP client, doesn't phone home |
| google_sign_in | ⚠️ Note | Only activated when user initiates backup. Does communicate with Google OAuth servers — document this |
| googleapis | ⚠️ Note | Only used for Google Drive backup when user explicitly enables it |
| flutter_local_notifications | ✅ Safe | Local scheduling only |
| shared_preferences | ✅ Safe | Local key-value storage |
| path_provider | ✅ Safe | File system paths only |
| permission_handler | ✅ Safe | Permission management only |
| flutter_animate | ✅ Safe | UI animations only |
| intl | ✅ Safe | Date formatting only |
| uuid | ✅ Safe | Local UUID generation |

### Packages we intentionally DO NOT use:
- ❌ firebase_analytics
- ❌ firebase_crashlytics
- ❌ sentry
- ❌ amplitude
- ❌ mixpanel
- ❌ facebook_sdk
- ❌ google_analytics
- ❌ appsflyer
- ❌ adjust

---

## speech_to_text Disclosure

The `speech_to_text` package uses the OS-level speech recognition service:
- **Android 13+**: On-device speech recognition (no data leaves device)
- **Older Android**: May use Google's cloud speech recognition
- **iOS**: Uses Apple's on-device speech recognition

**Recommendation for Data Safety Form**: Declare that audio data MAY be
processed by OS speech recognition services on older Android versions.
Inform users in Privacy Policy (already done).

---

## Google Sign-In Disclosure

When users enable Google Drive backup:
- App requests `drive.file` scope only (limited to app-created files)
- OAuth tokens are managed by the Google Sign-In SDK
- No user data is sent to OUR servers

**For Data Safety Form**: This counts as "data shared with Google" but only
when the user explicitly enables backup. Declare accordingly.
