import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';

class BiddingCardSection extends StatefulWidget {
  final bool hasDeposited;
  final double minimumBid;
  final double currentBid;
  final double minBidIncrement;
  final bool enableIncrementalBidding;
  final VoidCallback onDeposit;
  final Function(double) onPlaceBid;
  final Function(bool, double?, double)? onAutoBidToggle;
  final bool isProcessing;
  final bool isAutoBidActive;
  final double? maxAutoBid;

  const BiddingCardSection({
    super.key,
    required this.hasDeposited,
    required this.minimumBid,
    required this.currentBid,
    required this.minBidIncrement,
    required this.enableIncrementalBidding,
    required this.onDeposit,
    required this.onPlaceBid,
    this.onAutoBidToggle,
    this.isProcessing = false,
    this.isAutoBidActive = false,
    this.maxAutoBid,
  });

  @override
  State<BiddingCardSection> createState() => _BiddingCardSectionState();
}

class _BiddingCardSectionState extends State<BiddingCardSection> {
  final _bidController = TextEditingController();
  final _maxAutoBidController = TextEditingController();
  final _customIncrementController = TextEditingController();
  final List<double> _customIncrements = [];
  late double _nextMinimumBid;
  bool _showAutoBidSection = false;
  double _selectedIncrement = 0; // Set in initState based on listing config

  @override
  void initState() {
    super.initState();
    final nextBidBase = widget.currentBid + widget.minBidIncrement;
    _nextMinimumBid = nextBidBase < widget.minimumBid
        ? widget.minimumBid
        : nextBidBase;
    _bidController.text = _nextMinimumBid.toStringAsFixed(0);
    _selectedIncrement = widget.minBidIncrement;
    _showAutoBidSection = widget.isAutoBidActive;
    if (widget.maxAutoBid != null) {
      _maxAutoBidController.text = widget.maxAutoBid!.toStringAsFixed(0);
    }
  }

  @override
  void didUpdateWidget(BiddingCardSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentBid != widget.currentBid ||
        oldWidget.minBidIncrement != widget.minBidIncrement) {
      final nextBidBase = widget.currentBid + widget.minBidIncrement;
      _nextMinimumBid = nextBidBase < widget.minimumBid
          ? widget.minimumBid
          : nextBidBase;
      _bidController.text = _nextMinimumBid.toStringAsFixed(0);
      _selectedIncrement = widget.minBidIncrement;
    }
  }

  @override
  void dispose() {
    _bidController.dispose();
    _maxAutoBidController.dispose();
    super.dispose();
  }

  void _showAutoBidDialog() {
    final tempController = TextEditingController(
      text: widget.maxAutoBid?.toStringAsFixed(0) ?? '',
    );
    double selectedIncrement = _selectedIncrement < widget.minBidIncrement
        ? widget.minBidIncrement
        : _selectedIncrement;

    // Generate preset increments based on the seller's configured minimum increment
    final presetIncrements = <double>{
      widget.minBidIncrement, // 1x
      widget.minBidIncrement * 2, // 2x
      widget.minBidIncrement * 3, // 3x
      widget.minBidIncrement * 5, // 5x
      widget.minBidIncrement * 10, // 10x
    }.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_mode,
                  color: ColorConstants.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Auto-Bid Setup'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set your maximum bid amount and increment.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorConstants.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: tempController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Maximum Auto-Bid Amount',
                    hintText: 'e.g., ${_formatNumber(_nextMinimumBid + 50000)}',
                    prefixText: '₱ ',
                    prefixIcon: const Icon(Icons.price_check),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText:
                        'Must be at least ₱${_formatNumber(_nextMinimumBid + 10000)}',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Bid Increment',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final inc in presetIncrements)
                      ChoiceChip(
                        label: Text('₱${_formatNumber(inc)}'),
                        selected: selectedIncrement == inc,
                        selectedColor: ColorConstants.primary,
                        backgroundColor: ColorConstants.surfaceVariantLight,
                        labelStyle: TextStyle(
                          color: selectedIncrement == inc
                              ? Colors.white
                              : ColorConstants.textPrimaryLight,
                          fontWeight: selectedIncrement == inc
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: selectedIncrement == inc
                              ? ColorConstants.primary
                              : ColorConstants.borderLight,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() => selectedIncrement = inc);
                            _customIncrementController.clear();
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customIncrementController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Custom Increment',
                    hintText: 'Enter custom amount',
                    prefixText: '₱ ',
                    prefixIcon: const Icon(Icons.edit),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Or enter your own increment',
                  ),
                  onChanged: (value) {
                    final customValue = double.tryParse(value);
                    if (customValue != null && customValue > 0) {
                      final effective = customValue < widget.minBidIncrement
                          ? widget.minBidIncrement
                          : customValue;
                      setDialogState(() => selectedIncrement = effective);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstants.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ColorConstants.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: ColorConstants.info,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Auto-bid will increase by at least ₱${_formatNumber(widget.minBidIncrement)} each time',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ColorConstants.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final amount = double.tryParse(tempController.text) ?? 0;
                if (amount < _nextMinimumBid + 10000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Maximum must be at least ₱${_formatNumber(_nextMinimumBid + 10000)}',
                      ),
                      backgroundColor: ColorConstants.error,
                    ),
                  );
                  return;
                }

                if (selectedIncrement < widget.minBidIncrement) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Increment must be at least ₱${_formatNumber(widget.minBidIncrement)}',
                      ),
                      backgroundColor: ColorConstants.error,
                    ),
                  );
                  selectedIncrement = widget.minBidIncrement;
                  return;
                }

                setState(() {
                  _showAutoBidSection = true;
                  _maxAutoBidController.text = amount.toStringAsFixed(0);
                  _selectedIncrement = selectedIncrement;
                });
                widget.onAutoBidToggle?.call(true, amount, selectedIncrement);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Auto-bid activated! Increment: ₱${_formatNumber(selectedIncrement)}',
                    ),
                    backgroundColor: ColorConstants.success,
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Activate'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAutoBid() {
    if (!widget.enableIncrementalBidding) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-bid is disabled for this auction by the seller'),
          backgroundColor: ColorConstants.error,
        ),
      );
      return;
    }

    if (widget.isAutoBidActive || _showAutoBidSection) {
      // Deactivate auto-bid
      setState(() {
        _showAutoBidSection = false;
        _maxAutoBidController.clear();
      });
      widget.onAutoBidToggle?.call(false, null, 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-bid deactivated'),
          backgroundColor: ColorConstants.warning,
        ),
      );
    } else {
      // Show setup dialog
      _showAutoBidDialog();
    }
  }

  void _addCustomIncrement() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Add Custom Increment'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Increment Amount',
              hintText: 'Min: ₱${_formatNumber(widget.minBidIncrement)}',
              prefixText: '₱ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                if (amount < widget.minBidIncrement) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Custom increment must be at least ₱${_formatNumber(widget.minBidIncrement)}',
                      ),
                      backgroundColor: ColorConstants.error,
                    ),
                  );
                  return;
                }
                
                if (amount % 1000 != 0) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Increment must be a multiple of ₱1,000',
                      ),
                      backgroundColor: ColorConstants.error,
                    ),
                  );
                  return;
                }

                setState(() => _customIncrements.add(amount));
                Navigator.pop(context);
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
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.hasDeposited
              ? ColorConstants.success.withValues(alpha: 0.3)
              : (isDark
                    ? ColorConstants.borderDark
                    : ColorConstants.borderLight),
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
            child: const Icon(
              Icons.lock_rounded,
              size: 36,
              color: ColorConstants.warning,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bidding Locked',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
                const Icon(
                  Icons.receipt_long,
                  size: 18,
                  color: ColorConstants.primary,
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: widget.isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.payment_rounded),
              label: Text(
                widget.isProcessing ? 'Processing...' : 'Pay Deposit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ColorConstants.info,
                ),
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
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUnlockedBidding(ThemeData theme, bool isDark) {
    // Show increment amounts (how much to add), not total amounts
    final defaultIncrements = [
      widget.minBidIncrement,
      widget.minBidIncrement * 2,
      widget.minBidIncrement * 3,
      widget.minBidIncrement * 4,
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
              const Icon(
                Icons.check_circle,
                color: ColorConstants.success,
                size: 22,
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bidController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Your Bid Amount',
                  prefixText: '₱ ',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _addCustomIncrement,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          size: 16,
                          color: ColorConstants.primary,
                        ),
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
                  ...defaultIncrements.map(
                    (increment) =>
                        _buildIncrementChip(increment, theme, isDark),
                  ),
                  ..._customIncrements.map(
                    (increment) => _buildIncrementChip(
                      increment,
                      theme,
                      isDark,
                      isCustom: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Auto-bid section
              if (_showAutoBidSection || widget.isAutoBidActive) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorConstants.primary.withValues(alpha: 0.1),
                        ColorConstants.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ColorConstants.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: ColorConstants.primary.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.auto_mode,
                              size: 18,
                              color: ColorConstants.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Auto-Bid Active',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.primary,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _toggleAutoBid,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: ColorConstants.error.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: ColorConstants.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Stop',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: ColorConstants.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Max Auto-Bid:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? ColorConstants.textSecondaryDark
                                  : ColorConstants.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₱${_formatNumber(double.tryParse(_maxAutoBidController.text) ?? 0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: ColorConstants.primary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'System will auto-bid ₱${_formatNumber(_selectedIncrement)} increments when outbid',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: ColorConstants.primary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Manual bid button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.isProcessing
                      ? null
                      : () {
                          final amount =
                              double.tryParse(_bidController.text) ?? 0;
                          final increment = amount - widget.currentBid;
                          final meetsMinIncrement =
                              increment >= widget.minBidIncrement;
                          final isMultipleOf1k = increment % 1000 == 0;

                          if (amount >= _nextMinimumBid && 
                              meetsMinIncrement && 
                              isMultipleOf1k) {
                            widget.onPlaceBid(amount);
                          } else {
                            String errorMsg;
                            if (amount < _nextMinimumBid) {
                              errorMsg = 'Bid must be at least ₱${_formatNumber(_nextMinimumBid)}';
                            } else if (!meetsMinIncrement) {
                              errorMsg = 'Increase must be ≥ ₱${_formatNumber(widget.minBidIncrement)}';
                            } else {
                              errorMsg = 'Bid increment must be a multiple of ₱1,000';
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMsg),
                                backgroundColor: ColorConstants.error,
                              ),
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: widget.isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Place Bid',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              // Auto-bid toggle button
              if (!_showAutoBidSection && !widget.isAutoBidActive) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _toggleAutoBid,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: ColorConstants.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    icon: const Icon(Icons.auto_mode),
                    label: const Text(
                      'Enable Auto-Bid',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncrementChip(
    double increment,
    ThemeData theme,
    bool isDark, {
    bool isCustom = false,
  }) {
    final totalAmount = widget.currentBid + increment;
    final isSelected = _bidController.text == totalAmount.toStringAsFixed(0);

    return GestureDetector(
      onTap: () => _selectBidAmount(totalAmount),
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
                : (isDark
                      ? ColorConstants.borderDark
                      : ColorConstants.borderLight),
          ),
        ),
        child: Text(
          '+₱${_formatNumber(increment)}',
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
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
