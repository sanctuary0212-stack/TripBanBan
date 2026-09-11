# TripBanBan

TripBanBan 專案主倉庫。

目前先建立 **technology-agnostic monorepo skeleton**，把產品、前端、後端、共用模組、文件與測試的邊界先整理好；在正式決定 Web / Mobile / Backend 技術棧前，不先鎖死框架。

## Repository structure

```text
TripBanBan/
├─ apps/              # 使用者端應用（Web / Mobile 等）
├─ services/          # Backend API、worker、integration services
├─ packages/          # 跨應用共用模組、型別、domain logic
├─ docs/              # 架構、產品與開發文件
├─ scripts/           # 開發、建置、部署輔助腳本
├─ tests/             # 跨模組 / integration / e2e tests
├─ .editorconfig
├─ .gitignore
└─ README.md
```

## Initial principles

1. **先分離 domain 與 UI**：核心旅程/行程資料模型不要綁定單一前端框架。
2. **API contract 明確化**：前後端透過穩定 contract 溝通，方便未來 Web / Mobile 共用。
3. **共用邏輯集中**：共用型別、validation、utilities 放在 `packages/`。
4. **文件跟著程式走**：重要架構決策放在 `docs/`，避免只存在聊天紀錄。
5. **避免過早鎖定技術棧**：等 MVP 功能與部署需求確認後，再加入 framework-specific scaffold。

## Next milestones

- 定義 MVP 使用情境與核心功能
- 決定 Web / Mobile 優先順序
- 決定 frontend / backend 技術棧
- 建立 domain model 與 API contract
- 加入 CI、lint、test、deployment pipeline

## Status

Project scaffold initialized.
