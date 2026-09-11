# TripBanBan MVP

## Product goal

先解決一個最核心的問題：**讓使用者快速建立、看懂並調整一趟旅行的每日節奏。**

## MVP foundation included in this branch

- Web-first application shell
- Shared trip domain model
- Demo itinerary dashboard
- Health API
- Trips API
- TypeScript workspace structure
- CI typecheck + build gate

## Next product slices

### Slice 1 — Trip CRUD

- 建立旅行
- 編輯旅行名稱、目的地與日期
- 新增 / 刪除 Day
- 新增 / 編輯 / 排序 Stop

### Slice 2 — Persistence

- Database schema
- Repository layer
- API create/update/delete
- Seed / migration workflow

### Slice 3 — Identity & sharing

- Sign-in
- User-owned trips
- Shareable read-only trip link

### Slice 4 — Map & discovery

- Map view
- Place search
- Travel-time context
- Drag-and-drop itinerary refinement

## Out of scope for the first MVP

- Payment
- Booking transactions
- AI autonomous booking
- Complex social network features
- Full offline-first sync

## Definition of done for the next milestone

A user can create a trip, add at least two days and several stops, reload the page without losing data, and share a read-only itinerary URL.
