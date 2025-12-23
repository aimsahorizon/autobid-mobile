import 'package:flutter/foundation.dart';
import '../../domain/entities/pricing_entity.dart';
import '../../domain/usecases/get_token_balance_usecase.dart';
import '../../domain/usecases/get_user_subscription_usecase.dart';
import '../../domain/usecases/get_token_packages_usecase.dart';
import '../../domain/usecases/purchase_token_package_usecase.dart';
import '../../domain/usecases/subscribe_to_plan_usecase.dart';

/// Controller for pricing and token management
class PricingController extends ChangeNotifier {
  final GetTokenBalanceUsecase getTokenBalanceUsecase;
  final GetUserSubscriptionUsecase getUserSubscriptionUsecase;
  final GetTokenPackagesUsecase getTokenPackagesUsecase;
  final PurchaseTokenPackageUsecase purchaseTokenPackageUsecase;
  final SubscribeToPlanUsecase subscribeToPlanUsecase;

  PricingController({
    required this.getTokenBalanceUsecase,
    required this.getUserSubscriptionUsecase,
    required this.getTokenPackagesUsecase,
    required this.purchaseTokenPackageUsecase,
    required this.subscribeToPlanUsecase,
  });

  // State
  TokenBalanceEntity? _tokenBalance;
  UserSubscriptionEntity? _subscription;
  List<TokenPackageEntity> _packages = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  TokenBalanceEntity? get tokenBalance => _tokenBalance;
  UserSubscriptionEntity? get subscription => _subscription;
  List<TokenPackageEntity> get packages => _packages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get biddingTokens => _tokenBalance?.biddingTokens ?? 0;
  int get listingTokens => _tokenBalance?.listingTokens ?? 0;
  SubscriptionPlan get currentPlan =>
      _subscription?.plan ?? SubscriptionPlan.free;
  bool get hasActivePlan => _subscription?.hasActivePlan ?? false;

  List<TokenPackageEntity> get biddingPackages =>
      _packages.where((p) => p.type == TokenType.bidding).toList();

  List<TokenPackageEntity> get listingPackages =>
      _packages.where((p) => p.type == TokenType.listing).toList();

  /// Load user's token balance and subscription
  Future<void> loadUserPricing(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      // Load balance and subscription in parallel
      final results = await Future.wait([
        getTokenBalanceUsecase.call(userId),
        getUserSubscriptionUsecase.call(userId),
        getTokenPackagesUsecase.call(),
      ]);

      _tokenBalance = results[0] as TokenBalanceEntity;
      _subscription = results[1] as UserSubscriptionEntity;
      _packages = results[2] as List<TokenPackageEntity>;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Purchase a token package
  Future<bool> purchasePackage({
    required String userId,
    required String packageId,
    required double amount,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _tokenBalance = await purchaseTokenPackageUsecase.call(
        userId: userId,
        packageId: packageId,
        amount: amount,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Subscribe to a plan
  Future<bool> subscribe({
    required String userId,
    required SubscriptionPlan plan,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _subscription = await subscribeToPlanUsecase.call(
        userId: userId,
        plan: plan,
      );

      // Reload balance to get updated tokens
      _tokenBalance = await getTokenBalanceUsecase.call(userId);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh user pricing data
  Future<void> refresh(String userId) async {
    await loadUserPricing(userId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
