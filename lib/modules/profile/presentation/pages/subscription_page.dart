import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../domain/entities/pricing_entity.dart';
import '../controllers/pricing_controller.dart';
import 'subscription_payment_page.dart';

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
          '• ${plan.listingTokens} listing tokens${plan.isYearly ? ' monthly' : ''}',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully subscribed to ${plan.name}'),
            backgroundColor: ColorConstants.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.controller.error ?? 'Subscription failed'),
            backgroundColor: ColorConstants.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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

                // Free plan
                _PlanCard(
                  plan: SubscriptionPlan.free,
                  isCurrentPlan: widget.controller.currentPlan == SubscriptionPlan.free,
                  onSubscribe: () => _subscribeToPlan(SubscriptionPlan.free),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Monthly plans
                Text(
                  'Monthly Plans',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  plan: SubscriptionPlan.proBasicMonthly,
                  isCurrentPlan: widget.controller.currentPlan == SubscriptionPlan.proBasicMonthly,
                  onSubscribe: () => _subscribeToPlan(SubscriptionPlan.proBasicMonthly),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  plan: SubscriptionPlan.proPlusMonthly,
                  isCurrentPlan: widget.controller.currentPlan == SubscriptionPlan.proPlusMonthly,
                  onSubscribe: () => _subscribeToPlan(SubscriptionPlan.proPlusMonthly),
                  isDark: isDark,
                  isRecommended: true,
                ),
                const SizedBox(height: 24),

                // Yearly plans
                Text(
                  'Yearly Plans (Save more)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  plan: SubscriptionPlan.proBasicYearly,
                  isCurrentPlan: widget.controller.currentPlan == SubscriptionPlan.proBasicYearly,
                  onSubscribe: () => _subscribeToPlan(SubscriptionPlan.proBasicYearly),
                  isDark: isDark,
                  savingsPercent: 29,
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  plan: SubscriptionPlan.proPlusYearly,
                  isCurrentPlan: widget.controller.currentPlan == SubscriptionPlan.proPlusYearly,
                  onSubscribe: () => _subscribeToPlan(SubscriptionPlan.proPlusYearly),
                  isDark: isDark,
                  savingsPercent: 25,
                ),
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
              const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
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
                  const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
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

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.onSubscribe,
    required this.isDark,
    this.isRecommended = false,
    this.savingsPercent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan || isRecommended
              ? ColorConstants.primary
              : (isDark ? ColorConstants.borderDark : ColorConstants.borderLight),
          width: isCurrentPlan || isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ColorConstants.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'POPULAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (plan != SubscriptionPlan.free) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₱${plan.price.toStringAsFixed(0)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: ColorConstants.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            plan.isYearly ? '/year' : '/month',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? ColorConstants.textSecondaryDark : ColorConstants.textSecondaryLight,
                            ),
                          ),
                          if (savingsPercent != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: ColorConstants.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Save $savingsPercent%',
                                style: TextStyle(
                                  color: ColorConstants.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else
                      const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FeatureRow(icon: Icons.gavel, text: '${plan.biddingTokens} bidding tokens${plan != SubscriptionPlan.free && plan.isYearly ? ' monthly' : ''}'),
          const SizedBox(height: 8),
          _FeatureRow(icon: Icons.format_list_bulleted, text: '${plan.listingTokens} listing tokens${plan != SubscriptionPlan.free && plan.isYearly ? ' monthly' : ''}'),
          if (plan != SubscriptionPlan.free) ...[
            const SizedBox(height: 8),
            _FeatureRow(icon: Icons.support_agent, text: 'Priority support'),
            const SizedBox(height: 8),
            _FeatureRow(icon: Icons.trending_up, text: 'Advanced analytics'),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: isCurrentPlan
                ? OutlinedButton(
                    onPressed: null,
                    child: const Text('Current Plan'),
                  )
                : FilledButton(
                    onPressed: onSubscribe,
                    child: Text(plan == SubscriptionPlan.free ? 'Downgrade' : 'Subscribe'),
                  ),
          ),
        ],
      ),
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
      children: [
        Icon(icon, size: 18, color: ColorConstants.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
