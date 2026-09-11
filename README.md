# TripBanBan

TripBanBan 是一個以「快速建立、看懂並調整旅行每日節奏」為核心的行程規劃專案。

目前進入 **Web-first MVP** 階段：前端與 API 先放在 Next.js App Router，核心旅程資料模型獨立放在 shared domain package，保留未來 Mobile App 與獨立 backend service 的演進空間。

## Tech baseline

- Node.js 24 LTS
- npm workspaces
- Next.js 16.3.3
- React 19.2
- TypeScript
- GitHub Actions CI

## Repository structure

```text
TripBanBan/
├─ apps/
│  └─ web/                 # Next.js Web MVP + route handlers
├─ packages/
│  └─ domain/              # Trip / Day / Stop shared domain model
├─ services/               # Future standalone backend/integrations
├─ docs/
│  ├─ architecture.md
│  └─ mvp.md
├─ scripts/
├─ tests/
├─ .github/workflows/ci.yml
├─ .editorconfig
├─ .gitignore
├─ .nvmrc
├─ package.json
└─ README.md
```

## Run locally

```bash
nvm use
npm install
npm run dev
```

Then open `http://localhost:3000`.

Useful endpoints:

- `GET /api/health`
- `GET /api/trips`

## Verify

```bash
npm run typecheck
npm run build
```

## Architecture principles

1. **Domain 與 UI 分離**：核心 Trip / Day / Stop model 不綁定特定 UI framework。
2. **共用 contract**：Web、未來 Mobile 與 backend 共用一致的 domain types。
3. **逐步拆服務**：MVP 先以 Next.js route handlers 快速驗證；需求成長後再把 backend 拆到 `services/`。
4. **文件跟著程式走**：產品與架構決策保存在 `docs/`。
5. **CI 當基本門檻**：PR 先通過 typecheck 與 production build。

## MVP next milestone

下一個里程碑是完成 Trip CRUD + persistence：使用者可以建立行程、加入多天與景點、重新整理後資料仍存在，並分享唯讀行程網址。

See `docs/mvp.md` for the product slices and definition of done.
