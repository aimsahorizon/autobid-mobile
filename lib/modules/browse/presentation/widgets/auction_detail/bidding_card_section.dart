import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/bid_queue_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/pricing_entity.dart';

class BiddingCardSection extends StatefulWidget {
  final bool hasDeposited;
  final double minimumBid;
  final double currentBid;
  final double minBidIncrement;
  final double depositAmount;
  final bool enableIncrementalBidding;
  final VoidCallback onDeposit;
  final Function(double) onPlaceBid;
  final Function(bool, double?, double)? onAutoBidToggle;
  final bool isProcessing;
  final bool isAutoBidActive;
  final double? maxAutoBid;
  final double bidIncrement;
  final BidQueueCycleEntity? queueStatus;
  final bool hasRaisedHand;
  final bool isMyTurn;
  final int turnRemainingMs;
  final VoidCallback? onRaiseHand;
  final VoidCallback? onLowerHand;
  final Function(double)? onSubmitTurnBid;
  final int? queuePosition;

  const BiddingCardSection({
    super.key,
    required this.hasDeposited,
    required this.minimumBid,
    required this.currentBid,
    required this.minBidIncrement,
    required this.depositAmount,
    required this.enableIncrementalBidding,
    required this.onDeposit,
    required this.onPlaceBid,
    this.onAutoBidToggle,
    this.isProcessing = false,
    this.isAutoBidActive = false,
    this.maxAutoBid,
    this.bidIncrement = 100,
    this.queueStatus,
    this.hasRaisedHand = false,
    this.isMyTurn = false,
    this.turnRemainingMs = 0,
    this.onRaiseHand,
    this.onLowerHand,
    this.onSubmitTurnBid,
    this.queuePosition,
  });

  @override
  State<BiddingCardSection> createState() => _BiddingCardSectionState();
}

class _BiddingCardSectionState extends State<BiddingCardSection> {
  final _maxAutoBidController = TextEditingController();
  final _customIncrementController = TextEditingController();
  final _customBidController = TextEditingController();
  late double _nextMinimumBid;
  late double _selectedBidAmount; // User-chosen bid (>= next minimum)
  bool _showAutoBidSection = false;
  double _selectedIncrement = 0; // Set in initState based on listing config
  List<double> _customBidIncrements = [];
  bool _isCheckingAutoBidEligibility = true;
  bool _isGoldPlan = false;

  static const _customIncrementsKey = 'custom_bid_increments';

  // Local countdown timer for the 60s turn window
  Timer? _turnCountdownTimer;
  int _turnSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    final nextBidBase = widget.currentBid + widget.minBidIncrement;
    _nextMinimumBid = nextBidBase < widget.minimumBid
        ? widget.minimumBid
        : nextBidBase;
    _selectedBidAmount = _nextMinimumBid;
    _selectedIncrement = widget.bidIncrement;
    _showAutoBidSection = widget.isAutoBidActive;
    if (widget.maxAutoBid != null) {
      _maxAutoBidController.text = widget.maxAutoBid!.toStringAsFixed(0);
    }
    // Start turn countdown if it's already my turn
    if (widget.isMyTurn && widget.turnRemainingMs > 0) {
      _startTurnCountdown(widget.turnRemainingMs);
    }
    _loadCustomIncrements();
    _loadAutoBidEligibility();
  }

  Future<void> _loadAutoBidEligibility() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isGoldPlan = false;
            _isCheckingAutoBidEligibility = false;
          });
        }
        return;
      }

      final response = await SupabaseConfig.client
          .from('user_subscriptions')
          .select('plan')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      final currentPlan = SubscriptionPlanExtension.fromJson(
        response?['plan'] as String? ?? 'free',
      );

      if (mounted) {
        setState(() {
          _isGoldPlan = currentPlan.includesAutoBid;
          _isCheckingAutoBidEligibility = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isGoldPlan = false;
          _isCheckingAutoBidEligibility = false;
        });
      }
    }
  }

  Future<void> _loadCustomIncrements() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_customIncrementsKey);
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _customBidIncrements =
            saved.map((s) => double.tryParse(s)).whereType<double>().toList()
              ..sort();
      });
    }
  }

  Future<void> _saveCustomIncrements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _customIncrementsKey,
      _customBidIncrements.map((d) => d.toStringAsFixed(0)).toList(),
    );
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
      // Reset selection to minimum when current bid changes
      _selectedBidAmount = _nextMinimumBid;
      _customBidController.clear();
    }
    // Sync auto-bid state from controller (server may have deactivated it)
    if (oldWidget.isAutoBidActive != widget.isAutoBidActive) {
      _showAutoBidSection = widget.isAutoBidActive;
      if (widget.isAutoBidActive && widget.maxAutoBid != null) {
        _maxAutoBidController.text = widget.maxAutoBid!.toStringAsFixed(0);
      }
      _selectedIncrement = widget.bidIncrement;
    }
    // Start/stop turn countdown when isMyTurn changes
    if (widget.isMyTurn && !oldWidget.isMyTurn && widget.turnRemainingMs > 0) {
      _startTurnCountdown(widget.turnRemainingMs);
    } else if (!widget.isMyTurn && oldWidget.isMyTurn) {
      _stopTurnCountdown();
    } else if (widget.isMyTurn &&
        widget.turnRemainingMs > 0 &&
        _turnSecondsRemaining <= 0) {
      // Re-sync if server sends a new value while timer was at 0
      _startTurnCountdown(widget.turnRemainingMs);
    }
  }

  void _startTurnCountdown(int remainingMs) {
    _stopTurnCountdown();
    _turnSecondsRemaining = (remainingMs / 1000).ceil().clamp(0, 60);
    _turnCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_turnSecondsRemaining <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _turnSecondsRemaining = (_turnSecondsRemaining - 1).clamp(0, 60);
      });
    });
  }

  void _stopTurnCountdown() {
    _turnCountdownTimer?.cancel();
    _turnCountdownTimer = null;
    _turnSecondsRemaining = 0;
  }

  @override
  void dispose() {
    _stopTurnCountdown();
    _maxAutoBidController.dispose();
    _customIncrementController.dispose();
    _customBidController.dispose();
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
                    if (customValue != null) {
                      setDialogState(() => selectedIncrement = customValue);
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
                  (ScaffoldMessenger.of(
                    context,
                  )..clearSnackBars()).showSnackBar(
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
                  (ScaffoldMessenger.of(
                    context,
                  )..clearSnackBars()).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Increment must be at least ₱${_formatNumber(widget.minBidIncrement)}',
                      ),
                      backgroundColor: ColorConstants.error,
                    ),
                  );
                  return;
                }

                // Enforce increment is a multiple of min increment (optional but cleaner)
                if (selectedIncrement % widget.minBidIncrement != 0) {
                  (ScaffoldMessenger.of(
                    context,
                  )..clearSnackBars()).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Increment must be a multiple of ₱${_formatNumber(widget.minBidIncrement)}',
                      ),
                      backgroundColor: ColorConstants.error,
                    ),
                  );
                  return;
                }

                setState(() {
                  _showAutoBidSection = true;
                  _maxAutoBidController.text = amount.toStringAsFixed(0);
                  _selectedIncrement = selectedIncrement;
                });
                widget.onAutoBidToggle?.call(true, amount, selectedIncrement);
                Navigator.pop(context);
                (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
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
    if (widget.isAutoBidActive || _showAutoBidSection) {
      // Deactivate auto-bid
      setState(() {
        _showAutoBidSection = false;
        _maxAutoBidController.clear();
      });
      widget.onAutoBidToggle?.call(false, null, 0);
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        const SnackBar(
          content: Text('Auto-bid deactivated'),
          backgroundColor: ColorConstants.warning,
        ),
      );
    } else {
      if (_isCheckingAutoBidEligibility) {
        return;
      }

      if (!_isGoldPlan) {
        (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
          const SnackBar(
            content: Text('Auto-bid is available on Gold plan only.'),
            backgroundColor: ColorConstants.warning,
          ),
        );
        return;
      }

      // Show setup dialog
      _showAutoBidDialog();
    }
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
                  '₱${_formatNumber(widget.depositAmount)} Deposit',
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
              // Queue status display
              if (widget.queueStatus != null) ...[
                _buildQueueStatusBanner(theme, isDark),
                const SizedBox(height: 16),
              ],
              // Bid amount selection — only show when NOT in queue
              // (the turn UI in _buildRaiseHandButton has its own bid selector)
              if (!widget.isMyTurn && !widget.hasRaisedHand) ...[
                _buildBidAmountSelector(theme, isDark),
                const SizedBox(height: 20),
              ],
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
              // Raise Hand button
              _buildRaiseHandButton(theme, isDark),
              // Auto-bid toggle button
              if (!_showAutoBidSection && !widget.isAutoBidActive) ...[
                const SizedBox(height: 12),
                if (_isCheckingAutoBidEligibility)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      label: const Text('Checking Auto-Bid access...'),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isGoldPlan ? _toggleAutoBid : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: ColorConstants.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      icon: Icon(
                        _isGoldPlan ? Icons.auto_mode : Icons.lock_outline,
                      ),
                      label: Text(
                        _isGoldPlan
                            ? 'Enable Auto-Bid'
                            : 'Auto-Bid (Gold Plan Required)',
                        style: const TextStyle(
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

  Widget _buildQueueStatusBanner(ThemeData theme, bool isDark) {
    final status = widget.queueStatus!;
    final state = status.state;

    Color stateColor;
    IconData stateIcon;
    String stateLabel;
    String stateDescription;

    switch (state) {
      case 'open':
        stateColor = ColorConstants.success;
        stateIcon = Icons.pan_tool_outlined;
        stateLabel = 'Queue Open';
        stateDescription = 'Raise your hand to join this bidding round';
      case 'locked':
        stateColor = ColorConstants.warning;
        stateIcon = Icons.lock_clock;
        stateLabel = 'Queue Locked';
        stateDescription = 'Preparing to process bids...';
      case 'processing':
        stateColor = ColorConstants.primary;
        stateIcon = Icons.sync;
        stateLabel = 'Processing Bids';
        stateDescription = 'Executing bids in order...';
      default:
        stateColor = isDark
            ? ColorConstants.textSecondaryDark
            : ColorConstants.textSecondaryLight;
        stateIcon = Icons.hourglass_empty;
        stateLabel = 'Waiting';
        stateDescription = 'Next round will start when someone bids';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stateColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(stateIcon, size: 20, color: stateColor),
              const SizedBox(width: 10),
              Text(
                stateLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: stateColor,
                ),
              ),
              const Spacer(),
              if (status.cycleNumber > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Round ${status.cycleNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: stateColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  stateDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: stateColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
              if (status.queue.isNotEmpty)
                Text(
                  '${status.queue.length} in queue',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: stateColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          // Show user's position if hand is raised
          if (widget.hasRaisedHand && widget.queuePosition != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('✋', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    'Hand Raised!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${widget.queuePosition}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build bid amount selector with increment chips + custom amount input.
  Widget _buildBidAmountSelector(ThemeData theme, bool isDark) {
    final inc = widget.minBidIncrement;
    // Preset increments: 1x, 2x, 3x, 5x of minimum increment
    final presets = <double>[
      _nextMinimumBid, // 1x increment (minimum)
      widget.currentBid + inc * 2, // 2x
      widget.currentBid + inc * 3, // 3x
      widget.currentBid + inc * 5, // 5x
    ];

    // Build custom preset amounts (saved by user, stored as absolute bid amounts relative to current bid)
    final customPresets = _customBidIncrements
        .map((customInc) => widget.currentBid + customInc)
        .where(
          (amount) => amount >= _nextMinimumBid && !presets.contains(amount),
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.backgroundSecondaryDark
            : ColorConstants.backgroundSecondaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? ColorConstants.borderDark
              : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monetization_on_outlined,
                color: ColorConstants.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Choose Your Bid',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Min +₱${_formatNumber(inc)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ColorConstants.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Selected amount display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorConstants.primary.withValues(alpha: 0.08),
                  ColorConstants.primary.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ColorConstants.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '₱${_formatNumber(_selectedBidAmount)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(+₱${_formatNumber(_selectedBidAmount - widget.currentBid)})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Increment chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in presets)
                ChoiceChip(
                  label: Text('+₱${_formatNumber(amount - widget.currentBid)}'),
                  selected: _selectedBidAmount == amount,
                  selectedColor: ColorConstants.primary,
                  backgroundColor: isDark
                      ? ColorConstants.surfaceDark
                      : ColorConstants.surfaceVariantLight,
                  labelStyle: TextStyle(
                    color: _selectedBidAmount == amount
                        ? Colors.white
                        : (isDark
                              ? ColorConstants.textPrimaryDark
                              : ColorConstants.textPrimaryLight),
                    fontWeight: _selectedBidAmount == amount
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: _selectedBidAmount == amount
                        ? ColorConstants.primary
                        : (isDark
                              ? ColorConstants.borderDark
                              : ColorConstants.borderLight),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedBidAmount = amount;
                        _customBidController.clear();
                      });
                    }
                  },
                ),
              // Custom saved chips (with delete via long-press)
              for (final amount in customPresets)
                GestureDetector(
                  onLongPress: () =>
                      _confirmDeleteCustomIncrement(amount - widget.currentBid),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('+₱${_formatNumber(amount - widget.currentBid)}'),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.close,
                          size: 14,
                          color: _selectedBidAmount == amount
                              ? Colors.white70
                              : (isDark
                                    ? ColorConstants.textSecondaryDark
                                    : ColorConstants.textSecondaryLight),
                        ),
                      ],
                    ),
                    selected: _selectedBidAmount == amount,
                    selectedColor: ColorConstants.primary,
                    backgroundColor: isDark
                        ? ColorConstants.surfaceDark
                        : ColorConstants.surfaceVariantLight,
                    labelStyle: TextStyle(
                      color: _selectedBidAmount == amount
                          ? Colors.white
                          : (isDark
                                ? ColorConstants.textPrimaryDark
                                : ColorConstants.textPrimaryLight),
                      fontWeight: _selectedBidAmount == amount
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: _selectedBidAmount == amount
                          ? ColorConstants.primary
                          : (isDark
                                ? ColorConstants.borderDark
                                : ColorConstants.borderLight),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedBidAmount = amount;
                          _customBidController.clear();
                        });
                      }
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Custom amount input with Add button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customBidController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Custom Increment',
                    hintText: 'e.g., ${_formatNumber(inc * 10)}',
                    prefixText: '₱ ',
                    suffixIcon: _customBidController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _customBidController.clear();
                              setState(() {
                                _selectedBidAmount = _nextMinimumBid;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    helperText: 'Multiples of 100. Long-press chip to delete.',
                    helperMaxLines: 2,
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null && parsed % 100 == 0 && parsed >= inc) {
                      setState(() {
                        _selectedBidAmount = widget.currentBid + parsed;
                      });
                    }
                    setState(() {}); // Refresh suffixIcon visibility
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _addCustomIncrement(context),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addCustomIncrement(BuildContext context) {
    final text = _customBidController.text.trim();
    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) {
      _showChipError(context, 'Enter a valid amount');
      return;
    }
    if (parsed % 100 != 0) {
      _showChipError(context, 'Must be a multiple of 100');
      return;
    }
    if (parsed < widget.minBidIncrement) {
      _showChipError(
        context,
        'Must be at least ₱${_formatNumber(widget.minBidIncrement)}',
      );
      return;
    }
    if (_customBidIncrements.contains(parsed)) {
      _showChipError(context, 'Already saved');
      return;
    }
    setState(() {
      _customBidIncrements.add(parsed);
      _customBidIncrements.sort();
      _selectedBidAmount = widget.currentBid + parsed;
      _customBidController.clear();
    });
    _saveCustomIncrements();
  }

  void _showChipError(BuildContext context, String message) {
    (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorConstants.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDeleteCustomIncrement(double incrementValue) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Custom Amount?'),
        content: Text(
          'Remove +₱${_formatNumber(incrementValue)} from your saved amounts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _customBidIncrements.remove(incrementValue);
                if (_selectedBidAmount == widget.currentBid + incrementValue) {
                  _selectedBidAmount = _nextMinimumBid;
                }
              });
              _saveCustomIncrements();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: ColorConstants.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaiseHandButton(ThemeData theme, bool isDark) {
    final hasRaised = widget.hasRaisedHand;

    // =========================================================
    // IT'S YOUR TURN — show bid amount selector + timer + Place Bid
    // =========================================================
    if (widget.isMyTurn) {
      final turnSeconds = _turnSecondsRemaining;
      return Column(
        children: [
          // Timer banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'IT\'S YOUR TURN!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${turnSeconds}s',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: turnSeconds <= 10 ? Colors.yellow : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Bid amount selector (only shown during turn)
          _buildBidAmountSelector(theme, isDark),
          const SizedBox(height: 12),
          // Place Bid button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.isProcessing
                  ? null
                  : () => widget.onSubmitTurnBid?.call(_selectedBidAmount),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: ColorConstants.success,
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
                  : const Icon(Icons.gavel, color: Colors.white),
              label: Text(
                widget.isProcessing
                    ? 'Placing Bid...'
                    : 'Place Bid — ₱${_formatNumber(_selectedBidAmount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Lower hand / withdraw option
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.isProcessing ? null : widget.onLowerHand,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(
                  color: ColorConstants.error.withValues(alpha: 0.6),
                ),
                foregroundColor: ColorConstants.error,
              ),
              icon: const Icon(Icons.pan_tool_alt, size: 16),
              label: const Text(
                'Lower Hand — Skip My Turn',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose your bid amount and place it before the timer runs out.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    // =========================================================
    // Already raised hand — show position + Lower Hand option
    // =========================================================
    if (hasRaised) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: ColorConstants.success,
                disabledBackgroundColor: ColorConstants.success.withValues(
                  alpha: 0.7,
                ),
              ),
              icon: const Text('✋', style: TextStyle(fontSize: 18)),
              label: Text(
                widget.queuePosition != null
                    ? 'In Queue — #${widget.queuePosition} in line'
                    : 'In Queue — Waiting for your turn',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.isProcessing ? null : widget.onLowerHand,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(
                  color: ColorConstants.error.withValues(alpha: 0.6),
                ),
                foregroundColor: ColorConstants.error,
              ),
              icon: widget.isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorConstants.error,
                      ),
                    )
                  : const Icon(Icons.pan_tool_alt, size: 18),
              label: Text(
                widget.isProcessing
                    ? 'Withdrawing...'
                    : 'Lower Hand — Back Out',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You\'re in the queue. When it\'s your turn, you\'ll have 60 seconds to choose your bid amount and place it.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    // =========================================================
    // Ready to raise hand — simple queue join (no bid amount)
    // =========================================================
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: widget.isProcessing
            ? null
            : () => widget.onRaiseHand?.call(),
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
            : const Text('✋', style: TextStyle(fontSize: 18)),
        label: Text(
          widget.isProcessing ? 'Raising Hand...' : 'Raise Hand — Join Queue',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
