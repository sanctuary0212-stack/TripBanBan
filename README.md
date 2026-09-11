# 旅行伴伴 TripBanBan v0.8.2 — Android Local-First

TripBanBan 是 Android-first 的短期旅遊記帳／分帳 App。v0.8.2 開始把前期 WebView Alpha 的核心能力正式搬到 Flutter + SQLite/Drift，本機資料是唯一真實來源；沒有 TripBanBan 自建雲端後端。

## 目前產品原則

- Android 優先，**目前不開發 iOS**。
- 核心帳務、資料庫 Repository、分攤與結算演算法使用純 Dart/Flutter，不綁 Android API。
- SQLite/Drift 儲存旅程、旅伴、支出、分攤、公基金、實際轉帳、附件、匯率與設定。
- App 在完全離線狀態仍可建立旅程、記帳、分攤與結算。
- Google Drive AppData 僅作**個人備份／還原**，不是多人同步，也不是帳本主資料來源。
- 匯率採每日快取 + 離線 fallback + 使用者手動覆寫；每筆支出固定保存當下匯率 snapshot。
- 結算長圖 / CSV 在本機產生，再使用 Android ShareSheet 分享到 LINE、WhatsApp、微信等。
- 暫不做多人即時同步、Web Viewer、CRDT、P2P、AI OCR。

## v0.8.2 已包含

- Drift schema：Trips、Members、Expenses、ExpenseShares、FundTransactions、SettlementPayments、Attachments、CustomCategories、CustomCurrencies、FxRates、AppSettings。
- 單一 LedgerService：總支出、公基金、每人淨額、旅程狀態、建議轉帳共用同一套計算。
- 平均／自訂金額／比例分攤與精確 rounding。
- 支出 CRUD、公基金交易、實際轉帳紀錄。
- 本機照片附件儲存抽象層。
- `.tripbanban` ZIP 帳戶備份／還原與 JSON snapshot schema。
- Google Drive `appDataFolder` 備份／還原 Service。
- WorkManager 的每日匯率與「最佳努力」Drive 備份排程骨架。
- 160+ 世界幣別 catalog、離線匯率 fallback、每日靜態 JSON 更新。
- 本機 PNG 結算長圖、CSV 匯出、Android ShareSheet。
- 繁中／簡中／英文／日文／韓文的核心介面字串層。

## Android 建置

此來源包目前**不含由 Flutter SDK 產生的 `android/` scaffold**，因本工作環境沒有 Flutter / Dart / Android SDK。請在有 Flutter SDK 的機器上執行：

```bash
./tool/bootstrap_android.sh
```

或手動：

```bash
flutter create --platforms=android --org com.tripbanban --project-name tripbanban_app .
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
```

建立 scaffold 後，請依 `docs/ANDROID_BUILD.md` 將 Android `applicationId` / `namespace` 固定為 `com.tripbanban.app`，加入 INTERNET 權限，並完成 Google OAuth / Drive API 設定。

## 建置前自我檢查

不需 Dart SDK 即可先執行：

```bash
python3 tool/preflight.py
```

它會檢查版本、五語系、主要資料表、Android-only 文件與舊 Supabase / iOS 字樣是否混入核心設定。

## Google Drive AppData

請看 `docs/GOOGLE_DRIVE_APPDATA.md`。Drive AppData 是使用者個人備份空間，不支援旅伴共同存取；本版不把它當多人同步引擎。

## 重要限制

這個環境無法執行 `flutter analyze` / `flutter test` / Gradle APK build，因此 v0.8.2 是「build-ready source」，不是已宣稱通過實機編譯的 APK。正式 APK 必須在 Flutter Android toolchain 中完成 code generation、分析、測試與簽章。
