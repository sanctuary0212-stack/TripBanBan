import 'package:flutter/material.dart';

import '../data/local/app_database.dart';
import 'app_services.dart';

class AppController extends ChangeNotifier {
  AppController(this.services);

  static const _languageKey = 'app.language';
  static const _defaultCurrencyKey = 'app.defaultCurrency';
  static const _selectedTripKey = 'app.selectedTripId';

  final AppServices services;

  String _languageCode = 'zh_Hant';
  String _defaultCurrency = 'TWD';
  String? _selectedTripId;
  bool _initialized = false;

  bool get initialized => _initialized;
  String get languageCode => _languageCode;
  String get defaultCurrency => _defaultCurrency;
  String? get selectedTripId => _selectedTripId;

  Locale get locale => switch (_languageCode) {
        'zh_Hans' => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        'en' => const Locale('en'),
        'ja' => const Locale('ja'),
        'ko' => const Locale('ko'),
        _ => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      };

  Future<void> initialize() async {
    _languageCode = await services.repository.getSetting(_languageKey) ?? 'zh_Hant';
    _defaultCurrency = await services.repository.getSetting(_defaultCurrencyKey) ?? 'TWD';
    _selectedTripId = await services.repository.getSetting(_selectedTripKey);
    if (_selectedTripId?.trim().isEmpty == true) _selectedTripId = null;

    if (_selectedTripId != null && await services.repository.getTrip(_selectedTripId!) == null) {
      _selectedTripId = null;
    }
    if (_selectedTripId == null) {
      final trips = await services.repository.watchTrips().first;
      if (trips.isNotEmpty) _selectedTripId = trips.first.id;
    }

    await services.premium.initialize();
    await services.fx.ensureBootstrapRates();
    _initialized = true;
    notifyListeners();
  }

  Future<TripRow?> selectedTrip() async {
    final id = _selectedTripId;
    return id == null ? null : services.repository.getTrip(id);
  }

  Future<void> selectTrip(String? tripId) async {
    _selectedTripId = tripId;
    if (tripId == null) {
      await services.repository.setSetting(_selectedTripKey, '');
    } else {
      await services.repository.setSetting(_selectedTripKey, tripId);
    }
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (!const {'zh_Hant', 'zh_Hans', 'en', 'ja', 'ko'}.contains(code)) return;
    _languageCode = code;
    await services.repository.setSetting(_languageKey, code);
    notifyListeners();
  }

  Future<void> setDefaultCurrency(String code) async {
    _defaultCurrency = code.toUpperCase();
    await services.repository.setSetting(_defaultCurrencyKey, _defaultCurrency);
    notifyListeners();
  }

  Future<void> onTripDeleted(String tripId) async {
    if (_selectedTripId != tripId) return;
    final trips = await services.repository.watchTrips().first;
    _selectedTripId = trips.isEmpty ? null : trips.first.id;
    if (_selectedTripId != null) {
      await services.repository.setSetting(_selectedTripKey, _selectedTripId!);
    }
    notifyListeners();
  }
}
