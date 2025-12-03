import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/pricing_entity.dart';
import '../controllers/pricing_controller.dart';
import 'payment_page.dart';

class TokenPurchasePage extends StatefulWidget {
  final String userId;
  final PricingController controller;

  const TokenPurchasePage({
    super.key,
    required this.userId,
    required this.controller,
  });

  @override
  State<TokenPurchasePage> createState() => _TokenPurchasePageState();
}

class _TokenPurchasePageState extends State<TokenPurchasePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadUserPricing(widget.userId);
    });
  }

  Future<void> _purchasePackage(TokenPackageEntity package) async {
    // Navigate to payment page
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          package: package,
          userId: widget.userId,
          onSuccess: () {
            // Reload pricing data after successful payment
            widget.controller.loadUserPricing(widget.userId);
          },
        ),
      ),
    );

    // If payment was successful, show success message
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully purchased ${package.description}'),
          backgroundColor: ColorConstants.success,
        ),
      );
    }
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Tokens'),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error if there is one
          if (widget.controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: ColorConstants.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading packages',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.controller.error!,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => widget.controller.loadUserPricing(widget.userId),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Check if packages are empty
          if (widget.controller.biddingPackages.isEmpty &&
              widget.controller.listingPackages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No packages available',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => widget.controller.loadUserPricing(widget.userId),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current balance card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ColorConstants.primary, ColorConstants.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Token Balance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bidding Tokens',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.controller.biddingTokens.toString(),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Listing Tokens',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.controller.listingTokens.toString(),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Bidding tokens section
                Text(
                  'Bidding Tokens',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Each bid consumes 1 bidding token',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? ColorConstants.textSecondaryDark : ColorConstants.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                ...widget.controller.biddingPackages.map((package) => _PackageCard(
                  package: package,
                  onPurchase: () => _purchasePackage(package),
                  isDark: isDark,
                )),
                const SizedBox(height: 32),

                // Listing tokens section
                Text(
                  'Listing Tokens',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Each listing submission consumes 1 listing token',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? ColorConstants.textSecondaryDark : ColorConstants.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                ...widget.controller.listingPackages.map((package) => _PackageCard(
                  package: package,
                  onPurchase: () => _purchasePackage(package),
                  isDark: isDark,
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final TokenPackageEntity package;
  final VoidCallback onPurchase;
  final bool isDark;

  const _PackageCard({
    required this.package,
    required this.onPurchase,
    required this.isDark,
  });

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstants.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              package.type == TokenType.bidding ? Icons.gavel : Icons.format_list_bulleted,
              color: ColorConstants.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.description,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (package.bonusTokens > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+${package.bonusTokens} bonus tokens',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ColorConstants.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${_formatPrice(package.price)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.primary,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: onPurchase,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text('Buy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
