# GitHub Integration Setup (Phase 2)

This document describes the **external configuration** required to run the real
GitHub integration. The application is fully functional without it — it simply
shows the disconnected state and explains what is missing — but a real GitHub
sign-in requires the steps below.

> **Security model**
>
> - The Flutter client uses the **OAuth Device Authorization Flow**. This is the
>   only GitHub OAuth flow that does **not** require a client secret.
> - Only the OAuth **client id** is embedded in the app. It is a public
>   identifier, not a credential.
> - **No client secret is ever stored in, compiled into, or committed with this
>   repository.** Do not add one.
> - The issued access token is stored exclusively in `flutter_secure_storage`
>   (Android Keystore-backed). It is never written to `SharedPreferences`,
>   logs, analytics, or source control.
> - The requested scope is `read:user` only — the minimum needed to read the
>   public profile, public events, and the public contribution calendar.

---

## 1. Create a GitHub OAuth App

1. Sign in to GitHub and open **Settings → Developer settings → OAuth Apps**
   (<https://github.com/settings/developers>).
2. Click **New OAuth App**.
3. Fill in:
   - **Application name:** `Open Source Command Center` (or any name)
   - **Homepage URL:** `https://github.com/<your-username>` (any valid URL)
   - **Authorization callback URL:** `https://open-source-command-center.firebaseapp.com/__/auth/handler`
     - The device flow does not use this URL, but GitHub requires a value.
       Using the Firebase Auth handler URL keeps the same OAuth App usable for
       the optional Firebase identity linking described in section 3.
4. Click **Register application**.
5. On the app page, **enable Device Flow**:
   - Open the app, scroll to **Device Flow** and tick **Enable Device Flow**
     (GitHub may require you to confirm your account password).
6. Copy the **Client ID**. You do **not** need the client secret for this app —
   leave it unused.

> The device flow must be enabled, otherwise the token request fails with
> `device_flow_disabled`. The app surfaces this as a typed error.

---

## 2. Provide the client id at build time

The client id is read from a compile-time environment variable so that no
identifier is hardcoded in source:

```bash
flutter run --dart-define=GITHUB_OAUTH_CLIENT_ID=<your-client-id>
```

For release builds:

```bash
flutter build apk --release --dart-define=GITHUB_OAUTH_CLIENT_ID=<your-client-id>
```

Notes:

- `--dart-define` values are compiled into the app. Only the **public client
  id** may be supplied this way — never a secret.
- If the client id is missing or empty, connecting fails fast with a clear
  `AuthenticationFailed` message that names `GITHUB_OAUTH_CLIENT_ID`. The rest
  of the app (disconnect, local state, sample previews) continues to work.
- In VS Code / Android Studio, add the define to the run configuration
  (`toolArgs`: `["--dart-define=GITHUB_OAUTH_CLIENT_ID=<your-client-id>"]`).

---

## 3. Optional — link the GitHub identity to the Firebase user

The app signs the user in with Firebase (email/password). After a successful
GitHub authorization it can *additionally* link the GitHub identity to the
Firebase account via `linkWithCredential(GithubAuthProvider.credential(token))`.

This step is **best-effort**: if it fails (provider not enabled, account
already linked elsewhere, network error), the GitHub integration still works
with the stored token and the failure is only logged as an error code.

To enable it:

1. Open the **Firebase Console** for the project `open-source-command-center`.
2. Go to **Authentication → Sign-in method → Add new provider → GitHub**.
3. Paste the **Client ID** and **Client secret** from the GitHub OAuth App.
   - The client secret is entered **only in the Firebase Console**, never in
     the app repository.
4. Set the **Authorization callback URL** shown by Firebase
   (`https://open-source-command-center.firebaseapp.com/__/auth/handler`) as
   the OAuth App's callback URL (already done in section 1).
5. Save.

If you skip this step, nothing breaks — the app just does not link a GitHub
credential to the Firebase user.

---

## 4. Firebase project files

- `android/app/google-services.json` is a **local-only** file. It contains a
  Firebase API key and is listed in `.gitignore`; do not commit it.
- iOS/macOS equivalents (`GoogleService-Info.plist`) are ignored as well.
- The file is required for Firebase Auth to initialize. A fresh clone must
  download it from the Firebase Console
  (**Project settings → Your apps → Android → google-services.json**).

---

## 5. What the app requests

| Data | API | Scope required |
| --- | --- | --- |
| Profile (login, name, avatar, repos, followers) | REST `/user` | `read:user` |
| Repositories | REST `/user/repos` | `read:user` (public repos only) |
| Activity feed | REST `/users/{login}/events/public` | `read:user` |
| Contribution calendar | GraphQL `contributionsCollection` | `read:user` |

Private repositories, notifications, and write operations are **not** requested
in this phase. Requesting additional scopes requires changing
`GitHubConfig.scopes` and re-authorizing.

---

## 6. Verifying the integration locally

```bash
# 1. Format, analyze, test
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

# 2. Run with the client id
flutter run --dart-define=GITHUB_OAUTH_CLIENT_ID=<your-client-id>
```

Expected manual flow:

1. Sign in to the app with email/password.
2. Go to **Profile** (or **Dashboard**) and tap **Connect GitHub**.
3. A card shows a device code and a button that opens
   <https://github.com/login/device> in the system browser.
4. Enter the code on GitHub and approve `read:user`.
5. Return to the app: the connection card turns into the connected state with
   avatar, repository/follower counts, and a **Refresh** / **Disconnect**
   action. Dashboard, Activity, and Contributions switch from sample data to
   live data.

---

## 7. Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| "GitHub client id is missing" on connect | Build without `--dart-define` | Rebuild with the define (section 2) |
| `device_flow_disabled` | Device flow not enabled on the OAuth App | Enable it (section 1, step 5) |
| `access_denied` | User rejected the request | Retry the connect flow |
| `expired_token` / code expired | Device code lifetime elapsed | Tap **Connect** again for a fresh code |
| `slow_down` | Polling too fast | Automatic — the app increases its interval and continues |
| `rate_limited` with reset time | GitHub API limit reached | Wait until the shown reset time; the app shows the typed state |
| Identity linking error (non-fatal) | Firebase GitHub provider not enabled | Section 3 (optional) |

---

## 8. Disconnecting

Users can disconnect at any time from the connection card (**Disconnect**,
with a confirmation dialog). Disconnecting:

- Deletes the token from secure storage.
- Clears the local connection record.
- Returns Dashboard, Activity, and Contributions to their sample-data preview
  states.

If secure storage cannot confirm token deletion, the app reports a disconnect
error instead of claiming success and preserves the local connection record so
the user can retry. Resolve the device's secure-storage issue and retry; GitHub
authorization on the website is not revoked by a local disconnect.

The GitHub authorization itself remains on the user's GitHub account until they
revoke it in **GitHub → Settings → Applications**; the app cannot revoke it
server-side without a backend, which is a planned backend responsibility.


## 9. Building a configured manual-test APK from GitHub Actions

The feature-branch VPS workflow can build an APK with Firebase and GitHub
integration enabled without committing local configuration files.

In the repository, open **Settings → Secrets and variables → Actions** and add:

- **Repository secret** `GOOGLE_SERVICES_JSON`: paste the complete contents of
  your local `android/app/google-services.json` file as raw JSON. Do not commit
  this file to Git.
- **Repository variable** `GITHUB_OAUTH_CLIENT_ID`: the public Client ID of
  your GitHub OAuth App, with Device Flow enabled. Never store a client secret
  in this variable or in the Flutter app.

Then rerun **Actions → Temporary VPS Flutter checks**. The workflow writes the
Firebase config only into its temporary checkout (the file remains gitignored)
and passes the public GitHub Client ID using `--dart-define`. It does not upload
the raw Firebase config as an artifact. If either setting is missing, the APK
still builds, but the corresponding authentication flow will not be fully
configured; GitHub Actions will show a warning.

The uploaded debug APK is a temporary manual-testing build, not a signed
production release. Download it from the workflow run's **Artifacts** section.
