import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/pricing_entity.dart';
import 'package:autobid_mobile/modules/profile/presentation/controllers/pricing_controller.dart';
import 'package:autobid_mobile/modules/profile/presentation/pages/subscription_payment_page.dart';

class SubscriptionPage extends StatefulWidget {
  final String userId;
  final PricingController controller;

  const SubscriptionPage({
    super.key,
    required this.userId,
    required this.controller,
  });

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadUserPricing(widget.userId);
    });
  }

  Future<void> _subscribeToPlan(SubscriptionPlan plan) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Subscription'),
        content: Text(
          'Subscribe to ${plan.name} for ₱${plan.price.toStringAsFixed(0)}${plan.isYearly ? '/year' : '/month'}?\n\n'
          'You will receive:\n'
          '• ${plan.biddingTokens} bidding tokens${plan.isYearly ? ' monthly' : ''}\n'
          '• ${plan.listingTokens} listing tokens${plan.isYearly ? ' monthly' : ''}'
          '${plan.includesAutoBid ? '\n• Auto-bid access' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Handle Paid Plans via PayMongo
    if (plan != SubscriptionPlan.free) {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionPaymentPage(
            plan: plan,
            userId: widget.userId,
            onSuccess: () => _processSubscription(plan),
          ),
        ),
      );
    } else {
      // Free plan - proceed directly
      await _processSubscription(plan);
    }
  }

  Future<void> _processSubscription(SubscriptionPlan plan) async {
    // Process subscription with controller
    final success = await widget.controller.subscribe(
      userId: widget.userId,
      plan: plan,
    );

    if (mounted) {
      if (success) {
        (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
          SnackBar(
            content: Text('Successfully subscribed to ${plan.name}'),
            backgroundColor: ColorConstants.success,
          ),
        );
      } else {
        (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
          SnackBar(
            content: Text(widget.controller.error ?? 'Subscription failed'),
            backgroundColor: ColorConstants.error,
          ),
        );
      }
    }
  }

  Widget _buildTabButton(String title, int index, bool isDark) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? ColorConstants.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Current subscription card
                if (widget.controller.subscription != null)
                  _CurrentSubscriptionCard(
                    subscription: widget.controller.subscription!,
                    isDark: isDark,
                  ),
                const SizedBox(height: 24),

                // Plan selection
                Text(
                  'Available Plans',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton('FREE', 0, isDark),
                      _buildTabButton('SILVER', 1, isDark),
                      _buildTabButton('GOLD', 2, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_selectedTabIndex == 0) ...[
                  _PlanCard(
                    plan: SubscriptionPlan.free,
                    isCurrentPlan: widget.controller.currentPlan == SubscriptionPlan.free,
                    onSubscribe: () => _subscribeToPlan(SubscriptionPlan.free),
                    isDark: isDark,
                    titleOverride: 'Package One',
                    subtitleOverride: 'Standard',
                  ),
                ] else if (_selectedTabIndex == 1) ...[
                  _PlanCard(
                    plan: SubscriptionPlan.silverMonthly,
                    isCurrentPlan: widget.controller.currentPlan == SubscriptionPlan.silverMonthly,
                    onSubscribe: () => _subscribeToPlan(SubscriptionPlan.silverMonthly),
                    isDark: isDark,
                    titleOverride: 'Package One',
                    subtitleOverride: 'Monthly',
                  ),
                  const SizedBox(height: 16),
                  _PlanCard(
                    plan: SubscriptionPlan.silverYearly,
                    isCurrentPlan: widget.controller.currentPlan == SubscriptionPlan.silverYearly,
                    onSubscribe: () => _subscribeToPlan(SubscriptionPlan.silverYearly),
                    isDark: isDark,
                    titleOverride: 'Package Two',
                    subtitleOverride: 'Yearly',
                  ),
                ] else if (_selectedTabIndex == 2) ...[
                  _PlanCard(
                    plan: SubscriptionPlan.goldMonthly,
                    isCurrentPlan: widget.controller.currentPlan == SubscriptionPlan.goldMonthly,
                    onSubscribe: () => _subscribeToPlan(SubscriptionPlan.goldMonthly),
                    isDark: isDark,
                    titleOverride: 'Package One',
                    subtitleOverride: 'Monthly',
                  ),
                  const SizedBox(height: 16),
                  _PlanCard(
                    plan: SubscriptionPlan.goldYearly,
                    isCurrentPlan: widget.controller.currentPlan == SubscriptionPlan.goldYearly,
                    onSubscribe: () => _subscribeToPlan(SubscriptionPlan.goldYearly),
                    isDark: isDark,
                    isRecommended: true,
                    savingsPercent: 16,
                    titleOverride: 'Package Two',
                    subtitleOverride: 'Yearly',
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CurrentSubscriptionCard extends StatelessWidget {
  final UserSubscriptionEntity subscription;
  final bool isDark;

  const _CurrentSubscriptionCard({
    required this.subscription,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
          Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Current Plan',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            subscription.plan.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subscription.plan != SubscriptionPlan.free) ...[
            const SizedBox(height: 8),
            Text(
              '₱${subscription.plan.price.toStringAsFixed(0)}${subscription.plan.isYearly ? '/year' : '/month'}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            if (subscription.endDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Renews on ${_formatDate(subscription.endDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrentPlan;
  final VoidCallback onSubscribe;
  final bool isDark;
  final bool isRecommended;
  final int? savingsPercent;
  final String titleOverride;
  final String subtitleOverride;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.onSubscribe,
    required this.isDark,
    this.isRecommended = false,
    this.savingsPercent,
    required this.titleOverride,
    required this.subtitleOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> leftFeatures = [
      _FeatureRow(icon: Icons.gavel, text: '${plan.biddingTokens} bidding tokens'),
      const SizedBox(height: 8),
      _FeatureRow(icon: Icons.format_list_bulleted, text: '${plan.listingTokens} listing tokens'),
    ];

    final List<Widget> rightFeatures = [];
    if (plan.includesAutoBid) {
      rightFeatures.add(const _FeatureRow(icon: Icons.auto_awesome, text: 'Auto-bid access'));
      rightFeatures.add(const SizedBox(height: 8));
    }
    if (plan != SubscriptionPlan.free) {
      rightFeatures.add(const _FeatureRow(icon: Icons.add_shopping_cart, text: 'Buy additional token packs anytime'));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: isRecommended ? const EdgeInsets.only(top: 12) : null,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? ColorConstants.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentPlan || isRecommended
                  ? ColorConstants.primary.withValues(alpha: 0.3)
                  : (isDark ? ColorConstants.borderDark : ColorConstants.borderLight),
              width: isCurrentPlan || isRecommended ? 2 : 1,
            ),
            boxShadow: isCurrentPlan || isRecommended
                ? [
                    BoxShadow(
                      color: ColorConstants.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.radio_button_unchecked,
                    color: isCurrentPlan || isRecommended ? ColorConstants.primary : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleOverride,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          subtitleOverride,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ColorConstants.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: Text(
                      plan == SubscriptionPlan.free ? 'FREE' : '₱${plan.price.toStringAsFixed(0)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: ColorConstants.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: leftFeatures)),
                  if (rightFeatures.isNotEmpty) const SizedBox(width: 16),
                  if (rightFeatures.isNotEmpty) Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rightFeatures)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: isCurrentPlan
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? ColorConstants.surfaceVariantDark : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Current Plan', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                      )
                    : FilledButton(
                        onPressed: onSubscribe,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(plan == SubscriptionPlan.free ? 'Downgrade' : 'Subscribe'),
                      ),
              ),
            ],
          ),
        ),
        if (isRecommended && savingsPercent != null)
          Positioned(
            top: 2,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ColorConstants.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('POPULAR ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
                    child: Text('SAVE $savingsPercent%', style: const TextStyle(color: ColorConstants.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: ColorConstants.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
