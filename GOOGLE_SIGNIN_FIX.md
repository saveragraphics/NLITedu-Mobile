# Solving Google Sign-In Error (10) in NLIT Mobile App

The `Google Sign-In Error (10)` is a security/developer error thrown when Google's OAuth server rejects a login request because the signing key of the installed app does not match the fingerprint registered in the **Firebase Console**.

Since you are running/building the app, you need to ensure the correct SHA fingerprints are added to Firebase under **Project Settings** > **Your Android App**.

---

## 1. The Exact SHA Fingerprints for Your Project

I have extracted the exact SHA-1 and SHA-256 fingerprints from your local environments to make this quick and easy. Simply copy and paste them directly into your Firebase Console!

### A. Debug Key (For Local Development & Running on Emulators/USB)
* **SHA-1 Fingerprint:**
  ```text
  E5:E3:21:D2:2E:F4:80:E0:9A:F7:51:C6:47:C2:19:4A:80:5E:20:DE
  ```
* **SHA-256 Fingerprint:**
  ```text
  4D:F5:CF:BB:FD:DF:0A:3F:1A:7D:28:8D:DB:ED:E2:6B:75:CF:27:97:EC:20:CD:6A:94:A4:41:46:13:8A:9C:BA
  ```

### B. Upload / Release Key (For local release builds or uploading to Play Store)
* **SHA-1 Fingerprint:**
  ```text
  E1:69:E4:04:3D:A8:22:AA:31:F3:1A:76:10:A2:EF:ED:51:52:37:69
  ```
* **SHA-256 Fingerprint:**
  ```text
  9A:53:51:AE:93:2D:37:F6:A5:6D:11:E2:FD:73:EA:3A:56:98:3E:B3:81:71:F7:46:13:10:48:68:F5:BC:4F:A6
  ```

---

## 2. Play Store App Signing Fingerprint (CRITICAL for Play Store Downloads)

If the app is downloaded from the **Google Play Store**, Google uses **Play App Signing** by default. This means Google automatically signs your app with a completely new **App Signing Key** managed on their servers. 

Your local debug/upload keys **will not** match the Play Store version! You must add the Play Store fingerprint to Firebase:

### How to get the Play Store Fingerprint:
1. Log in to the [Google Play Console](https://play.google.com/console/).
2. Select your **NLIT** App.
3. In the left-hand menu, navigate to **Release** > **Setup** > **App integrity**.
4. Go to the **App signing** tab.
5. Copy the **SHA-1 certificate fingerprint** and **SHA-256 certificate fingerprint** listed under the **"App signing key certificate"** section.
6. Add BOTH fingerprints to your **Firebase Console** under your Android App.

---

## 3. How to Add These Fingerprints in Firebase

1. Open the [Firebase Console](https://console.firebase.google.com/) and go to your **NLIT** project (`nlitedu-a4418`).
2. Click the Gear Icon ⚙️ next to Project Overview in the left panel and select **Project settings**.
3. Under the **General** tab, scroll down to the **"Your apps"** section and select the Android app (`com.nlitedu.app`).
4. Click **Add fingerprint**.
5. Paste the **SHA-1** and click **Save**.
6. Repeat the process to add **SHA-256** for extra security/stability.
7. **Important**: After adding a new fingerprint, download the updated `google-services.json` file and place it in the `android/app/` directory of your Flutter project, replacing the old one. Rebuild your app!
