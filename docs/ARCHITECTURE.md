# TripBanBan v0.8.2 Android Local-First Architecture

## 1. 原則

TripBanBan 目前只以 Android 為交付平台，但核心帳務與資料層不依賴 Android framework。App 不需要 TripBanBan 自建後端；本機 SQLite 是唯一帳本真相來源。

資料流固定為：

`Flutter UI → Application Service → Repository → Drift / SQLite`

衍生資料固定由：

`SQLite → LedgerService → Balance / Fund / Status / Suggested Transfers`

UI 不自行維護總額、公基金餘額或每人淨額。

## 2. 旅程帳務狀態

只保留三個使用者可見狀態：

- `notStarted`: 尚無任何支出紀錄。
- `pendingSettlement`: 已有支出，仍有公基金餘額或成員間待處理款項。
- `settled`: 所有帳務已完成。

狀態由 LedgerService 推導，不在 Trips table 儲存可漂移的 status 欄位。

## 3. 本機資料庫

主要資料表：

- Trips
- Members
- Expenses
- ExpenseShares
- FundTransactions
- SettlementPayments
- Attachments
- CustomCategories
- CustomCurrencies
- FxRates
- AppSettings

所有旅程資料都以 `tripId` 隔離。金額使用 integer minor units，避免浮點誤差；匯率保存 decimal string snapshot。

## 4. 公基金

公基金不是獨立的第二套帳本。原始資料只保存：

- `CONTRIBUTION`
- `REFUND`
- `ADJUSTMENT`
- payerType = `FUND` 的 Expense

公基金餘額由上述紀錄推導。不同旅程不共享任何公基金狀態。

## 5. 分攤與結算

ExpenseShares 保存每位旅伴的實際分攤 minor amount。平均、自訂金額、比例最終都必須轉成確定的 minor-unit shares，而且總和必須精確等於 `baseAmountMinor`。

Suggested transfers 永不直接持久化；它們是目前帳本狀態的衍生結果。只有使用者已實際完成的轉帳寫入 SettlementPayments。

## 6. 匯率

優先順序：

1. 使用者手動匯率
2. 當日快取
3. 最近可用快取
4. App 內建 fallback

每筆 Expense 固定保存 `exchangeRateText`、`exchangeRateDate`、`exchangeRateSource` 與換算後的 `baseAmountMinor`。日後更新匯率不得改寫歷史支出。

## 7. 照片

SQLite 只保存附件 metadata 與相對路徑；實際圖片放在 App 私有文件目錄。刪除支出／旅程時必須同步清理附件。

## 8. 備份

`.tripbanban` 是 ZIP container，至少包含：

- `manifest.json`
- `snapshot.json`
- `files/attachments/...`

本機匯出與 Google Drive AppData 使用同一格式。Drive 只是 Backup Provider，不是同步資料庫。

## 9. 背景工作

WorkManager 用於 best-effort：

- 每日匯率刷新
- 已授權時的每日 Drive 備份

任何背景工作失敗都不能影響本機帳務功能。

## 10. 分享

ReportFactory 從 LedgerService 建立唯讀報告模型，再由：

- SettlementImageService → PNG 長圖
- CsvExportService → CSV
- PlatformShareService → Android ShareSheet

LINE / WhatsApp / 微信都透過系統 ShareSheet，不做專有 SDK 綁定。

## 11. 目前不做

- iOS build / StoreKit / iCloud
- 多人即時同步
- Web Viewer
- CRDT / P2P
- TripBanBan 自建 API / DB server
- AI OCR
