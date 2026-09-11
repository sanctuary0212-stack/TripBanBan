import 'package:flutter/foundation.dart';

import '../../data/repositories/ledger_repository.dart';

/// Central entitlement gate for TripBanBan Plus.
///
/// The debug switch exists only so sideloaded development APKs can exercise
/// paid-only flows before the Google Play product is configured. Release
/// builds never expose the debug entitlement switch.
class PremiumService {
  PremiumService(this._repository);

  static const String entitlementKey = 'premium.entitled';
  static const String productLabel = 'TripBanBan Plus';
  static const String priceLabel = 'US\$1.99';

  final LedgerRepository _repository;
  bool _isPremium = false;

  bool get isPremium => _isPremium;
  bool get canUseDebugToggle => kDebugMode;

  Future<void> initialize() async {
    _isPremium = (await _repository.getSetting(entitlementKey)) == 'true';
  }

  Future<void> setDebugPremium(bool value) async {
    if (!kDebugMode) {
      throw StateError('Debug premium override is not available in release builds.');
    }
    _isPremium = value;
    await _repository.setSetting(entitlementKey, value.toString());
  }
}
