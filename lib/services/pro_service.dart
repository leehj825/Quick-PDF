import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time "Pro" unlock (no subscription).
class ProService {
  ProService._();
  static final ProService instance = ProService._();

  static const productId = 'quickpdf_pro';
  static const freePageLimit = 20;
  static const _key = 'quickpdf.pro';

  final ValueNotifier<bool> isPro = ValueNotifier(false);
  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    isPro.value = p.getBool(_key) ?? false;
    try {
      _sub = InAppPurchase.instance.purchaseStream.listen(_onPurchases, onError: (_) {});
    } catch (_) {}
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final d in list) {
      if (d.productID != productId) continue;
      if (d.status == PurchaseStatus.purchased || d.status == PurchaseStatus.restored) {
        final p = await SharedPreferences.getInstance();
        await p.setBool(_key, true);
        isPro.value = true;
      }
      if (d.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(d);
    }
  }

  /// Returns false if the store is unavailable or the product is not found.
  Future<bool> buy() async {
    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) return false;
    final res = await iap.queryProductDetails({productId});
    if (res.productDetails.isEmpty) return false;
    return iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: res.productDetails.first));
  }

  Future<void> restore() => InAppPurchase.instance.restorePurchases();

  void dispose() => _sub?.cancel();
}
