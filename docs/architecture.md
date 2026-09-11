# TripBanBan Architecture

## Goal

先用清楚的模組邊界建立可演進架構，避免在產品需求尚未定案時過早綁定特定 framework。

## Logical layers

### 1. Apps

`apps/` 放直接面向使用者的應用，例如 Web、Mobile 或管理介面。

原則：
- UI 不直接承擔核心 domain 規則。
- 不同 client 儘可能共用 contract 與 domain types。
- platform-specific code 留在各自 app 內。

### 2. Services

`services/` 放 server-side components，例如 API、background worker、notification service 或第三方 integration。

原則：
- 對外 API contract 要可版本化。
- secrets 僅由 runtime environment 注入，不進 Git。
- integration code 與核心 domain logic 分離。

### 3. Packages

`packages/` 放可重用模組，例如：
- domain models
- shared types
- validation
- API contracts
- utilities
- design tokens / shared UI（若未來需要）

原則：共用模組不能反向依賴特定 app。

### 4. Tests

`tests/` 放跨模組測試，例如 integration / end-to-end / contract tests。單元測試可依所選技術棧放在模組附近。

### 5. Docs

`docs/` 紀錄：
- product decisions
- architecture decisions
- API design
- data model
- deployment/runbook

重要決策建議以 ADR（Architecture Decision Record）方式保存。

## Proposed dependency direction

```text
Apps ───────┐
            ├──> Packages / Contracts / Domain
Services ───┘

Tests ────────> Apps + Services + Packages
```

避免：

```text
packages -> apps
packages -> concrete service implementation
```

## Decisions intentionally left open

以下項目暫不在 scaffold 階段鎖定：
- Web framework
- Mobile framework
- Backend language/framework
- Database
- Authentication provider
- Cloud/deployment platform
- CI/CD implementation

等 MVP 與主要 client 優先級確認後再決定。
