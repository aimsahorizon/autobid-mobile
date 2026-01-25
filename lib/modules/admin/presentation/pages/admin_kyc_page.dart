import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../domain/entities/kyc_document_entity.dart';
import '../controllers/kyc_controller.dart';
import 'admin_kyc_review_page.dart';

class AdminKycPage extends StatefulWidget {
  final KycController controller;

  const AdminKycPage({super.key, required this.controller});

  @override
  State<AdminKycPage> createState() => _AdminKycPageState();
}

class _AdminKycPageState extends State<AdminKycPage>
    with AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> _statusFilters = [
    {'value': 'pending', 'label': 'Pending', 'icon': Icons.pending_actions},
    {
      'value': 'under_review',
      'label': 'Under Review',
      'icon': Icons.rate_review
    },
    {'value': 'approved', 'label': 'Approved', 'icon': Icons.check_circle},
    {'value': 'rejected', 'label': 'Rejected', 'icon': Icons.cancel},
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
    await Future.wait([
      widget.controller.loadStats(),
      widget.controller.loadSubmissions(status: 'pending'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // Stats Banner
        ListenableBuilder(
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
                    'Pending',
                    stats.needsReview.toString(),
                    Icons.pending_actions,
                    ColorConstants.warning,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'SLA Risk',
                    stats.slaAtRisk.toString(),
                    Icons.warning_amber,
                    Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Approved',
                    stats.approved.toString(),
                    Icons.check_circle,
                    ColorConstants.success,
                  ),
                ],
              ),
            );
          },
        ),

        // Status Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: ColorConstants.surfaceVariantLight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                return Row(
                  children: _statusFilters.map((filter) {
                    final isSelected =
                        widget.controller.selectedStatus == filter['value'];
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
                            widget.controller.loadSubmissions(
                              status: filter['value'] as String,
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
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),

        // KYC Submissions List
        Expanded(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              if (widget.controller.isLoading &&
                  widget.controller.submissions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (widget.controller.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: ColorConstants.error,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading KYC submissions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.controller.error!),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => widget.controller.refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final submissions = widget.controller.submissions;

              if (submissions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 64,
                        color: ColorConstants.textSecondaryLight,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No KYC submissions found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No submissions for selected status',
                        style: TextStyle(
                          color: ColorConstants.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => widget.controller.refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final submission = submissions[index];
                    return _buildKycCard(context, submission);
                  },
                ),
              );
            },
          ),
        ),
      ],
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
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorConstants.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycCard(BuildContext context, KycDocumentEntity submission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminKycReviewPage(
                controller: widget.controller,
                kycDocumentId: submission.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name and Status
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(submission.statusName)
                        .withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      color: _getStatusColor(submission.statusName),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          submission.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          submission.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorConstants.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(submission.statusName),
                ],
              ),

              const Divider(height: 24),

              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.calendar_today,
                      'Submitted',
                      submission.submittedAt != null
                          ? _formatDate(submission.submittedAt!)
                          : 'N/A',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.description,
                      'Documents',
                      '${submission.documentCount} files',
                    ),
                  ),
                ],
              ),

              if (submission.isSlaAtRisk || submission.isSlaBreached) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: submission.isSlaBreached
                        ? ColorConstants.error.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: submission.isSlaBreached
                          ? ColorConstants.error
                          : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        submission.isSlaBreached
                            ? Icons.error
                            : Icons.warning_amber,
                        size: 16,
                        color: submission.isSlaBreached
                            ? ColorConstants.error
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          submission.isSlaBreached
                              ? 'SLA Breached - Immediate action required'
                              : 'SLA at risk - Review soon',
                          style: TextStyle(
                            fontSize: 12,
                            color: submission.isSlaBreached
                                ? ColorConstants.error
                                : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (submission.rejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstants.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: ColorConstants.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          submission.rejectionReason!,
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorConstants.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: ColorConstants.textSecondaryLight,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: ColorConstants.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return ColorConstants.success;
      case 'rejected':
        return ColorConstants.error;
      case 'under_review':
        return Colors.blue;
      case 'pending':
        return ColorConstants.warning;
      case 'expired':
        return ColorConstants.textSecondaryLight;
      default:
        return ColorConstants.textSecondaryLight;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'under_review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
