# TripBanBan Google Play Release Checklist

Release preparation branch: `release/play-rc`

## Technical release gates

- [x] Package ID fixed to `com.tripbanban.app`.
- [x] Android compileSdk and targetSdk pinned to API 36 for 2026 Google Play submission requirements.
- [x] Release-candidate workflow builds Android App Bundle (`.aab`).
- [x] Existing Flutter analyze/tests run before the AAB build.
- [x] Google Drive backup removed; local `.tripbanban` import/export remains Plus-only.
- [ ] Replace debug-only Plus entitlement with Google Play Billing purchase + restore flow.
- [ ] Create Google Play one-time product for TripBanBan Plus and connect its product ID.
- [ ] Configure a persistent Android upload key and store signing material only in GitHub Actions secrets / Play App Signing.
- [ ] Build the final production-signed AAB.
- [ ] Run Play internal testing with at least purchase, restore, import/export, multi-traveler, expense accumulation and settlement scenarios.

## Recommended Google Play product

- Type: one-time product / permanent entitlement
- Suggested product ID: `tripbanban_plus_lifetime`
- Display name: `TripBanBan Plus`
- Intended price: US$1.99 equivalent, localized by Google Play
- Entitlement: more than 3 travelers + `.tripbanban` import/export

Do not create multiple product IDs for the same lifetime entitlement unless migration is intentional.

## Store and policy gates

- [ ] Developer account identity/payment profile verified in Play Console.
- [ ] App name, short description, full description and category finalized.
- [ ] Phone/tablet screenshots and 512x512 high-resolution icon uploaded.
- [ ] Feature graphic prepared.
- [ ] Privacy policy published at a public, stable URL and linked inside the app.
- [ ] Data safety form completed and matched to actual SDK/data behavior.
- [ ] Ads declaration completed (expected: no ads, unless product direction changes).
- [ ] Target audience/content declarations completed.
- [ ] Content rating questionnaire completed.
- [ ] App access/reviewer instructions completed if any function is gated.

## Data/privacy baseline for current architecture

TripBanBan is local-first: ledger, traveler, photo attachment and settlement data are intended to remain on-device unless the user explicitly exports/shares a `.tripbanban` backup or other output. Google Drive backup has been removed. Google Play Billing will be used only for the Plus entitlement when implemented.

The final Data safety declaration must be re-checked after Billing is integrated and before production submission.

## Final release sequence

1. Finish Play Billing integration and product configuration.
2. Configure upload signing key and Play App Signing.
3. Produce production-signed AAB from this release branch.
4. Upload to Internal testing.
5. Test clean install, upgrade from v0.8.4, Plus purchase/restore, language switching, backups, multi-project records, fund refunds and settlement.
6. Promote to Closed/Open testing as needed.
7. Complete store listing + policy forms.
8. Submit Production release for review.
