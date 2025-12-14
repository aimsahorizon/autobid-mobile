import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/admin_transaction_entity.dart';
import '../controllers/admin_transaction_controller.dart';
import 'admin_transaction_review_page.dart';

/// Admin page for managing transaction reviews
class AdminTransactionsPage extends StatefulWidget {
  final AdminTransactionController controller;

  const AdminTransactionsPage({super.key, required this.controller});

  @override
  State<AdminTransactionsPage> createState() => _AdminTransactionsPageState();
}

class _AdminTransactionsPageState extends State<AdminTransactionsPage>
    with AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> _filters = [
    {
      'value': 'pending_review',
      'label': 'Pending Review',
      'icon': Icons.rate_review,
    },
    {
      'value': 'in_transaction',
      'label': 'In Progress',
      'icon': Icons.pending_actions,
    },
    {'value': 'sold', 'label': 'Completed', 'icon': Icons.check_circle},
    {'value': 'deal_failed', 'label': 'Failed', 'icon': Icons.cancel},
    {'value': 'all', 'label': 'All', 'icon': Icons.list},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('[AdminTransactionsPage] Loading data...');
    await widget.controller.loadAll();
    // Default to "all" to show all transactions
    await widget.controller.loadTransactions(statusFilter: 'all');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // Stats Banner
        _buildStatsBanner(),

        // Filter Chips
        _buildFilterChips(),

        // Transaction List
        Expanded(child: _buildTransactionList()),
      ],
    );
  }

  Widget _buildStatsBanner() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final stats = widget.controller.stats;
        if (stats == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          color: ColorConstants.primaryLight.withValues(alpha: 0.1),
          child: Row(
            children: [
              _buildStatCard(
                'Pending Review',
                stats.pendingReview.toString(),
                Icons.rate_review,
                ColorConstants.warning,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'In Progress',
                stats.inProgress.toString(),
                Icons.pending_actions,
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Approved',
                stats.approved.toString(),
                Icons.verified,
                ColorConstants.success,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Completed',
                stats.completed.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: ColorConstants.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: ColorConstants.surfaceVariantLight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return Row(
              children: _filters.map((filter) {
                final isSelected =
                    widget.controller.selectedFilter == filter['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter['icon'] as IconData,
                          size: 16,
                          color: isSelected
                              ? ColorConstants.primary
                              : ColorConstants.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(filter['label'] as String),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        widget.controller.loadTransactions(
                          statusFilter: filter['value'] as String,
                        );
                      }
                    },
                    backgroundColor: Colors.white,
                    selectedColor: ColorConstants.primary.withValues(
                      alpha: 0.2,
                    ),
                    checkmarkColor: ColorConstants.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? ColorConstants.primary
                          : ColorConstants.textPrimaryLight,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (widget.controller.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: ColorConstants.error,
                ),
                const SizedBox(height: 16),
                Text(widget.controller.error!),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final transactions = widget.controller.transactions;

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: ColorConstants.textSecondaryLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyMessage(),
                  style: TextStyle(color: ColorConstants.textSecondaryLight),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => widget.controller.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _TransactionCard(
                transaction: transaction,
                onTap: () => _openReviewPage(transaction),
              );
            },
          ),
        );
      },
    );
  }

  String _getEmptyMessage() {
    switch (widget.controller.selectedFilter) {
      case 'pending_review':
        return 'No transactions pending admin review';
      case 'in_transaction':
        return 'No transactions in progress';
      case 'sold':
        return 'No completed transactions';
      case 'deal_failed':
        return 'No failed transactions';
      default:
        return 'No transactions available';
    }
  }

  void _openReviewPage(AdminTransactionEntity transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminTransactionReviewPage(
          controller: widget.controller,
          transactionId: transaction.id,
        ),
      ),
    );
  }
}

/// Card for displaying transaction in list
class _TransactionCard extends StatelessWidget {
  final AdminTransactionEntity transaction;
  final VoidCallback onTap;

  const _TransactionCard({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final reviewStatus = transaction.reviewStatus;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transaction.carName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(reviewStatus),
                ],
              ),

              const SizedBox(height: 12),

              // Price
              Text(
                '₱${_formatPrice(transaction.agreedPrice)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.primary,
                ),
              ),

              const SizedBox(height: 12),

              // Seller/Buyer info
              Row(
                children: [
                  Expanded(
                    child: _buildPartyInfo(
                      'Seller',
                      transaction.sellerName,
                      Icons.store,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPartyInfo(
                      'Buyer',
                      transaction.buyerName,
                      Icons.person,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress indicators
              _buildProgressRow(),

              const Divider(height: 24),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${_formatDate(transaction.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorConstants.textSecondaryLight,
                    ),
                  ),
                  if (transaction.readyForReview)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorConstants.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 14,
                            color: ColorConstants.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Needs Review',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AdminReviewStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case AdminReviewStatus.pendingReview:
        color = ColorConstants.warning;
        icon = Icons.rate_review;
        break;
      case AdminReviewStatus.awaitingConfirmation:
        color = Colors.orange;
        icon = Icons.hourglass_bottom;
        break;
      case AdminReviewStatus.inProgress:
        color = Colors.blue;
        icon = Icons.pending_actions;
        break;
      case AdminReviewStatus.approved:
        color = ColorConstants.success;
        icon = Icons.verified;
        break;
      case AdminReviewStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case AdminReviewStatus.failed:
        color = ColorConstants.error;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyInfo(String label, String name, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ColorConstants.textSecondaryLight),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: ColorConstants.textSecondaryLight,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow() {
    return Row(
      children: [
        _buildProgressItem('Seller Form', transaction.sellerFormSubmitted),
        const SizedBox(width: 8),
        _buildProgressItem('Buyer Form', transaction.buyerFormSubmitted),
        const SizedBox(width: 8),
        _buildProgressItem('Both Confirmed', transaction.bothConfirmed),
        const SizedBox(width: 8),
        _buildProgressItem('Admin Approved', transaction.adminApproved),
      ],
    );
  }

  Widget _buildProgressItem(String label, bool completed) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: completed ? ColorConstants.success : Colors.grey[400],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: completed
                  ? ColorConstants.textPrimaryLight
                  : ColorConstants.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
