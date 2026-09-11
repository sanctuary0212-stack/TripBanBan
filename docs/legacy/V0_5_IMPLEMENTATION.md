# TripBanBan v0.5 Function/UI Alpha

Implemented scope:

- Built-in currencies: TWD, JPY, CNY, USD, KRW, EUR.
- New expenses default to the selected trip's base currency.
- Any expense may use a different currency.
- Auto FX service uses Frankfurter v2 and stores the returned rate/date/source on the expense.
- Offline reference rates keep the UI usable when the rate service is unavailable.
- Manual FX remains available and is stored with the expense.
- Per-trip custom currencies with code, symbol and manual rate to trip base currency.
- Report currency can differ from the settlement/base currency. Changing report currency never mutates ledger or settlement data.
- Category selection uses icons; per-trip custom categories are supported.
- Split participants are individually selectable and include select-all / clear-all.
- Expense attachments support camera/gallery through `image_picker`; Free is intended for one attachment per expense, Full for multiple attachments.
- Trip deletion is explicit and destructive with confirmation. Production should recommend exporting a `.tripbanban` backup first.
- Launcher branding source lives at `assets/branding/tripbanban_icon.png` and `flutter_launcher_icons` is configured.
- Supabase schema v0.5 includes custom currencies, custom categories, FX capture fields and expense attachments.

## Accounting invariant

`Expense.amountMinor` is the amount used for balance and settlement calculations in the trip base currency. `originalAmountMinor` and `currencyCode` preserve the purchase amount and currency. `exchangeRateToBase` is immutable after save.

This prevents historical balances from changing when market FX rates change later.

## Report currency

Report conversion is presentation-only. Person-to-person settlement instructions remain in the trip base currency. A PDF may show a converted trip total, but it also retains the settlement base currency and rate date/source context.

## Test APK vs Flutter source

The hand-built Android test shell exercises the v0.5 flows without a full Flutter SDK in the build environment. Its photo buttons create attachment placeholders for flow validation. The Flutter source contains the native `image_picker` camera/gallery implementation intended for the production build.
