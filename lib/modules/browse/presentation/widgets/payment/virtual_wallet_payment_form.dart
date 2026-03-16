import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/services/virtual_wallet_service.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/virtual_wallet_entity.dart';

/// Simulated payment form using virtual wallet
/// Mimics the PayMongo payment UI but deducts from the virtual wallet instead
class VirtualWalletPaymentForm extends StatefulWidget {
  final String userId;
  final double amount;
  final String description;
  final WalletTransactionCategory category;
  final String? referenceId;
  final VoidCallback onSuccess;

  const VirtualWalletPaymentForm({
    super.key,
    required this.userId,
    required this.amount,
    required this.description,
    required this.category,
    this.referenceId,
    required this.onSuccess,
  });

  @override
  State<VirtualWalletPaymentForm> createState() =>
      _VirtualWalletPaymentFormState();
}

class _VirtualWalletPaymentFormState extends State<VirtualWalletPaymentForm>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  bool _isSuccess = false;
  double _walletBalance = 0;
  bool _isLoadingBalance = true;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _loadBalance();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final balance = await VirtualWalletService.instance.loadBalance(
      widget.userId,
    );
    if (mounted) {
      setState(() {
        _walletBalance = balance;
        _isLoadingBalance = false;
      });
    }
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Future<void> _processPayment() async {
    if (_walletBalance < widget.amount) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        const SnackBar(
          content: Text('Insufficient wallet balance'),
          backgroundColor: ColorConstants.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate processing delay for realistic UX
    await Future.delayed(const Duration(seconds: 1));

    final result = await VirtualWalletService.instance.pay(
      userId: widget.userId,
      amount: widget.amount,
      category: widget.category,
      referenceId: widget.referenceId,
      description: widget.description,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _isSuccess = true;
        _walletBalance = result.newBalance;
      });
      _animController.forward();

      // Short delay to show success animation
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _isProcessing = false);
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Wallet Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet balance card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)],
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
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Virtual Wallet',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isLoadingBalance
                      ? const SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '₱${_formatPrice(_walletBalance)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    'Available Balance',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? ColorConstants.surfaceDark
                    : ColorConstants.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? ColorConstants.borderDark
                      : ColorConstants.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Description',
                    widget.description,
                    theme,
                    isDark,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Amount',
                    '₱${_formatPrice(widget.amount)}',
                    theme,
                    isDark,
                    isHighlight: true,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Balance After',
                    '₱${_formatPrice((_walletBalance - widget.amount).clamp(0, double.infinity))}',
                    theme,
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Insufficient balance warning
            if (!_isLoadingBalance && _walletBalance < widget.amount)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstants.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ColorConstants.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: ColorConstants.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Insufficient balance. You need ₱${_formatPrice(widget.amount - _walletBalance)} more.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ColorConstants.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Success animation or pay button
            if (_isSuccess)
              Center(
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: ColorConstants.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: ColorConstants.success,
                      size: 48,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed:
                      (_isProcessing ||
                          _isLoadingBalance ||
                          _walletBalance < widget.amount)
                      ? null
                      : _processPayment,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Pay ₱${_formatPrice(widget.amount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Virtual Wallet • Demo Mode',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ThemeData theme,
    bool isDark, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: isHighlight ? ColorConstants.primary : null,
          ),
        ),
      ],
    );
  }
}
