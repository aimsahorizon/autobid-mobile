import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/pricing_entity.dart';
import '../controllers/pricing_controller.dart';

class PricingSection extends StatelessWidget {
  final PricingController pricingController;
  final VoidCallback onManageTokens;
  final VoidCallback onManageSubscription;

  const PricingSection({
    super.key,
    required this.pricingController,
    required this.onManageTokens,
    required this.onManageSubscription,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tokens & Subscription',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Token Balance Card
          ListenableBuilder(
            listenable: pricingController,
            builder: (context, _) {
              if (pricingController.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return Column(
                children: [
                  // Token balances
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [ColorConstants.primary, ColorConstants.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.gavel, color: Colors.white70, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Bidding',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${pricingController.biddingTokens}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.format_list_bulleted, color: Colors.white70, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Listing',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${pricingController.listingTokens}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Current subscription
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? ColorConstants.backgroundDark
                          : ColorConstants.backgroundSecondaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pricingController.hasActivePlan
                            ? ColorConstants.primary.withValues(alpha: 0.3)
                            : (isDark ? ColorConstants.borderDark : ColorConstants.borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pricingController.hasActivePlan
                              ? Icons.workspace_premium
                              : Icons.card_membership_outlined,
                          color: pricingController.hasActivePlan
                              ? ColorConstants.primary
                              : (isDark ? ColorConstants.textSecondaryDark : ColorConstants.textSecondaryLight),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pricingController.currentPlan.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (pricingController.hasActivePlan) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '₱${pricingController.currentPlan.price.toStringAsFixed(0)}${pricingController.currentPlan.isYearly ? '/year' : '/month'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? ColorConstants.textSecondaryDark
                                        : ColorConstants.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (pricingController.hasActivePlan)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ColorConstants.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                color: ColorConstants.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManageTokens,
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Buy Tokens'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onManageSubscription,
                  icon: const Icon(Icons.workspace_premium, size: 18),
                  label: const Text('Subscription'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
