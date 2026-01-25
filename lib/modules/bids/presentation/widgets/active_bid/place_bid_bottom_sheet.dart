import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';

class PlaceBidBottomSheet extends StatefulWidget {
  final double currentBid;
  final double minBidIncrement;
  final Function(double) onBidPlaced;

  const PlaceBidBottomSheet({
    super.key,
    required this.currentBid,
    required this.minBidIncrement,
    required this.onBidPlaced,
  });

  @override
  State<PlaceBidBottomSheet> createState() => _PlaceBidBottomSheetState();
}

class _PlaceBidBottomSheetState extends State<PlaceBidBottomSheet> {
  late TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final suggestedBid = widget.currentBid + widget.minBidIncrement;
    _controller = TextEditingController(text: suggestedBid.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final amount = double.tryParse(_controller.text.replaceAll(',', ''));

    if (amount == null) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    if (amount <= widget.currentBid) {
      setState(() => _errorMessage = 'Bid must be higher than current bid');
      return;
    }

    if (amount < widget.currentBid + widget.minBidIncrement) {
      setState(() =>
          _errorMessage = 'Minimum bid increment is ₱${widget.minBidIncrement.toStringAsFixed(0)}');
      return;
    }

    widget.onBidPlaced(amount);
  }

  void _addQuickAmount(double amount) {
    final newAmount = widget.currentBid + amount;
    _controller.text = newAmount.toStringAsFixed(0);
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Place Your Bid',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current bid: ₱${widget.currentBid.toStringAsFixed(0)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: 'Your Bid Amount',
              prefixText: '₱',
              errorText: _errorMessage,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? ColorConstants.textSecondaryDark.withValues(alpha: 0.3)
                      : ColorConstants.textSecondaryLight.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ColorConstants.primary, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() => _errorMessage = null);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Add',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _QuickButton(label: '+5K', amount: 5000, onTap: _addQuickAmount),
              const SizedBox(width: 8),
              _QuickButton(label: '+10K', amount: 10000, onTap: _addQuickAmount),
              const SizedBox(width: 8),
              _QuickButton(label: '+25K', amount: 25000, onTap: _addQuickAmount),
              const SizedBox(width: 8),
              _QuickButton(label: '+50K', amount: 50000, onTap: _addQuickAmount),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _validateAndSubmit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Place Bid'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final double amount;
  final Function(double) onTap;

  const _QuickButton({
    required this.label,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: OutlinedButton(
        onPressed: () => onTap(amount),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: isDark
                ? ColorConstants.textSecondaryDark.withValues(alpha: 0.3)
                : ColorConstants.textSecondaryLight.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
