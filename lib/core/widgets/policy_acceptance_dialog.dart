import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/constants/policy_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/core/services/policy_penalty_datasource.dart';

/// Reusable dialog that shows policy rules and requires acceptance.
/// Returns `true` if user accepted, `false`/null if dismissed.
///
/// Usage:
/// ```dart
/// final accepted = await PolicyAcceptanceDialog.show(
///   context: context,
///   policyType: PolicyConstants.biddingRules,
/// );
/// if (accepted != true) return; // User declined
/// ```
class PolicyAcceptanceDialog extends StatefulWidget {
  final String policyType;
  final String? contextId;

  const PolicyAcceptanceDialog({
    super.key,
    required this.policyType,
    this.contextId,
  });

  /// Show the dialog. Returns true if accepted.
  ///
  /// [contextId] scopes the acceptance:
  ///   - Bidding: pass auctionId → shown once per auction
  ///   - Transaction: pass transactionId → shown once per transaction
  ///   - Listing: pass null → shown every time
  static Future<bool> show({
    required BuildContext context,
    required String policyType,
    String? contextId,
  }) async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return false;

    // If contextId is provided, check if already accepted for this context
    if (contextId != null) {
      final version = _getVersion(policyType);
      final alreadyAccepted = await PolicyPenaltyDatasource.instance
          .hasAcceptedPolicy(
            userId: userId,
            policyType: policyType,
            version: version,
            contextId: contextId,
          );
      if (alreadyAccepted) return true;
    }

    // Show dialog
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          PolicyAcceptanceDialog(policyType: policyType, contextId: contextId),
    );

    return result ?? false;
  }

  static int _getVersion(String policyType) {
    switch (policyType) {
      case PolicyConstants.biddingRules:
        return PolicyConstants.biddingRulesVersion;
      case PolicyConstants.listingRules:
        return PolicyConstants.listingRulesVersion;
      case PolicyConstants.transactionRules:
        return PolicyConstants.transactionRulesVersion;
      default:
        return 1;
    }
  }

  @override
  State<PolicyAcceptanceDialog> createState() => _PolicyAcceptanceDialogState();
}

class _PolicyAcceptanceDialogState extends State<PolicyAcceptanceDialog> {
  bool _hasReadAndAgreed = false;
  bool _isSubmitting = false;

  String get _title {
    switch (widget.policyType) {
      case PolicyConstants.biddingRules:
        return 'Bidding Rules & Policies';
      case PolicyConstants.listingRules:
        return 'Listing Rules & Policies';
      case PolicyConstants.transactionRules:
        return 'Transaction Rules & Policies';
      default:
        return 'Rules & Policies';
    }
  }

  IconData get _icon {
    switch (widget.policyType) {
      case PolicyConstants.biddingRules:
        return Icons.gavel;
      case PolicyConstants.listingRules:
        return Icons.sell;
      case PolicyConstants.transactionRules:
        return Icons.handshake;
      default:
        return Icons.policy;
    }
  }

  List<String> get _policies {
    switch (widget.policyType) {
      case PolicyConstants.biddingRules:
        return PolicyConstants.biddingPolicies;
      case PolicyConstants.listingRules:
        return PolicyConstants.listingPolicies;
      case PolicyConstants.transactionRules:
        return PolicyConstants.transactionPolicies;
      default:
        return [];
    }
  }

  Future<void> _onAccept() async {
    setState(() => _isSubmitting = true);

    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) {
      if (mounted) Navigator.pop(context, false);
      return;
    }

    final version = PolicyAcceptanceDialog._getVersion(widget.policyType);
    await PolicyPenaltyDatasource.instance.acceptPolicy(
      userId: userId,
      policyType: widget.policyType,
      version: version,
      contextId: widget.contextId,
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorConstants.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorConstants.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon, color: ColorConstants.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Policy items (scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please read the following carefully before proceeding:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_policies.length, (index) {
                      final policy = _policies[index];
                      final isSubItem = policy.startsWith('  •');
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: 12,
                          left: isSubItem ? 24 : 0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isSubItem) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: ColorConstants.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                isSubItem ? policy.trim() : policy,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Checkbox + buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? ColorConstants.borderDark
                        : ColorConstants.borderLight,
                  ),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _hasReadAndAgreed = !_hasReadAndAgreed),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _hasReadAndAgreed,
                          onChanged: (v) =>
                              setState(() => _hasReadAndAgreed = v ?? false),
                          activeColor: ColorConstants.primary,
                        ),
                        Expanded(
                          child: Text(
                            'I have read and agree to the above policies',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _hasReadAndAgreed && !_isSubmitting
                              ? _onAccept
                              : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Accept & Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
