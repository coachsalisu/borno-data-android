# Borno Data — Android App (Capacitor project)

This wraps the existing Borno Data web app (`bornodata.com/app.html`) inside
a real native Android shell using [Capacitor](https://capacitorjs.com).
It talks to your existing live backend at `https://api.bornodata.com` — no
separate backend needed, it's the same one the website uses.

## Two ways to build this

**Path A — On a computer with Android Studio.** The traditional way. See
"Building on a computer" below.

**Path B — Entirely from your phone, using GitHub Actions.** GitHub's
free cloud servers do the actual building — you never touch Android
Studio. This gets you a real, installable test APK without owning a
computer. See "Building from your phone" below. (Getting a fully signed,
Play-Store-ready release still benefits from a computer at the final step
— see the note at the end of that section.)

---

## Building from your phone (GitHub Actions)

1. **Create a free GitHub account** at github.com, if you don't have one.
2. **Create a new repository** — tap the "+" icon → "New repository".
   Name it something like `borno-data-android`. Private or public both
   work.
3. **Upload this entire project into that repository.** On the repo page,
   tap "Add file" → "Upload files". Unzip the project first (most phone
   file manager apps can unzip), then select all the files and folders
   — including the hidden `.github` folder — and upload them. If your
   phone's file picker won't let you select a whole folder at once,
   upload the files one at a time; folder structure (like
   `.github/workflows/build-android.yml`) needs to end up at that exact
   path in the repo for the build to work.
4. Once everything is uploaded, go to the **"Actions" tab** on your repo.
   You should see "Build Android APK" listed. If it hasn't already started
   automatically, tap it, then tap **"Run workflow"**.
5. Wait a few minutes — GitHub's servers are doing the actual build.
6. When it finishes (green checkmark), tap into that run, scroll down to
   **"Artifacts"**, and download `borno-data-debug-apk`. That's a `.zip`
   containing `app-debug.apk` — extract it, and you have a real,
   installable Android app.
7. To install it on your own phone: you'll need to allow "Install unknown
   apps" for your browser/file manager in Android settings (Android shows
   this prompt automatically the first time you tap an APK file).

**This gets you a working test app you can actually use and show people.**
It is NOT yet what you'd submit to the Play Store — Play Store requires a
*signed release* build (an `.aab` file, cryptographically signed with a
private key only you hold), which is a separate, more careful step. That
signing step is realistically easier with a computer at hand even once,
since it involves generating and safely storing a keystore file. If you
get to that point, sending the project to a developer with a computer for
just that final signing-and-submit step is a reasonable way to finish.

---

## Building on a computer

## What you need before starting

- A computer (Windows, Mac, or Linux) — this cannot be built on a phone.
- [Node.js](https://nodejs.org) installed (v18 or newer).
- [Android Studio](https://developer.android.com/studio) installed, with the
  Android SDK set up (Android Studio prompts you through this on first
  launch).
- A [Google Play Developer account](https://play.google.com/console/signup)
  ($25 one-time fee) — needed to actually publish, not needed just to build
  and test.

## 1. Install dependencies

Open a terminal in this project folder and run:

```bash
npm install
npx cap add android
```

`npx cap add android` generates the `android/` folder — the actual native
Android Studio project. It downloads Capacitor's Android template from the
internet, so this step needs network access.

## 2. Icon and splash screen

Replace the placeholder icon with Borno Data's real logo:

1. Put a 1024×1024px PNG of the logo at `resources/icon.png`
2. Put a simple splash image (can be the logo centered on the navy
   `#0F1B2B` background) at `resources/splash.png`
3. Install the asset generator and run it:
   ```bash
   npm install -D @capacitor/assets
   npx capacitor-assets generate
   ```
   This auto-generates every required icon size for Android.

## 3. Build and test

```bash
npx cap sync android
npx cap open android
```

The last command opens the project in Android Studio. From there:
- Click the green ▶ Run button to test on an emulator or a plugged-in phone.
- **Build → Generate Signed Bundle / APK** when ready for the Play Store
  (choose "Android App Bundle" — Play Store requires `.aab`, not `.apk`,
  for new apps).

Android Studio will walk you through creating a signing key the first
time — **keep that key file and its password somewhere safe.** If it's
lost, you can never update the app again under the same listing; you'd
have to publish as a brand new app.

## 4. Push Notifications — two-part setup

Getting a notification onto someone's phone has two separate pieces, and
**both** need to be done — this project only has the first one wired up
so far.

### Part A — Client registration (already done in this project)

The app already asks for notification permission and sends the resulting
device token to `/api/push/register-token` on login. Nothing to do here.

### Part B — Server can actually send (you need to set this up)

1. Go to [Firebase Console](https://console.firebase.google.com), create a
   free project (or link this Android app to an existing one).
2. Add an Android app inside that Firebase project using package name
   `com.bornodata.app` (must match `capacitor.config.json` exactly).
3. Download the `google-services.json` file Firebase gives you, and place
   it at `android/app/google-services.json` in this project.
4. In Firebase Console → Project Settings → Service Accounts, click
   "Generate new private key" — this downloads a JSON file. **Keep this
   secret, never commit it to any public repo.**
5. On the **backend server** (Truehost), add the entire contents of that
   JSON file as one line to `env.txt`:
   ```
   FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"...", ...}
   ```
6. Also on the backend, run:
   ```bash
   npm install firebase-admin --save
   ```
   then restart the app (`backend/tmp/restart.txt` trick, as usual).

Once both parts are done, a successful data or airtime purchase will
trigger a real push notification — that trigger point is already wired
into `app.js` (search for `sendPushToUser` if you want to add more trigger
points, like "wallet funded" or an admin broadcast).

Until Part B is set up, purchases work completely normally — the push
attempt just silently logs "not configured" on the server and does nothing
else. Nothing breaks if you skip this entirely.

## 5. Fingerprint unlock

This is already fully wired up in `www/index.html` — no server setup
needed, unlike push notifications. It uses the device's own fingerprint
sensor (via `capacitor-native-biometric`, listed in `package.json`) purely
to gate access to a session that's already logged in on that device — it
never replaces the actual email+password login, and no fingerprint data
ever touches your server (Android handles the actual fingerprint matching
itself, entirely on-device).

After `npm install` and `npx cap sync android`, this should work out of
the box — a person can turn it on from Me → Fingerprint unlock once
they're logged in.

## 6. Offline behavior

The app already caches the last-seen wallet balance and transaction history
locally (via the existing `window.storage` layer), so it shows something
useful even with no signal, then quietly refreshes once back online. No
extra work needed for this — it's already how the app behaves on the
website today too.

## 7. Before submitting to Google Play

- **Privacy Policy URL** — `privacy.html` is included in this project.
  Upload it to `bornodata.com/privacy.html` (if it's not already there) and
  use that URL in the Play Console listing.
- **App category** — "Finance" is the accurate category for a VTU/wallet
  app; Google reviews finance-category apps more strictly, so make sure
  the privacy policy and data-safety form in Play Console accurately
  reflect what's in `privacy.html`.
- **Screenshots** — Play Console requires at least 2 phone screenshots.
  Simplest way: run the app on an emulator/phone and screenshot the Home,
  Buy Data, and Wallet screens.
- **Content rating questionnaire** — answer honestly; a VTU/wallet app
  typically lands in "Everyone" but does need the questionnaire completed.

## Files in this project

- `www/index.html` — the actual app (same code as `bornodata.com/app.html`,
  copied in here so Capacitor can bundle it)
- `capacitor.config.json` — app ID, name, splash/push settings
- `package.json` — dependencies for the wrapper itself
- `privacy.html` — privacy policy, upload this to your website too
- `add_push_tokens_table.sql` — run this on the database before deploying
  the updated `app.js` (adds the table push tokens are stored in)

## A note on keeping the app updated later

Whenever the website (`app.html`) changes, copy the updated file into
`www/index.html` here and run `npx cap sync android` again, then rebuild
in Android Studio and publish an update through Play Console. The web app
and the Android app share the exact same code — there's no second
codebase to maintain separately for the UI itself.
