# Google Drive AppData 備份設計

TripBanBan 不架設自己的備份伺服器。Android 使用者可以明確選擇連結 Google 帳號，將 `.tripbanban` 帳戶備份寫入自己的 Google Drive `appDataFolder`。

## 用途

- 個人資料備份
- 換機還原
- App 重裝後還原

**不作為：**

- 多人共同帳本
- 即時同步
- 旅伴分享資料夾

## OAuth scope

只要求：

`https://www.googleapis.com/auth/drive.appdata`

不要為了備份要求整個 Google Drive 的廣泛權限。

## Google Cloud Console

1. 建立 / 選擇 TripBanBan Google Cloud project。
2. 啟用 Google Drive API。
3. 設定 OAuth consent screen。
4. 建立 Android OAuth client。
5. Package name 使用 `com.tripbanban.app`。
6. 加入 debug keystore SHA-1；正式發行時再加入 release / Play App Signing SHA。

## 備份檔

Drive AppData 中固定維護：

`tripbanban_account_v1.tripbanban`

每次備份先在本機建立一致性 snapshot，再整檔上傳／取代。SQLite 本機資料仍是主資料來源。

## 還原安全性

還原前 UI 必須顯示：

- 備份時間
- 旅程數
- 支出數
- 照片附件數

並明確告知「將覆蓋本機資料」，使用者二次確認後才執行 destructive restore。

## 背景備份

WorkManager 只做 best-effort。若背景 isolate 無法取得既有 Google 授權，就跳過此次雲端上傳；不得阻塞或影響本機記帳。使用者永遠可從設定頁按「立即備份」。
