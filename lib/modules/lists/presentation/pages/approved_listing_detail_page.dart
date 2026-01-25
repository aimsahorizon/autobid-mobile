import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../domain/entities/listing_detail_entity.dart';
import '../widgets/detail_sections/listing_cover_section.dart';
import '../widgets/detail_sections/listing_info_section.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../data/datasources/listing_supabase_datasource.dart';
import '../../domain/entities/seller_listing_entity.dart';

class ApprovedListingDetailPage extends StatelessWidget {
  final ListingDetailEntity listing;
  late final ListingSupabaseDataSource _datasource = ListingSupabaseDataSource(
    SupabaseConfig.client,
  );

  // Prevent repeated auto-start calls when scheduled time has passed
  static final Set<String> _autoStartTriggered = {};

  ApprovedListingDetailPage({super.key, required this.listing});

  Future<void> _makeListingLive(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go Live Now'),
        content: const Text(
          'Start the auction immediately? Bidders can place bids right away.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Go Live'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final now = DateTime.now();
      final currentEnd = listing.endTime;
      // Ensure end_time stays after start_time to satisfy constraint
      final safeEnd =
          (currentEnd != null && currentEnd.isAfter(now))
              ? currentEnd
              : now.add(const Duration(days: 7));

      // Update listing status to live with aligned start/end
      await _datasource.updateListingStatusByName(
        listing.id,
        'live',
        additionalData: {
          'start_time': now.toIso8601String(),
          'end_time': safeEnd.toIso8601String(),
        },
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(
        context,
        true,
      ); // Return true to trigger reload in ListingsGrid

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auction is now live!'),
          backgroundColor: ColorConstants.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to go live: $e'),
          backgroundColor: ColorConstants.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _scheduleListingLater(BuildContext context) async {
    final now = DateTime.now();
    // Clamp initial picker value to be >= today to avoid showDatePicker assertion
    final baseRaw = listing.startTime ?? now.add(const Duration(hours: 1));
    final base = baseRaw.isBefore(now) ? now.add(const Duration(hours: 1)) : baseRaw;

    // Step 1: choose date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate == null) return;

    // Step 2: choose time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );

    if (pickedTime == null) return;
    if (!context.mounted) return;

    final scheduledStart = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Ensure end_time remains after the new start_time
    final currentEnd = listing.endTime;
    final safeEnd = (currentEnd != null && currentEnd.isAfter(scheduledStart))
        ? currentEnd
        : scheduledStart.add(const Duration(days: 7));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule for Later'),
        content: Text(
          'Start auction on ${pickedDate.month}/${pickedDate.day}/${pickedDate.year} '
          'at ${pickedTime.format(context)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Update listing status to scheduled with start/end time
      await _datasource.updateListingStatusByName(
        listing.id,
        'scheduled',
        additionalData: {
          'start_time': scheduledStart.toIso8601String(),
          'end_time': safeEnd.toIso8601String(),
        },
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(
        context,
        true,
      ); // Return true to trigger reload in ListingsGrid

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Auction scheduled for ${pickedDate.month}/${pickedDate.day}/${pickedDate.year} at ${pickedTime.format(context)}',
          ),
          backgroundColor: ColorConstants.info,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule: $e'),
          backgroundColor: ColorConstants.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isScheduled = listing.status == ListingStatus.scheduled;

    // Auto-start if scheduled time already passed
    final shouldAutoStart = isScheduled &&
        listing.startTime != null &&
        listing.startTime!.isBefore(DateTime.now()) &&
        !_autoStartTriggered.contains(listing.id);

    if (shouldAutoStart) {
      _autoStartTriggered.add(listing.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _makeListingLive(context);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isScheduled ? 'Scheduled Listing' : 'Approved Listing'),
      ),
      backgroundColor: isDark
          ? ColorConstants.backgroundDark
          : ColorConstants.backgroundLight,
      body: ListView(
        children: [
          ListingCoverSection(listing: listing),
          const SizedBox(height: 16),
          _buildStatusCard(context, isDark, isScheduled),
          const SizedBox(height: 16),
          ListingInfoSection(listing: listing),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, isDark, isScheduled),
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isDark, bool isScheduled) {
    final startTime = listing.startTime;
    final timeUntil = listing.timeUntilStart;

    final gradientColors = isScheduled
        ? [
            Colors.purple.withValues(alpha: 0.2),
            Colors.purple.withValues(alpha: 0.1),
          ]
        : [
            ColorConstants.success.withValues(alpha: 0.2),
            ColorConstants.success.withValues(alpha: 0.1),
          ];

    final accentColor = isScheduled ? Colors.purple : ColorConstants.success;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isScheduled ? Icons.schedule : Icons.check_circle,
              size: 48,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isScheduled ? 'Auction Scheduled' : 'Listing Approved!',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (isScheduled && startTime != null) ...[
            Text(
              'Starts ${_formatDate(startTime)} at ${_formatTime(startTime)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              timeUntil != null && !timeUntil.isNegative
                  ? 'Goes live in ${_formatDuration(timeUntil)}'
                  : 'Starts soon',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          ]
          else
            Text(
              'Your listing has been approved! Choose to go live now or schedule for later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatusStep(
                  icon: Icons.check_circle,
                  label: 'Submitted',
                  isCompleted: true,
                  isDark: isDark,
                ),
              ),
              Container(height: 2, width: 32, color: ColorConstants.success),
              Expanded(
                child: _StatusStep(
                  icon: Icons.check_circle,
                  label: 'Approved',
                  isCompleted: true,
                  isDark: isDark,
                ),
              ),
              Container(
                height: 2,
                width: 32,
                color: isScheduled
                    ? ColorConstants.success
                    : (isDark
                          ? ColorConstants.surfaceLight
                          : Colors.grey.shade300),
              ),
              Expanded(
                child: _StatusStep(
                  icon: isScheduled ? Icons.schedule : Icons.rocket_launch,
                  label: isScheduled ? 'Scheduled' : 'Go Live',
                  isCompleted: isScheduled,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isScheduled
                      ? 'Scheduled start is set. You can reschedule or start early.'
                      : 'Go Live: Start auction now  •  Schedule: Set start time for later',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    bool isDark,
    bool isScheduled,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _scheduleListingLater(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isScheduled ? Colors.purple : ColorConstants.info,
                    side: const BorderSide(
                      color: ColorConstants.info,
                      width: 2,
                    ),
                  ),
                  icon: Icon(isScheduled ? Icons.edit_calendar : Icons.schedule),
                  label: Text(
                    isScheduled ? 'Reschedule' : 'Schedule',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => _makeListingLive(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: isScheduled ? Colors.deepPurple : ColorConstants.success,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.rocket_launch),
                  label: Text(
                    isScheduled ? 'Start Now' : 'Go Live',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}/${dt.year}';

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _formatDuration(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }
}

class _StatusStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCompleted;
  final bool isDark;

  const _StatusStep({
    required this.icon,
    required this.label,
    required this.isCompleted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted
                ? ColorConstants.success.withValues(alpha: 0.2)
                : (isDark
                      ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
                      : Colors.grey.shade100),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 24,
            color: isCompleted
                ? ColorConstants.success
                : (isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
            color: isCompleted
                ? ColorConstants.success
                : (isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight),
          ),
        ),
      ],
    );
  }
}
