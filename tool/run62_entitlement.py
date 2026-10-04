from pathlib import Path

p = Path('lib/features/premium/premium_service.dart')
s = p.read_text(encoding='utf-8')

s = s.replace(
    "  static const String entitlementKey = 'premium.entitled';\n",
    "  static const String entitlementKey = 'premium.entitled';\n  static const String entitlementSourceKey = 'premium.entitlementSource';\n",
    1,
)

old_init = """  Future<void> initialize() async {
    _isPremium = (await _repository.getSetting(entitlementKey)) == 'true';

    _purchaseSubscription ??= _iap.purchaseStream.listen(
"""
new_init = """  Future<void> initialize() async {
    final cachedEntitled = (await _repository.getSetting(entitlementKey)) == 'true';
    final cachedSource = await _repository.getSetting(entitlementSourceKey);
    // Debug entitlements must never leak into a release install. A release build
    // only trusts a cached entitlement that was previously confirmed by Play.
    _isPremium = kDebugMode
        ? cachedEntitled
        : cachedEntitled && cachedSource == 'google_play';

    _purchaseSubscription ??= _iap.purchaseStream.listen(
"""
if old_init not in s:
    raise SystemExit('Premium initialize marker not found')
s = s.replace(old_init, new_init, 1)

old_product_end = """        if (_product == null && _storeError == null) {
          _storeError = 'TripBanBan Plus product is not configured in Google Play.';
        }
      } else {
"""
new_product_end = """        if (_product == null && _storeError == null) {
          _storeError = 'TripBanBan Plus product is not configured in Google Play.';
        }
        if (!kDebugMode) {
          // Reconcile cached entitlement with current Google Play ownership.
          // If the purchase was refunded/revoked, no restored purchase will be
          // emitted and the release entitlement remains locked.
          _isPremium = false;
          await _repository.setSetting(entitlementKey, 'false');
          await _repository.setSetting(entitlementSourceKey, 'google_play');
          await _iap.restorePurchases();
        }
      } else {
"""
if old_product_end not in s:
    raise SystemExit('Premium product reconciliation marker not found')
s = s.replace(old_product_end, new_product_end, 1)

s = s.replace(
    "          await _setPremium(true);\n",
    "          await _setPremium(true, source: 'google_play');\n",
    1,
)

old_set = """  Future<void> _setPremium(bool value) async {
    _isPremium = value;
    await _repository.setSetting(entitlementKey, value.toString());
    notifyListeners();
  }

  Future<void> setDebugPremium(bool value) async {
"""
new_set = """  Future<void> _setPremium(bool value, {required String source}) async {
    _isPremium = value;
    await _repository.setSetting(entitlementKey, value.toString());
    await _repository.setSetting(entitlementSourceKey, source);
    notifyListeners();
  }

  Future<void> setDebugPremium(bool value) async {
"""
if old_set not in s:
    raise SystemExit('Premium set entitlement marker not found')
s = s.replace(old_set, new_set, 1)

s = s.replace(
    "    await _setPremium(value);\n",
    "    await _setPremium(value, source: 'debug');\n",
    1,
)

p.write_text(s, encoding='utf-8')
print('Run62 applied: release entitlements are reconciled with Google Play ownership')
