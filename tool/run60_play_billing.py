from pathlib import Path

# Add the official Flutter IAP package. v3.3.x uses Android Billing Library 8.x.
p = Path('pubspec.yaml')
s = p.read_text(encoding='utf-8')
if '  in_app_purchase:' not in s:
    marker = '  intl: ^0.20.2\n'
    if marker not in s:
        raise SystemExit('pubspec intl marker not found')
    s = s.replace(marker, marker + '  in_app_purchase: ^3.3.0\n', 1)
p.write_text(s, encoding='utf-8')

premium = r'''import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../data/repositories/ledger_repository.dart';

/// Central entitlement gate for TripBanBan Plus.
///
/// Release builds use Google Play Billing. Debug builds retain a local
/// entitlement switch so sideloaded development APKs can exercise Plus flows.
class PremiumService extends ChangeNotifier {
  PremiumService(this._repository);

  static const String entitlementKey = 'premium.entitled';
  static const String productId = 'tripbanban_plus_lifetime';
  static const String productLabel = 'TripBanBan Plus';
  static const String priceLabel = 'US\$1.99';

  final LedgerRepository _repository;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _product;
  bool _isPremium = false;
  bool _storeAvailable = false;
  String? _storeError;

  bool get isPremium => _isPremium;
  bool get canUseDebugToggle => kDebugMode;
  bool get storeAvailable => _storeAvailable;
  bool get canPurchase => _storeAvailable && _product != null;
  String get displayPrice => _product?.price ?? priceLabel;
  String? get storeError => _storeError;

  Future<void> initialize() async {
    _isPremium = (await _repository.getSetting(entitlementKey)) == 'true';

    _purchaseSubscription ??= _iap.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchases(purchases)),
      onError: (Object error) {
        _storeError = '$error';
        notifyListeners();
      },
    );

    try {
      _storeAvailable = await _iap.isAvailable();
      if (_storeAvailable) {
        final response = await _iap.queryProductDetails(const {productId});
        if (response.error != null) {
          _storeError = response.error!.message;
        }
        for (final product in response.productDetails) {
          if (product.id == productId) {
            _product = product;
            break;
          }
        }
        if (_product == null && _storeError == null) {
          _storeError = 'TripBanBan Plus product is not configured in Google Play.';
        }
      } else {
        _storeError = 'Google Play Billing is unavailable on this device.';
      }
    } catch (error) {
      _storeError = '$error';
    }
    notifyListeners();
  }

  Future<void> purchasePlus() async {
    if (_isPremium) return;
    final product = _product;
    if (!_storeAvailable || product == null) {
      throw StateError(_storeError ?? 'TripBanBan Plus is unavailable.');
    }
    final launched = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!launched) {
      throw StateError('Google Play did not start the purchase flow.');
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      throw StateError(_storeError ?? 'Google Play Billing is unavailable.');
    }
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setPremium(true);
          _storeError = null;
          break;
        case PurchaseStatus.error:
          _storeError = purchase.error?.message ?? 'Purchase failed.';
          break;
        case PurchaseStatus.canceled:
        case PurchaseStatus.pending:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  Future<void> _setPremium(bool value) async {
    _isPremium = value;
    await _repository.setSetting(entitlementKey, value.toString());
    notifyListeners();
  }

  Future<void> setDebugPremium(bool value) async {
    if (!kDebugMode) {
      throw StateError('Debug premium override is not available in release builds.');
    }
    await _setPremium(value);
  }

  @override
  void dispose() {
    final subscription = _purchaseSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    super.dispose();
  }
}
'''
Path('lib/features/premium/premium_service.dart').write_text(premium, encoding='utf-8')

# Dispose Billing stream together with application services.
p = Path('lib/app/app_services.dart')
s = p.read_text(encoding='utf-8')
s = s.replace(
    '  Future<void> dispose() => db.close();',
    '  Future<void> dispose() async {\n    premium.dispose();\n    await db.close();\n  }',
)
p.write_text(s, encoding='utf-8')

# Add billing-specific localized UI strings as the highest-priority layer.
p = Path('lib/localization/app_strings.dart')
s = p.read_text(encoding='utf-8')
needle = "    final extra = _extraValues[languageCode]?[key];\n    if (extra != null) return extra;\n"
replacement = "    final billing = _run60[languageCode]?[key];\n    if (billing != null) return billing;\n    final extra = _extraValues[languageCode]?[key];\n    if (extra != null) return extra;\n"
if needle not in s:
    raise SystemExit('AppStrings run60 insertion target not found')
s = s.replace(needle, replacement, 1)

run60 = r'''  static const Map<String, Map<String, String>> _run60 = {
    'en': {
      'buyPlus': 'Buy Plus',
      'restorePurchase': 'Restore purchase',
      'purchaseUnavailable': 'Google Play purchase is unavailable. Please try again later.',
    },
    'zh_Hant': {
      'buyPlus': '購買 Plus',
      'restorePurchase': '恢復購買',
      'purchaseUnavailable': '目前無法連線至 Google Play 商品，請稍後再試。',
    },
    'zh_Hans': {
      'buyPlus': '购买 Plus',
      'restorePurchase': '恢复购买',
      'purchaseUnavailable': '目前无法连接 Google Play 商品，请稍后再试。',
    },
    'ja': {
      'buyPlus': 'Plusを購入',
      'restorePurchase': '購入を復元',
      'purchaseUnavailable': '現在 Google Play の商品を取得できません。後でもう一度お試しください。',
    },
    'ko': {
      'buyPlus': 'Plus 구매',
      'restorePurchase': '구매 복원',
      'purchaseUnavailable': '현재 Google Play 상품을 불러올 수 없습니다. 나중에 다시 시도하세요.',
    },
    'fr': {
      'buyPlus': 'Acheter Plus',
      'restorePurchase': 'Restaurer l’achat',
      'purchaseUnavailable': 'L’achat Google Play est indisponible. Réessayez plus tard.',
    },
    'de': {
      'buyPlus': 'Plus kaufen',
      'restorePurchase': 'Kauf wiederherstellen',
      'purchaseUnavailable': 'Der Google-Play-Kauf ist derzeit nicht verfügbar. Bitte später erneut versuchen.',
    },
    'es': {
      'buyPlus': 'Comprar Plus',
      'restorePurchase': 'Restaurar compra',
      'purchaseUnavailable': 'La compra de Google Play no está disponible. Inténtalo de nuevo más tarde.',
    },
    'it': {
      'buyPlus': 'Acquista Plus',
      'restorePurchase': 'Ripristina acquisto',
      'purchaseUnavailable': 'L’acquisto Google Play non è disponibile. Riprova più tardi.',
    },
    'th': {
      'buyPlus': 'ซื้อ Plus',
      'restorePurchase': 'กู้คืนการซื้อ',
      'purchaseUnavailable': 'ขณะนี้ไม่สามารถซื้อผ่าน Google Play ได้ โปรดลองอีกครั้งภายหลัง',
    },
  };

'''
marker = '  static const Map<String, Map<String, String>> _run50 = '
if marker not in s:
    raise SystemExit('AppStrings run50 marker not found')
s = s.replace(marker, run60 + marker, 1)
p.write_text(s, encoding='utf-8')

# The settings screen is produced by run55 immediately before this patch.
p = Path('lib/screens/settings_screen.dart')
s = p.read_text(encoding='utf-8')

state_marker = 'class _SettingsScreenState extends State<SettingsScreen> {\n  bool busy = false;\n'
state_replacement = '''class _SettingsScreenState extends State<SettingsScreen> {
  bool busy = false;

  @override
  void initState() {
    super.initState();
    widget.controller.services.premium.addListener(_onPremiumChanged);
  }

  @override
  void dispose() {
    widget.controller.services.premium.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onPremiumChanged() {
    if (mounted) setState(() {});
  }
'''
if state_marker not in s:
    raise SystemExit('Settings state marker not found')
s = s.replace(state_marker, state_replacement, 1)

s = s.replace(
    "                          : '${PremiumService.productLabel} · ${PremiumService.priceLabel}',",
    "                          : '${PremiumService.productLabel} · ${premium.displayPrice}',",
    1,
)

old_purchase = '''              ] else if (!premium.isPremium) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: null, child: Text(strings.t('purchaseSoon'))),
                ),
              ],'''
new_purchase = '''              ] else if (!premium.isPremium) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy || !premium.canPurchase ? null : _purchasePlus,
                    child: Text('${strings.t('buyPlus')} · ${premium.displayPrice}'),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: busy || !premium.storeAvailable ? null : _restorePurchases,
                    child: Text(strings.t('restorePurchase')),
                  ),
                ),
                if (!premium.canPurchase)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(strings.t('purchaseUnavailable'), style: const TextStyle(fontSize: 12)),
                  ),
              ],'''
if old_purchase not in s:
    raise SystemExit('Settings purchase block not found')
s = s.replace(old_purchase, new_purchase, 1)

s = s.replace(
    "subtitle: Text('${strings.t('localImportExport')} · ${PremiumService.priceLabel}'),",
    "subtitle: Text('${strings.t('localImportExport')} · ${premium.displayPrice}'),",
    1,
)

method_marker = '  Future<void> _toggleDebugPremium(bool value) async {\n'
method_block = '''  Future<void> _purchasePlus() => _run(() async {
        await widget.controller.services.premium.purchasePlus();
      });

  Future<void> _restorePurchases() => _run(() async {
        await widget.controller.services.premium.restorePurchases();
      });

'''
if method_marker not in s:
    raise SystemExit('Settings method marker not found')
s = s.replace(method_marker, method_block + method_marker, 1)
p.write_text(s, encoding='utf-8')

print('Run60 applied: Google Play Billing lifetime Plus integration')
