import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionService extends ChangeNotifier {
  static const String ownerMonthlyId = 'owner_monthly';
  static const String vansWeeklyId = 'vans_1_weekly';

  static const Set<String> _productIds = {
    ownerMonthlyId,
    vansWeeklyId,
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _ownerSubscribed = false;
  bool _vanSubscribed = false;
  bool _loading = true;
  String? _userId;

  // Getters
  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  bool get ownerSubscribed => _ownerSubscribed;
  bool get vanSubscribed => _vanSubscribed;
  bool get loading => _loading;

  ProductDetails? get ownerProduct =>
      _products.where((p) => p.id == ownerMonthlyId).firstOrNull;

  ProductDetails? get vanProduct =>
      _products.where((p) => p.id == vansWeeklyId).firstOrNull;

  SubscriptionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> initialize(String userId) async {
    _userId = userId;

    // Check if IAP is available
    _isAvailable = await _iap.isAvailable();

    if (_isAvailable) {
      // Load products
      final response = await _iap.queryProductDetails(_productIds);
      _products = response.productDetails;

      // Listen to purchase stream
      _purchaseSubscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (error) {
          debugPrint('Purchase stream error: $error');
        },
      );
    }

    // Load subscription status from Firestore
    await _loadSubscriptionStatus();

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadSubscriptionStatus() async {
    if (_userId == null) return;

    final doc =
        await _firestore.collection('subscriptions').doc(_userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _ownerSubscribed = data['ownerSubscribed'] == true;
      _vanSubscribed = data['vanSubscribed'] == true;
    }
    notifyListeners();
  }

  Future<void> _saveSubscriptionStatus() async {
    if (_userId == null) return;

    await _firestore.collection('subscriptions').doc(_userId).set({
      'ownerSubscribed': _ownerSubscribed,
      'vanSubscribed': _vanSubscribed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _verifyAndDeliver(purchase);
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    // For StoreKit 2, transactions are verified on-device
    if (purchase.productID == ownerMonthlyId) {
      _ownerSubscribed = true;
    } else if (purchase.productID == vansWeeklyId) {
      _vanSubscribed = true;
    }

    await _saveSubscriptionStatus();
    notifyListeners();
  }

  Future<bool> purchaseOwnerSubscription() async {
    final product = ownerProduct;
    if (product == null) return false;

    try {
      final param = PurchaseParam(productDetails: product);
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  Future<bool> purchaseVanPlan() async {
    final product = vanProduct;
    if (product == null) return false;

    try {
      final param = PurchaseParam(productDetails: product);
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  bool canAddVan() {
    return _ownerSubscribed && _vanSubscribed;
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
