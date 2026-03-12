import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionService extends ChangeNotifier {
  static const String ownerMonthlyId = 'owner_monthly';
  static const String vans3WeeklyId = 'vans_3_weekly';
  static const String vans5WeeklyId = 'vans_5_weekly';
  static const String vans10WeeklyId = 'vans_10_weekly';
  static const String vans25WeeklyId = 'vans_25_weekly';

  static const Set<String> _productIds = {
    ownerMonthlyId,
    vans3WeeklyId,
    vans5WeeklyId,
    vans10WeeklyId,
    vans25WeeklyId,
  };

  static const Map<String, int> vanLimits = {
    vans3WeeklyId: 3,
    vans5WeeklyId: 5,
    vans10WeeklyId: 10,
    vans25WeeklyId: 25,
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _ownerSubscribed = false;
  String? _activeVanPlan;
  int _vanLimit = 0;
  bool _loading = true;
  String? _userId;

  // Getters
  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  bool get ownerSubscribed => _ownerSubscribed;
  String? get activeVanPlan => _activeVanPlan;
  int get vanLimit => _vanLimit;
  bool get loading => _loading;

  ProductDetails? get ownerProduct =>
      _products.where((p) => p.id == ownerMonthlyId).firstOrNull;

  List<ProductDetails> get vanProducts =>
      _products.where((p) => p.id != ownerMonthlyId).toList()
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

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
      _activeVanPlan = data['activeVanPlan'];
      _vanLimit = data['vanLimit'] ?? 0;
    }
    notifyListeners();
  }

  Future<void> _saveSubscriptionStatus() async {
    if (_userId == null) return;

    await _firestore.collection('subscriptions').doc(_userId).set({
      'ownerSubscribed': _ownerSubscribed,
      'activeVanPlan': _activeVanPlan,
      'vanLimit': _vanLimit,
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
    } else if (vanLimits.containsKey(purchase.productID)) {
      _activeVanPlan = purchase.productID;
      _vanLimit = vanLimits[purchase.productID]!;
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

  Future<bool> purchaseVanPlan(String productId) async {
    final product = _products.where((p) => p.id == productId).firstOrNull;
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

  bool canAddVan(int currentVanCount) {
    if (!_ownerSubscribed) return false;
    if (_vanLimit == 0) return false;
    return currentVanCount < _vanLimit;
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
