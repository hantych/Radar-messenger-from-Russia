# 👻 Ghost Mesh v2.0

A peer-to-peer Bluetooth/Wi-Fi messenger for Android.

- **No accounts.** No sign-up, no email, no phone number.
- **No servers.** Phones talk to each other directly using Google Nearby Connections.
- **Auto-discovery.** Open the app on two phones — they find each other automatically.
- **Device-name nicknames.** Your model name (e.g. "Pixel 7") is what others see.
- **Range:** about 30–100 meters, works fully offline.
- **Special feature — Ghost messages 👻:** toggle ghost mode and your message
  is wiped from both phones the moment they go out of range.

## What's new in v2.0

- ✅ **Pre-flight check screen** — step-by-step diagnostic of every requirement
  (Location permission, GPS service, Bluetooth, etc.) with one-tap fix buttons.
- ✅ **Auto re-check** — when you come back from system settings, the screen
  refreshes automatically.
- ✅ **Fixed Android 14+ permissions bug** — Nearby Connections no longer
  throws "missing ACCESS_COARSE_LOCATION" on Android 13/14/15/16.
- ✅ **Fixed build issues** — NDK version + core library desugaring properly
  configured. Builds cleanly on first try.
- ✅ **Better radar UI** — peer cards with status, unread badges, sorted by
  connection state.
- ✅ **Activity log + diagnostics** in Settings.

## How to build the APK

You will use **GitHub Actions** to compile the APK in the cloud. No Android
Studio, no Java, no Flutter installation needed.

### 1. Create a GitHub repository
1. Go to <https://github.com> and sign in.
2. Click **New** → name it `ghost-mesh` → **Create repository**.

### 2. Upload the project files
1. Click **Add file → Upload files**.
2. **Drag the contents of the `ghost_mesh` folder** (NOT the folder itself)
   into the upload area. The `lib/`, `android/`, `pubspec.yaml`, etc. should
   end up in the root of the repo.
3. ⚠️ Make sure `.github/workflows/build.yml` was uploaded. If not, create it
   manually: *Add file → Create new file*, type the path
   `.github/workflows/build.yml`, paste the YAML contents.
4. Commit changes.

### 3. Wait for the APK
1. Open the **Actions** tab — you'll see "Build APK" running (yellow).
2. Wait 5–15 minutes for the green ✅.
3. Click the run → scroll down to **Artifacts** → download `ghost-mesh-apk`.
4. Unzip — inside is `app-release.apk`.

### 4. Install on your phone
1. Transfer the APK to your Android phone.
2. Open it. Allow installation from unknown sources if prompted.
3. Launch Ghost Mesh.
4. **Pre-flight check** screen will guide you — tap each red ✗ to fix it.
5. When everything is green, tap **ENTER MESH ▶**.

### 5. Test on two phones
1. Install on **two** Android phones within ~30m.
2. Both must pass the pre-flight check (Location ON, Bluetooth ON, all permissions).
3. Within ~30s the phones should appear on each other's radar.
4. Tap a peer card → start chatting.

## Xiaomi / Huawei users

Stock MIUI / HyperOS / EMUI aggressively kill background apps. For best results:

- Settings → Apps → **Ghost Mesh** → **Battery** → **No restrictions** /
  **Don't optimize**
- Settings → Apps → **Ghost Mesh** → **Autostart** → **Enable** (MIUI only)
- If "Grant" buttons don't work in the pre-flight screen, tap **OPEN APP
  SETTINGS** at the bottom and toggle each permission manually.

## Troubleshooting

| Problem | Fix |
|---|---|
| Workflow fails on GitHub | Open the failed run, copy the error from the failed step, paste it back to your AI helper |
| Phones don't see each other | Re-check pre-flight screen on both phones; they must ALL be green |
| "Discovery failed: missing permission ACCESS_COARSE_LOCATION" | This was a v1.0 bug — make sure you're using v2.0 (check Settings → version is 2.0) |
| Connection drops constantly | Battery optimisation killing the app — see Xiaomi/Huawei section above |
| App crashes on launch | Uninstall any older version first, then install fresh |

## Known limitations

- **Android only.** iOS would require a complete rewrite.
- **No encryption.** Messages travel in cleartext over Nearby Connections.
- **No internet.** Local peer-to-peer only — adding internet would require a
  signaling server.
- **No multi-hop mesh.** Messages reach only phones within direct radio range.

## License

MIT — do whatever you want.
