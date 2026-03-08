import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';

class Step9Summary extends StatelessWidget {
  final ListingDraftController controller;
  final VoidCallback onSubmitSuccess;

  const Step9Summary({
    super.key,
    required this.controller,
    required this.onSubmitSuccess,
  });

  Future<void> _submitListing(BuildContext context) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';

    final success = await controller.submitListing(userId);

    if (!context.mounted) return;

    if (success) {
      onSubmitSuccess();
    } else if (controller.errorMessage != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          title: const Text('Submission Failed'),
          content: Text(controller.errorMessage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.currentDraft == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final draft = controller.currentDraft!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Step 9: Review & Submit',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildCompletionStatus(draft, isDark),
            const SizedBox(height: 24),
            _buildStepCard(
              1,
              'Photos',
              draft.isStepComplete(1),
              isDark,
              _photosDetails(draft),
            ),
            _buildStepCard(
              2,
              'Basic Information',
              draft.isStepComplete(2),
              isDark,
              _basicInfoDetails(draft),
            ),
            _buildStepCard(
              3,
              'Mechanical Specification',
              draft.isStepComplete(3),
              isDark,
              _mechanicalDetails(draft),
            ),
            _buildStepCard(
              4,
              'Dimensions & Capacity',
              draft.isStepComplete(4),
              isDark,
              _dimensionsDetails(draft),
            ),
            _buildStepCard(
              5,
              'Exterior Details',
              draft.isStepComplete(5),
              isDark,
              _exteriorDetails(draft),
            ),
            _buildStepCard(
              6,
              'Condition & History',
              draft.isStepComplete(6),
              isDark,
              _conditionDetails(draft),
            ),
            _buildStepCard(
              7,
              'Documentation & Location',
              draft.isStepComplete(7),
              isDark,
              _documentationDetails(draft),
            ),
            _buildStepCard(
              8,
              'Final Details & Pricing',
              draft.isStepComplete(8),
              isDark,
              _finalDetails(draft),
            ),
            const SizedBox(height: 24),
            _buildBiddingTypeSummary(draft, isDark),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed:
                  controller.isSubmitting || draft.completionPercentage < 100
                  ? null
                  : () => _submitListing(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Listing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompletionStatus(ListingDraftEntity draft, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.backgroundSecondaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? ColorConstants.textPrimaryDark
                  : ColorConstants.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: draft.completionPercentage / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${draft.completionPercentage.toStringAsFixed(0)}% Complete',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: draft.completionPercentage >= 100
                  ? Colors.green
                  : ColorConstants.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    int step,
    String title,
    bool isComplete,
    bool isDark,
    List<_DetailItem> details,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.backgroundSecondaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isComplete ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Step $step: $title',
                  style: TextStyle(
                    fontWeight: isComplete
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => controller.goToStep(step),
                child: const Text('Edit'),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const Divider(height: 16),
            ...details.map(
              (d) => Padding(
                padding: const EdgeInsets.only(left: 36, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        d.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        d.value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBiddingTypeSummary(ListingDraftEntity draft, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (draft.biddingType ?? 'public') == 'private'
            ? Colors.orange.withAlpha((0.08 * 255).toInt())
            : Colors.blue.withAlpha((0.08 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (draft.biddingType ?? 'public') == 'private'
              ? Colors.orange.withAlpha((0.3 * 255).toInt())
              : Colors.blue.withAlpha((0.3 * 255).toInt()),
        ),
      ),
      child: Row(
        children: [
          Icon(
            (draft.biddingType ?? 'public') == 'private'
                ? Icons.lock
                : Icons.public,
            color: (draft.biddingType ?? 'public') == 'private'
                ? Colors.orange
                : Colors.blue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bidding Type',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (draft.biddingType ?? 'public') == 'private'
                      ? 'Private Auction'
                      : 'Public Auction',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Detail builders per step
  List<_DetailItem> _photosDetails(ListingDraftEntity draft) {
    final count =
        draft.photoUrls?.values.fold<int>(
          0,
          (sum, urls) => sum + urls.length,
        ) ??
        0;
    final items = <_DetailItem>[];
    if (count > 0) items.add(_DetailItem('Photos', '$count / 56 uploaded'));
    if (draft.coverPhotoUrl != null)
      items.add(_DetailItem('Cover Photo', 'Selected'));
    if (draft.deedOfSaleUrl != null)
      items.add(_DetailItem('Deed of Sale', 'Uploaded'));
    return items;
  }

  List<_DetailItem> _basicInfoDetails(ListingDraftEntity draft) {
    return [
      if (draft.brand != null) _DetailItem('Brand', draft.brand!),
      if (draft.model != null) _DetailItem('Model', draft.model!),
      if (draft.variant != null) _DetailItem('Variant', draft.variant!),
      if (draft.bodyType != null) _DetailItem('Body Type', draft.bodyType!),
      if (draft.year != null) _DetailItem('Year', '${draft.year}'),
    ];
  }

  List<_DetailItem> _mechanicalDetails(ListingDraftEntity draft) {
    return [
      if (draft.engineType != null) _DetailItem('Engine', draft.engineType!),
      if (draft.engineDisplacement != null)
        _DetailItem('Displacement', '${draft.engineDisplacement}L'),
      if (draft.horsepower != null)
        _DetailItem('Horsepower', '${draft.horsepower} hp'),
      if (draft.torque != null) _DetailItem('Torque', '${draft.torque} Nm'),
      if (draft.transmission != null)
        _DetailItem('Transmission', draft.transmission!),
      if (draft.fuelType != null) _DetailItem('Fuel Type', draft.fuelType!),
      if (draft.driveType != null) _DetailItem('Drive Type', draft.driveType!),
    ];
  }

  List<_DetailItem> _dimensionsDetails(ListingDraftEntity draft) {
    return [
      if (draft.length != null) _DetailItem('Length', '${draft.length} mm'),
      if (draft.width != null) _DetailItem('Width', '${draft.width} mm'),
      if (draft.height != null) _DetailItem('Height', '${draft.height} mm'),
      if (draft.wheelbase != null)
        _DetailItem('Wheelbase', '${draft.wheelbase} mm'),
      if (draft.groundClearance != null)
        _DetailItem('Ground Clearance', '${draft.groundClearance} mm'),
      if (draft.seatingCapacity != null)
        _DetailItem('Seats', '${draft.seatingCapacity}'),
      if (draft.doorCount != null) _DetailItem('Doors', '${draft.doorCount}'),
      if (draft.fuelTankCapacity != null)
        _DetailItem('Fuel Tank', '${draft.fuelTankCapacity}L'),
      if (draft.curbWeight != null)
        _DetailItem('Curb Weight', '${draft.curbWeight} kg'),
    ];
  }

  List<_DetailItem> _exteriorDetails(ListingDraftEntity draft) {
    return [
      if (draft.exteriorColor != null)
        _DetailItem('Color', draft.exteriorColor!),
      if (draft.paintType != null) _DetailItem('Paint', draft.paintType!),
      if (draft.rimType != null) _DetailItem('Rim Type', draft.rimType!),
      if (draft.rimSize != null) _DetailItem('Rim Size', '${draft.rimSize}"'),
      if (draft.tireSize != null) _DetailItem('Tire Size', draft.tireSize!),
      if (draft.tireBrand != null) _DetailItem('Tire Brand', draft.tireBrand!),
    ];
  }

  List<_DetailItem> _conditionDetails(ListingDraftEntity draft) {
    return [
      if (draft.condition != null) _DetailItem('Condition', draft.condition!),
      if (draft.mileage != null) _DetailItem('Mileage', '${draft.mileage} km'),
      if (draft.previousOwners != null)
        _DetailItem('Prev. Owners', '${draft.previousOwners}'),
      if (draft.usageType != null) _DetailItem('Usage', draft.usageType!),
      if (draft.hasModifications == true)
        _DetailItem('Modified', draft.modificationsDetails ?? 'Yes'),
      if (draft.hasWarranty == true)
        _DetailItem('Warranty', draft.warrantyDetails ?? 'Yes'),
    ];
  }

  List<_DetailItem> _documentationDetails(ListingDraftEntity draft) {
    return [
      if (draft.plateNumber != null) _DetailItem('Plate', draft.plateNumber!),
      if (draft.orcrStatus != null) _DetailItem('OR/CR', draft.orcrStatus!),
      if (draft.registrationStatus != null)
        _DetailItem('Registration', draft.registrationStatus!),
      if (draft.province != null) _DetailItem('Province', draft.province!),
      if (draft.cityMunicipality != null)
        _DetailItem('City', draft.cityMunicipality!),
      if (draft.barangay != null) _DetailItem('Barangay', draft.barangay!),
    ];
  }

  List<_DetailItem> _finalDetails(ListingDraftEntity draft) {
    return [
      if (draft.description != null && draft.description!.length > 50)
        _DetailItem('Description', '${draft.description!.substring(0, 50)}...'),
      if (draft.description != null && draft.description!.length <= 50)
        _DetailItem('Description', draft.description!),
      if (draft.startingPrice != null)
        _DetailItem(
          'Starting Price',
          '₱${draft.startingPrice!.toStringAsFixed(0)}',
        ),
      if (draft.reservePrice != null)
        _DetailItem(
          'Reserve Price',
          '₱${draft.reservePrice!.toStringAsFixed(0)}',
        ),
      if (draft.bidIncrement != null)
        _DetailItem(
          'Bid Increment',
          '₱${draft.bidIncrement!.toStringAsFixed(0)}',
        ),
      if (draft.depositAmount != null)
        _DetailItem('Deposit', '₱${draft.depositAmount!.toStringAsFixed(0)}'),
      if (draft.features != null && draft.features!.isNotEmpty)
        _DetailItem('Features', '${draft.features!.length} listed'),
      if (draft.auctionEndDate != null)
        _DetailItem('End Time', _formatDate(draft.auctionEndDate!)),
    ];
  }

  String _formatDate(DateTime dt) {
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _DetailItem {
  final String label;
  final String value;
  const _DetailItem(this.label, this.value);
}
