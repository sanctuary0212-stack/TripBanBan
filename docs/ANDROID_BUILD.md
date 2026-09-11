# TripBanBan Android Build

## 固定 Android identity

正式測試開始後不要再每版更換 package id。建議固定：

- namespace: `com.tripbanban.app`
- applicationId: `com.tripbanban.app`
- App label: `旅行伴伴`
- minSdk: 依 Flutter / plugin 實際最低要求
- targetSdk: 使用當前 Google Play 要求版本

`flutter create` 後，在 `android/app/build.gradle.kts` 確認：

```kotlin
android {
    namespace = "com.tripbanban.app"
    defaultConfig {
        applicationId = "com.tripbanban.app"
    }
}
```

## Manifest

`android/app/src/main/AndroidManifest.xml` 至少需要：

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

相機／照片權限依目前 `image_picker` 與目標 Android SDK 的官方設定處理，不在程式中要求不必要的廣泛儲存權限。

## 產生 Drift 程式

```bash
dart run build_runner build --delete-conflicting-outputs
```

此步會產生 `lib/data/local/app_database.g.dart`。不要手工建立該檔。

## 驗證順序

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
```

Debug APK 預期位置：

`build/app/outputs/flutter-apk/app-debug.apk`

## Release 前

- 固定 release keystore；之後所有更新必須沿用同一簽章。
- Google OAuth Android client 的 package name 與 SHA-1 / SHA-256 必須對應 release key。
- 驗證相機、相簿、Drive AppData、背景工作、長圖分享、CSV 分享。
- 驗證無網路狀態下所有核心帳務功能仍可操作。
