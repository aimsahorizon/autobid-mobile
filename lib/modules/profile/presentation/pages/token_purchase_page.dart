import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/pricing_entity.dart';
import 'package:autobid_mobile/modules/profile/presentation/controllers/pricing_controller.dart';
import 'package:autobid_mobile/modules/profile/presentation/pages/paymongo_payment_page.dart';

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
    // Navigate to PayMongo payment page
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PayMongoPaymentPage(
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
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Text('Successfully purchased ${package.description}'),
          backgroundColor: ColorConstants.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Tokens')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.error != null) {
            return Center(child: Text(widget.controller.error!));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bidding Tokens Section
                Text(
                  'Bidding Tokens',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Each bid consumes 1 bidding token',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? ColorConstants.textSecondaryDark : ColorConstants.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildBiddingTokenCard(
                        title: '5 Bidding Tokens',
                        price: 99,
                        icon: Icons.gavel,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBiddingTokenCard(
                        title: '25 Bidding Tokens',
                        price: 349,
                        icon: Icons.gavel,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBiddingTokenCard(
                  title: '100 Bidding Tokens',
                  price: 1299,
                  icon: Icons.gavel,
                  isDark: isDark,
                  theme: theme,
                  isFullWidth: true,
                  badgeText: 'MOST POPULAR',
                  subtitle: '₱12.99/ea',
                ),

                const SizedBox(height: 32),

                // Listing Tokens Section
                Text(
                  'Listing Tokens',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Each listing submission consumes 1 listing token',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? ColorConstants.textSecondaryDark : ColorConstants.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end, // Align to bottom to handle badge height differences
                  children: [
                    Expanded(
                      child: _buildListingTokenCard(
                        title: '1 Listing Token',
                        price: 199,
                        subtitle: 'Single Use',
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildListingTokenCard(
                        title: '3 Listing Token',
                        price: 499,
                        subtitle: 'Save 16%',
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildListingTokenCard(
                        title: '10 Listing Token',
                        price: 1499,
                        subtitle: 'Single Use',
                        isDark: isDark,
                        theme: theme,
                        badgeText: 'BEST VALUE',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Secure checkout via top methods  [ GCash | VISA | Mastercard ]',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBiddingTokenCard({
    required String title,
    required double price,
    required IconData icon,
    required bool isDark,
    required ThemeData theme,
    bool isFullWidth = false,
    String? badgeText,
    String? subtitle,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? ColorConstants.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isFullWidth)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Icon(icon, color: ColorConstants.primary, size: 64),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                    Icon(icon, color: ColorConstants.primary, size: 32),
                  ],
                ),
              SizedBox(height: isFullWidth ? 8 : 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₱${price.toStringAsFixed(0)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      if (subtitle != null)
                        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Buy'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (badgeText != null)
          Positioned(
            top: -10,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ColorConstants.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListingTokenCard({
    required String title,
    required double price,
    required String subtitle,
    required bool isDark,
    required ThemeData theme,
    String? badgeText,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(top: badgeText != null ? 10 : 0),
          decoration: BoxDecoration(
            color: isDark ? ColorConstants.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: const BoxDecoration(
                  color: ColorConstants.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    Text(
                      title.replaceFirst(' ', '\n'), // break after number
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, height: 1.2),
                    ),
                    const SizedBox(height: 16),
                    const Icon(Icons.receipt_long, color: Colors.white, size: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text('₱${price.toStringAsFixed(0)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Buy'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (badgeText != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorConstants.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
