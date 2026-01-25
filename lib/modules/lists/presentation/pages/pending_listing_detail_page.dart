import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/app/di/app_module.dart';
import '../../domain/entities/listing_detail_entity.dart';
import '../../domain/entities/seller_listing_entity.dart';
import '../../domain/usecases/submission_usecases.dart';
import '../widgets/detail_sections/listing_cover_section.dart';
import '../widgets/detail_sections/listing_info_section.dart';
import '../widgets/invite_user_dialog.dart';

class PendingListingDetailPage extends StatefulWidget {
  final ListingDetailEntity listing;

  const PendingListingDetailPage({super.key, required this.listing});

  @override
  State<PendingListingDetailPage> createState() =>
      _PendingListingDetailPageState();
}

class _PendingListingDetailPageState extends State<PendingListingDetailPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Review')),
      backgroundColor: isDark
          ? ColorConstants.backgroundDark
          : ColorConstants.backgroundLight,
      body: Stack(
        children: [
          ListView(
            children: [
              ListingCoverSection(listing: widget.listing),
              const SizedBox(height: 16),
              _buildStatusCard(context, isDark),
              const SizedBox(height: 16),
              ListingInfoSection(listing: widget.listing),
              const SizedBox(height: 20),
              _buildActionButtons(context, isDark),
              const SizedBox(height: 16),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    // Determine if seller can invite users
    // Invites allowed: pending_approval (after admin approval), scheduled, or live
    final canInvite =
        widget.listing.status == ListingStatus.pending ||
        widget.listing.status == ListingStatus.scheduled ||
        widget.listing.status == ListingStatus.active;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Invite Users button - only show during pending_approval, scheduled, or live
          if (canInvite)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (_) => InviteUserDialog(
                                auctionId: widget.listing.id,
                                auctionTitle:
                                    '${widget.listing.year} ${widget.listing.brand} ${widget.listing.model}',
                              ),
                            );
                          },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite Users'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (canInvite) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _cancelListing(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel Listing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelListing(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Listing'),
        content: const Text(
          'Are you sure you want to cancel this listing? It will be moved to your cancelled listings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Listing'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await sl<CancelListingUseCase>().call(widget.listing.id);

      if (mounted) {
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${failure.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
            setState(() => _isLoading = false);
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Listing cancelled successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pop(context, true); // Return true to trigger list refresh
              }
            });
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatusCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.2),
            Colors.orange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pending_actions,
              size: 48,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Awaiting Admin Approval',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your listing is currently being reviewed by our admin team. This typically takes 24-48 hours.',
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
              Container(height: 2, width: 32, color: Colors.orange),
              Expanded(
                child: _StatusStep(
                  icon: Icons.pending,
                  label: 'Under Review',
                  isCompleted: false,
                  isDark: isDark,
                ),
              ),
              Container(
                height: 2,
                width: 32,
                color: isDark
                    ? ColorConstants.surfaceLight
                    : Colors.grey.shade300,
              ),
              Expanded(
                child: _StatusStep(
                  icon: Icons.rocket_launch,
                  label: 'Go Live',
                  isCompleted: false,
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
                  'We review all listings to ensure quality and accuracy. You\'ll be notified once approved.',
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
                ? Colors.orange.withValues(alpha: 0.2)
                : (isDark
                      ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
                      : Colors.grey.shade100),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 24,
            color: isCompleted
                ? Colors.orange
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
                ? Colors.orange
                : (isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight),
          ),
        ),
      ],
    );
  }
}
