import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionService extends ChangeNotifier {
  static const String ownerMonthlyId = 'owner_monthly';

  // Van tier product IDs — note: 3, 5, 10 use no underscore (Apple reuse restriction)
  static const Map<int, String> vanTierProducts = {
    1: 'vans_1_weekly',
    2: 'vans_2_weekly',
    3: 'vans3_weekly',
    4: 'vans_4_weekly',
    5: 'vans5_weekly',
    6: 'vans_6_weekly',
    7: 'vans_7_weekly',
    8: 'vans_8_weekly',
    9: 'vans_9_weekly',
    10: 'vans10_weekly',
    15: 'vans_15_weekly',
    20: 'vans_20_weekly',
  };

  // Sorted tier counts for upgrade/downgrade lookups
  static final List<int> _sortedTiers = vanTierProducts.keys.toList()..sort();

  static Set<String> get _productIds => {
        ownerMonthlyId,
        ...vanTierProducts.values,
      };

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _ownerSubscribed = false;
  String? _activeVanProductId;
  bool _loading = true;
  String? _userId;

  // Getters
  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  bool get ownerSubscribed => _ownerSubscribed;
  bool get loading => _loading;

  /// Current van limit based on active tier (0 if no van subscription)
  int get vanLimit {
    if (_activeVanProductId == null) return 0;
    for (final entry in vanTierProducts.entries) {
      if (entry.value == _activeVanProductId) return entry.key;
    }
    return 0;
  }

  /// Whether the user has any van subscription
  bool get vanSubscribed => _activeVanProductId != null;

  /// The active van tier product ID
  String? get activeVanProductId => _activeVanProductId;

  ProductDetails? get ownerProduct =>
      _products.where((p) => p.id == ownerMonthlyId).firstOrNull;

  /// Get ProductDetails for a specific van tier
  ProductDetails? vanProductForTier(int tierCount) {
    final productId = vanTierProducts[tierCount];
    if (productId == null) return null;
    return _products.where((p) => p.id == productId).firstOrNull;
  }

  /// Find the right tier for a given van count
  static int tierForVanCount(int vanCount) {
    for (final tier in _sortedTiers) {
      if (tier >= vanCount) return tier;
    }
    return _sortedTiers.last; // max tier
  }

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
      _activeVanProductId = data['activeVanProductId'];
    }
    notifyListeners();
  }

  Future<void> _saveSubscriptionStatus() async {
    if (_userId == null) return;

    await _firestore.collection('subscriptions').doc(_userId).set({
      'ownerSubscribed': _ownerSubscribed,
      'activeVanProductId': _activeVanProductId,
      'vanLimit': vanLimit,
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
    if (purchase.productID == ownerMonthlyId) {
      _ownerSubscribed = true;
    } else if (vanTierProducts.values.contains(purchase.productID)) {
      _activeVanProductId = purchase.productID;
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

  /// Purchase or upgrade to a specific van tier
  Future<bool> purchaseVanTier(int tierCount) async {
    final productId = vanTierProducts[tierCount];
    if (productId == null) return false;

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

  /// Check if the user can add a van (has room in current tier)
  bool canAddVan(int currentVanCount) {
    if (!_ownerSubscribed) return false;
    if (!vanSubscribed) return false;
    return currentVanCount < vanLimit;
  }

  /// Check if adding a van requires a tier upgrade
  bool needsUpgrade(int currentVanCount) {
    if (!vanSubscribed) return true;
    return currentVanCount >= vanLimit;
  }

  /// Get the next tier needed if the user wants to add a van
  int? nextTierForAddingVan(int currentVanCount) {
    final needed = currentVanCount + 1;
    return tierForVanCount(needed);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
