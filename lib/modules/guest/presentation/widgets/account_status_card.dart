import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/account_status_entity.dart';

class AccountStatusCard extends StatelessWidget {
  final AccountStatusEntity status;

  const AccountStatusCard({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getStatusColor(status.status).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildStatusBadge(theme),
            const SizedBox(height: 16),
            _buildDescription(theme, isDark),
            const SizedBox(height: 20),
            _buildTimeline(theme, isDark),
            if (_shouldShowReviewNotes()) ...[
              const SizedBox(height: 16),
              _buildReviewNotes(theme, isDark),
            ],
            if (_shouldShowNextSteps()) ...[
              const SizedBox(height: 16),
              _buildNextSteps(theme, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getStatusColor(status.status).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getStatusIcon(status.status),
            color: _getStatusColor(status.status),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.userName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                status.userEmail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(status.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(status.status).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status.status),
            color: _getStatusColor(status.status),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            status.status.displayName,
            style: theme.textTheme.labelLarge?.copyWith(
              color: _getStatusColor(status.status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ThemeData theme, bool isDark) {
    return Text(
      status.status.description,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isDark
            ? ColorConstants.textSecondaryDark
            : ColorConstants.textSecondaryLight,
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme, bool isDark) {
    return Column(
      children: [
        _buildTimelineItem(
          theme,
          isDark,
          icon: Icons.send_rounded,
          title: 'Submitted',
          date: _formatDate(status.submittedAt),
          isCompleted: true,
        ),
        if (status.status == AccountStatus.underReview)
          _buildTimelineItem(
            theme,
            isDark,
            icon: Icons.search_rounded,
            title: 'Under Review',
            date: 'In progress',
            isCompleted: true,
          ),
        if (status.reviewedAt != null &&
            (status.status == AccountStatus.approved ||
             status.status == AccountStatus.rejected ||
             status.status == AccountStatus.suspended))
          _buildTimelineItem(
            theme,
            isDark,
            icon: _getReviewedIcon(status.status),
            title: _getReviewedTitle(status.status),
            date: _formatDate(status.reviewedAt!),
            isCompleted: true,
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} - ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  Widget _buildTimelineItem(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String date,
    required bool isCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: isCompleted
                ? ColorConstants.success
                : (isDark ? Colors.grey[600] : Colors.grey[400]),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date,
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
    );
  }

  Widget _buildReviewNotes(ThemeData theme, bool isDark) {
    final noteColor = status.status == AccountStatus.rejected
        ? ColorConstants.error
        : (status.status == AccountStatus.suspended
            ? Colors.grey
            : ColorConstants.warning);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: noteColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: noteColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getReviewNotesIcon(),
                color: noteColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _getReviewNotesTitle(),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: noteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status.reviewNotes!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: noteColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextSteps(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorConstants.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: ColorConstants.info,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getNextStepsMessage(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: ColorConstants.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowReviewNotes() {
    return (status.status == AccountStatus.rejected ||
            status.status == AccountStatus.suspended) &&
        status.reviewNotes != null &&
        status.reviewNotes!.isNotEmpty;
  }

  bool _shouldShowNextSteps() {
    return status.status == AccountStatus.pending ||
        status.status == AccountStatus.underReview ||
        status.status == AccountStatus.approved;
  }

  String _getNextStepsMessage() {
    switch (status.status) {
      case AccountStatus.pending:
        return 'Your KYC submission is pending review. You will be notified once the review process begins.';
      case AccountStatus.underReview:
        return 'Your KYC documents are currently being reviewed. This typically takes 1-3 business days.';
      case AccountStatus.approved:
        return 'Your account has been approved! You can now log in and access all features.';
      case AccountStatus.rejected:
      case AccountStatus.suspended:
        return '';
    }
  }

  IconData _getReviewedIcon(AccountStatus status) {
    switch (status) {
      case AccountStatus.approved:
        return Icons.check_circle_rounded;
      case AccountStatus.rejected:
        return Icons.cancel_rounded;
      case AccountStatus.suspended:
        return Icons.block_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String _getReviewedTitle(AccountStatus status) {
    switch (status) {
      case AccountStatus.approved:
        return 'Approved';
      case AccountStatus.rejected:
        return 'Rejected';
      case AccountStatus.suspended:
        return 'Suspended';
      default:
        return 'Reviewed';
    }
  }

  IconData _getReviewNotesIcon() {
    switch (status.status) {
      case AccountStatus.rejected:
        return Icons.error_outline_rounded;
      case AccountStatus.suspended:
        return Icons.warning_amber_rounded;
      default:
        return Icons.note_outlined;
    }
  }

  String _getReviewNotesTitle() {
    switch (status.status) {
      case AccountStatus.rejected:
        return 'Rejection Reason';
      case AccountStatus.suspended:
        return 'Suspension Reason';
      default:
        return 'Review Notes';
    }
  }

  Color _getStatusColor(AccountStatus status) {
    switch (status) {
      case AccountStatus.pending:
        return ColorConstants.warning;
      case AccountStatus.underReview:
        return ColorConstants.info;
      case AccountStatus.approved:
        return ColorConstants.success;
      case AccountStatus.rejected:
        return ColorConstants.error;
      case AccountStatus.suspended:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(AccountStatus status) {
    switch (status) {
      case AccountStatus.pending:
        return Icons.schedule_rounded;
      case AccountStatus.underReview:
        return Icons.search_rounded;
      case AccountStatus.approved:
        return Icons.check_circle_rounded;
      case AccountStatus.rejected:
        return Icons.cancel_rounded;
      case AccountStatus.suspended:
        return Icons.block_rounded;
    }
  }
}
