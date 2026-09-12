# Google Play Data Safety — Draft for TripBanBan

This document is a submission aid, not a substitute for reviewing the final Google Play Data safety form against the exact production AAB and SDKs.

## Current production-candidate architecture

- Local-first ledger/database; no TripBanBan account or cloud backend.
- Google Drive backup removed.
- User-triggered `.tripbanban` import/export only; export destination is chosen by the user.
- Optional photo attachments remain local unless the user explicitly exports/shares data.
- Google Play Billing is used for the TripBanBan Plus entitlement.
- No advertising SDK.
- No analytics SDK intentionally included.

## Likely Data safety answers

### Does the app collect or share user data with the developer?

Expected answer for the current architecture: **No developer-operated collection of trip ledger data.**

Travelers, expenses, shared-fund entries, settlements, settings, and attachments are stored locally. The app does not send them to a TripBanBan server.

### User-initiated exports/shares

A `.tripbanban` export or other shared output is initiated by the user and sent to a destination selected by the user. This should be reviewed under Google's user-initiated transfer exceptions when completing the form.

### Purchases

Google Play processes payment information. TripBanBan receives purchase/entitlement information through Play Billing but does not receive or store the user's payment-card number.

Review the Play Console guidance at submission time for whether purchase/transaction information exposed through the Billing SDK requires declaration in the exact form version then current.

### Photos/files

Photos and backup files are accessed only when selected/created by the user for an app feature. They are intended to remain local unless the user explicitly exports or shares them.

### Advertising

Expected answer: **No ads.**

### Tracking

Expected answer: **No cross-app advertising tracking.**

## Security practices to select only if accurate at release time

- Data in transit: Google Play Billing communications are handled by Google Play/SDK transport.
- Local ledger data is stored on device; do not claim end-to-end encryption for local data unless explicitly implemented.
- Users can delete trips/data in the app and can uninstall/clear app storage to remove local data.

## Final verification before submission

1. Inspect final production AAB dependency/permission list.
2. Confirm no analytics/crash/ad SDK was added after this draft.
3. Confirm no production `FX_STATIC_URL` sends ledger/user data (exchange-rate fetch should be data-only GET).
4. Confirm the privacy policy matches the final Billing and backup behavior.
5. Complete the Play Console form using the final wording presented by Google at submission time.
