# TripBanBan Mobile

Android-first mobile client built with Expo / React Native.

## Local development

From the repository root:

```bash
npm install
npm run mobile
```

Then open the project on an Android emulator or device through Expo tooling.

## Generate a test APK with GitHub Actions

1. Open the repository **Actions** tab.
2. Select **Android APK**.
3. Choose **Run workflow**.
4. Select the branch containing the mobile app.
5. When the job finishes, download the `tripbanban-android-debug` artifact.
6. Extract the ZIP and install `app-debug.apk` on the Android device.

The workflow generates a native Android project with Expo Prebuild and runs Gradle `assembleDebug`, so it does not require an Expo account or EAS token.

## EAS preview build

`eas.json` also contains a `preview` profile configured with `android.buildType = apk` for future EAS cloud builds.

```bash
cd apps/mobile
npx eas-cli build -p android --profile preview
```

Before using EAS in CI, link the Expo project and configure credentials/token once.

## Shared domain

The mobile client imports trip data types and demo data from `@tripbanban/domain`, the same package used by the Web app.
