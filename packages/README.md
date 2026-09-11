# Packages

跨應用與跨服務共用的模組放在這裡。

預期可能包含：

```text
packages/
├─ domain/
├─ contracts/
├─ validation/
└─ shared/
```

原則：`packages/` 不依賴特定 UI app 或 concrete service implementation。
