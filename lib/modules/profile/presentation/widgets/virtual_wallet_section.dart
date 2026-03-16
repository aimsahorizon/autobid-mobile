import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/core/services/virtual_wallet_service.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/virtual_wallet_entity.dart';

class VirtualWalletSection extends StatefulWidget {
  const VirtualWalletSection({super.key});

  @override
  State<VirtualWalletSection> createState() => _VirtualWalletSectionState();
}

class _VirtualWalletSectionState extends State<VirtualWalletSection> {
  @override
  void initState() {
    super.initState();
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId != null) {
      VirtualWalletService.instance.loadBalance(userId);
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

  void _showTransactionHistory() {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _WalletHistoryPage(userId: userId)),
    );
  }

  void _showAmountDialog({required bool isDeposit}) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isProcessing = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isDeposit ? 'Deposit Funds' : 'Withdraw Funds'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₱ ',
                    labelText: 'Amount',
                    hintText: '0.00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter an amount';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    if (!isDeposit &&
                        amount > VirtualWalletService.instance.balance) {
                      return 'Insufficient balance';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final amount = double.parse(
                            amountController.text.trim(),
                          );
                          setDialogState(() => isProcessing = true);

                          final result = isDeposit
                              ? await VirtualWalletService.instance.topUp(
                                  userId: userId,
                                  amount: amount,
                                )
                              : await VirtualWalletService.instance.withdraw(
                                  userId: userId,
                                  amount: amount,
                                );

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

                          if (mounted) {
                            (ScaffoldMessenger.of(
                              context,
                            )..clearSnackBars()).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.success
                                      ? '${isDeposit ? 'Deposit' : 'Withdrawal'} successful'
                                      : result.message,
                                ),
                                backgroundColor: result.success
                                    ? ColorConstants.success
                                    : ColorConstants.error,
                              ),
                            );
                          }
                        },
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isDeposit ? 'Deposit' : 'Withdraw'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DEMO',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: VirtualWalletService.instance,
              builder: (context, _) {
                final service = VirtualWalletService.instance;
                if (service.isLoading) {
                  return const SizedBox(
                    height: 36,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                return Text(
                  '₱${_formatPrice(service.balance)}',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Available Balance',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAmountDialog(isDeposit: true),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Deposit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAmountDialog(isDeposit: false),
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('Withdraw'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showTransactionHistory,
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Transaction history page
class _WalletHistoryPage extends StatefulWidget {
  final String userId;

  const _WalletHistoryPage({required this.userId});

  @override
  State<_WalletHistoryPage> createState() => _WalletHistoryPageState();
}

class _WalletHistoryPageState extends State<_WalletHistoryPage> {
  List<WalletTransactionEntity> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final txns = await VirtualWalletService.instance.getTransactions(
        widget.userId,
      );
      if (mounted) {
        setState(() {
          _transactions = txns;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _transactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final txn = _transactions[index];
                  final isCredit = txn.type == WalletTransactionType.credit;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? ColorConstants.surfaceDark
                          : ColorConstants.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? ColorConstants.borderDark
                            : ColorConstants.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                (isCredit
                                        ? ColorConstants.success
                                        : ColorConstants.error)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isCredit
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isCredit
                                ? ColorConstants.success
                                : ColorConstants.error,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                txn.category.label,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (txn.description != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  txn.description!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? ColorConstants.textSecondaryDark
                                        : ColorConstants.textSecondaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(txn.createdAt),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? ColorConstants.textSecondaryDark
                                      : ColorConstants.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isCredit ? '+' : '-'}₱${_formatPrice(txn.amount)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCredit
                                    ? ColorConstants.success
                                    : ColorConstants.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bal: ₱${_formatPrice(txn.balanceAfter)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? ColorConstants.textSecondaryDark
                                    : ColorConstants.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $amPm';
  }
}
