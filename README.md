# TripBanBan

TripBanBan 是 Web + Mobile 共用 domain model 的旅遊行程 MVP。

## Current stack

- Node.js 24 LTS
- npm workspaces
- Web: Next.js 16.3.3 + React 19.2 + TypeScript
- Mobile: Expo SDK 57 + React Native 0.86.3
- Shared domain: `@tripbanban/domain`

## Repository structure

```text
TripBanBan/
├─ apps/
│  ├─ web/            # Next.js Web MVP
│  └─ mobile/         # Expo / React Native Android client
├─ services/          # Future standalone backend / workers
├─ packages/
│  └─ domain/         # Trip / Day / Stop shared model
├─ docs/              # Architecture and MVP scope
├─ scripts/
├─ tests/
└─ .github/workflows/
```

## Run Web

```bash
npm install
npm run dev
```

Open `http://localhost:3000`.

Available endpoints:

- `GET /api/health`
- `GET /api/trips`

## Run Mobile

```bash
npm install
npm run mobile
```

The mobile app renders the same demo itinerary from `@tripbanban/domain` as the Web app.

## Build an Android test APK

The repository includes `.github/workflows/android-apk.yml`.

On pull requests that change mobile code, GitHub automatically builds a debug APK. You can also run it manually from **Actions → Android APK → Run workflow**.

After the workflow succeeds:

1. Open the workflow run.
2. Download the `tripbanban-android-debug` artifact.
3. Extract it.
4. Install `app-debug.apk` on the Android phone.

This debug APK path does not require an Expo account or EAS token. The mobile app also includes an EAS `preview` profile for future cloud-distributed APK builds.

## Initial architecture principles

1. **Domain 與 UI 分離**：核心 Trip / Day / Stop model 不綁特定前端。
2. **API contract 明確化**：Web / Mobile 未來透過穩定 contract 存取後端。
3. **共用邏輯集中**：共用型別與 domain logic 放在 `packages/`。
4. **文件跟程式走**：產品與架構決策保存在 `docs/`。
5. **先 MVP、再拆服務**：目前以 Web route handlers 快速驗證，需求成熟後再拆 standalone services。

## Next milestones

- Trip CRUD
- Persistence / database
- Read-only sharing URL
- Mobile navigation
- Map / location support
- Authentication

## Status

Web + Android MVP foundation in progress.
