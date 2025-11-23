import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../app/core/constants/color_constants.dart';

class BiddingCardSection extends StatefulWidget {
  final bool hasDeposited;
  final double minimumBid;
  final double currentBid;
  final VoidCallback onDeposit;
  final Function(double) onPlaceBid;
  final bool isProcessing;

  const BiddingCardSection({
    super.key,
    required this.hasDeposited,
    required this.minimumBid,
    required this.currentBid,
    required this.onDeposit,
    required this.onPlaceBid,
    this.isProcessing = false,
  });

  @override
  State<BiddingCardSection> createState() => _BiddingCardSectionState();
}

class _BiddingCardSectionState extends State<BiddingCardSection> {
  final _bidController = TextEditingController();
  final List<double> _customIncrements = [];
  late double _nextMinimumBid;

  @override
  void initState() {
    super.initState();
    _nextMinimumBid = widget.currentBid + 1000;
    _bidController.text = _nextMinimumBid.toStringAsFixed(0);
  }

  @override
  void didUpdateWidget(BiddingCardSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentBid != widget.currentBid) {
      _nextMinimumBid = widget.currentBid + 1000;
      _bidController.text = _nextMinimumBid.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  void _addCustomIncrement() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Custom Increment'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Increment Amount',
              hintText: 'Min: ₱1,000',
              prefixText: '₱ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(controller.text) ?? 0;
                if (amount >= 1000) {
                  setState(() => _customIncrements.add(amount));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _selectBidAmount(double amount) {
    setState(() => _bidController.text = amount.toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.hasDeposited
              ? ColorConstants.success.withValues(alpha: 0.3)
              : (isDark ? ColorConstants.borderDark : ColorConstants.borderLight),
          width: widget.hasDeposited ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: widget.hasDeposited
          ? _buildUnlockedBidding(theme, isDark)
          : _buildLockedBidding(theme, isDark),
    );
  }

  Widget _buildLockedBidding(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorConstants.warning.withValues(alpha: 0.2),
                  ColorConstants.warning.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, size: 36, color: ColorConstants.warning),
          ),
          const SizedBox(height: 20),
          Text(
            'Bidding Locked',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Pay a refundable deposit to start bidding on this auction',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ColorConstants.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long, size: 18, color: ColorConstants.primary),
                const SizedBox(width: 8),
                Text(
                  '₱10,000 Deposit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ColorConstants.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.isProcessing ? null : widget.onDeposit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: widget.isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.payment_rounded),
              label: Text(
                widget.isProcessing ? 'Processing...' : 'Pay Deposit',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPaymentBadge('GCash', const Color(0xFF007DFE)),
              const SizedBox(width: 8),
              _buildPaymentBadge('Maya', const Color(0xFF52B44B)),
              const SizedBox(width: 8),
              _buildPaymentBadge('Card', ColorConstants.primary),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 14, color: ColorConstants.info),
              const SizedBox(width: 6),
              Text(
                'Fully refundable if you don\'t win',
                style: theme.textTheme.bodySmall?.copyWith(color: ColorConstants.info),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildUnlockedBidding(ThemeData theme, bool isDark) {
    final defaultIncrements = [
      _nextMinimumBid,
      _nextMinimumBid + 5000,
      _nextMinimumBid + 10000,
      _nextMinimumBid + 25000,
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: ColorConstants.success.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: ColorConstants.success, size: 22),
              const SizedBox(width: 10),
              Text(
                'Ready to Bid',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.success,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Deposit Paid',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ColorConstants.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Minimum Bid:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '₱${_formatNumber(_nextMinimumBid)}',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bidController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Your Bid Amount',
                  prefixText: '₱ ',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: isDark
                      ? ColorConstants.backgroundSecondaryDark
                      : ColorConstants.backgroundSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Quick Amounts',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _addCustomIncrement,
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, size: 16, color: ColorConstants.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Custom',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ColorConstants.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...defaultIncrements.map((amount) => _buildAmountChip(amount, theme, isDark)),
                  ..._customIncrements.map((amount) => _buildAmountChip(
                        _nextMinimumBid + amount,
                        theme,
                        isDark,
                        isCustom: true,
                      )),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.isProcessing
                      ? null
                      : () {
                          final amount = double.tryParse(_bidController.text) ?? 0;
                          if (amount >= _nextMinimumBid) {
                            widget.onPlaceBid(amount);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Minimum bid is ₱${_formatNumber(_nextMinimumBid)}'),
                                backgroundColor: ColorConstants.error,
                              ),
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: widget.isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Place Bid',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountChip(double amount, ThemeData theme, bool isDark, {bool isCustom = false}) {
    final isSelected = _bidController.text == amount.toStringAsFixed(0);

    return GestureDetector(
      onTap: () => _selectBidAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstants.primary
              : isCustom
                  ? ColorConstants.primary.withValues(alpha: 0.1)
                  : (isDark
                      ? ColorConstants.backgroundSecondaryDark
                      : ColorConstants.backgroundSecondaryLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ColorConstants.primary
                : (isDark ? ColorConstants.borderDark : ColorConstants.borderLight),
          ),
        ),
        child: Text(
          '₱${_formatNumber(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isCustom ? ColorConstants.primary : null),
          ),
        ),
      ),
    );
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
