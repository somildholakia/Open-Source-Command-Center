# Manual Android Test Checklist

Use this checklist only after downloading the debug APK artifact from the latest successful GitHub Actions run.

## Build configuration preflight

If the latest GitHub Actions build reports missing authentication configuration, configure these in the repository's **Settings → Secrets and variables → Actions** before testing sign-in and the live GitHub connection:

- **Repository secret:** `GOOGLE_SERVICES_JSON` — the complete contents of your local `android/app/google-services.json` file.
- **Repository variable:** `GITHUB_OAUTH_CLIENT_ID` — the public client ID for the GitHub OAuth App with Device Flow enabled.

Do not paste Firebase configuration, client secrets, access tokens, or signing keys into chat or commit them to the repository. After configuring these values, rerun the **Temporary VPS Flutter checks** workflow and use its newly uploaded APK. Without them, the app can launch but Firebase sign-in and the GitHub authorization flow are unavailable.

## Install and launch

- [ ] Download and extract `open-source-command-center-vps-debug-apk`.
- [ ] Install `app-debug.apk` on the Android device.
- [ ] Launch the app and confirm the splash/login flow opens without a crash.
- [ ] Close and reopen the app; confirm startup remains stable.

## Authentication and settings

- [ ] Sign in with a valid Firebase email/password account.
- [ ] Confirm invalid credentials and invalid form input show readable errors.
- [ ] Request a password-reset email and confirm the UI reports success only when the request succeeds.
- [ ] Switch Dark, Light, and System themes; navigate between screens and restart the app to verify the preference persists.
- [ ] Sign out and confirm the app returns to the login flow.

## GitHub and local-first data

- [ ] Start Connect GitHub and confirm a device code and verification link appear.
- [ ] Complete authorization in the browser and return to the app.
- [ ] Confirm the connected username/profile, repository list, activity feed, contribution calendar, and progress values use real data.
- [ ] Refresh while online and confirm the UI remains responsive.
- [ ] After a successful sync, enable airplane mode and refresh. Confirm cached data remains visible with a stale/offline notice rather than being replaced by fake live data.
- [ ] Restart while offline and confirm cached data can be restored.
- [ ] Disconnect GitHub and confirm the token, connection metadata, snapshots, and account-scoped progression history are cleared.
- [ ] Reconnect with another account and confirm the previous account's data does not appear.

## Layout and accessibility

- [ ] Check a compact viewport around 320 logical pixels for horizontal overflow.
- [ ] Check a regular phone viewport and rotate to landscape.
- [ ] Check a tablet-width viewport if available.
- [ ] Repeat key screens in Light and Dark themes.
- [ ] Increase system font size and confirm buttons, forms, cards, and bottom navigation remain readable and usable.

## Results

Record the device/Android version, APK commit SHA, passed checks, failures, and screenshots of any layout or functional issues. Manual device testing is not considered complete until the failed items are fixed and retested.
