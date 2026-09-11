# Android CI build (recommended for this ChatGPT environment)

The current ChatGPT container is network-isolated, so it cannot download the ~1.5 GB Flutter SDK or Android SDK packages directly. The project therefore includes a GitHub Actions build that runs on a normal hosted Android/Flutter toolchain.

## One-time setup

1. Create or connect a GitHub repository for TripBanBan.
2. Put this source tree at the repository root and push it.
3. Open **Actions → Android Build → Run workflow**.
4. When the workflow finishes, download the artifact **TripBanBan-v0.8.2-debug-apk**.

The workflow uses Flutter 3.47.2 stable, Java 21, the Android SDK bundled on the GitHub-hosted runner, Drift code generation, `flutter analyze`, `flutter test`, and `flutter build apk --debug`.

## Why this route

It solves the SDK limitation without returning to the hand-built APK approach. The generated APK is produced by the real Flutter/Gradle/Android toolchain and is suitable for device testing.

## Later

Once the debug build is stable, add a Play signing keystore through GitHub Actions secrets and produce an Android App Bundle (`flutter build appbundle --release`).
