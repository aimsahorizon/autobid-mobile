import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../domain/entities/auction_detail_entity.dart';

class CarInfoTab extends StatelessWidget {
  final AuctionDetailEntity auction;

  const CarInfoTab({super.key, required this.auction});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OverviewSection(auction: auction),
          const SizedBox(height: 24),
          _EnginePerformanceSection(auction: auction),
          const SizedBox(height: 24),
          _DimensionsSection(auction: auction),
          const SizedBox(height: 24),
          _ExteriorSection(auction: auction),
          const SizedBox(height: 24),
          _ConditionHistorySection(auction: auction),
          const SizedBox(height: 24),
          _DocumentationSection(auction: auction),
          const SizedBox(height: 24),
          if (auction.features != null && auction.features!.isNotEmpty)
            _FeaturesSection(auction: auction),
          if (auction.features != null && auction.features!.isNotEmpty)
            const SizedBox(height: 24),
          _AuctionConfigSection(auction: auction),
          const SizedBox(height: 24),
          if (auction.description != null || auction.knownIssues != null)
            _DescriptionSection(auction: auction),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _AuctionConfigSection extends StatelessWidget {
  final AuctionDetailEntity auction;

  const _AuctionConfigSection({required this.auction});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Auction Settings',
      child: Column(
        children: [
          _InfoRow(
            label: 'Bidding Type',
            value: auction.biddingType == 'public' ? 'Public' : 'Private',
          ),
          _InfoRow(
            label: 'Increment Type',
            value: auction.enableIncrementalBidding ? 'Dynamic' : 'Fixed',
          ),
          if (!auction.enableIncrementalBidding)
            _InfoRow(
              label: 'Min Increment',
              value: '₱${auction.minBidIncrement.toStringAsFixed(0)}',
            ),
          _InfoRow(
            label: 'Buyer Deposit',
            value: '₱${auction.depositAmount.toStringAsFixed(0)}',
          ),
          _InfoRow(
            label: 'Snipe Guard',
            value: auction.snipeGuardEnabled ? 'Enabled' : 'Disabled',
          ),
          if (auction.snipeGuardEnabled)
            _InfoRow(
              label: 'Extension',
              value: '+${auction.snipeGuardExtendSeconds}s',
            ),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final AuctionDetailEntity auction;

  const _OverviewSection({required this.auction});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Overview',
      child: Column(
        children: [
          _InfoRow(label: 'Brand', value: auction.brand),
          _InfoRow(label: 'Model', value: auction.model),
          if (auction.variant != null)
            _InfoRow(label: 'Variant', value: auction.variant!),
          _InfoRow(label: 'Year', value: auction.year.toString()),
          if (auction.mileage != null)
            _InfoRow(label: 'Mileage', value: '${auction.mileage!.toStringAsFixed(0)} km'),
          if (auction.transmission != null)
            _InfoRow(label: 'Transmission', value: auction.transmission!),
          if (auction.fuelType != null)
            _InfoRow(label: 'Fuel Type', value: auction.fuelType!),
          if (auction.exteriorColor != null)
            _InfoRow(label: 'Color', value: auction.exteriorColor!),
          if (auction.condition != null)
            _InfoRow(label: 'Condition', value: auction.condition!),
          if (auction.previousOwners != null)
            _InfoRow(label: 'Previous Owners', value: auction.previousOwners!.toString()),
        ],
      ),
    );
  }
}

class _EnginePerformanceSection extends StatelessWidget {
  final AuctionDetailEntity auction;

  const _EnginePerformanceSection({required this.auction});

  @override
  Widget build(BuildContext context) {
    // Only show if we have engine data
    if (auction.engineType == null &&
        auction.horsepower == null &&
        auction.torque == null) {
      return const SizedBox.shrink();
    }

    return _InfoCard(
      title: 'Engine & Performance',
      child: Column(
        children: [
          if (auction.engineType != null)
            _InfoRow(label: 'Engine', value: auction.engineType!),
          if (auction.engineDisplacement != null)
            _InfoRow(
              label: 'Displacement',
              value: '${auction.engineDisplacement!}L',
            ),
          if (auction.cylinderCount != null)
            _InfoRow(label: 'Cylinders', value: '${auction.cylinderCount}'),
          if (auction.horsepower != null)
            _InfoRow(label: 'Horsepower', value: '${auction.horsepower} hp'),
          if (auction.torque != null)
            _InfoRow(label: 'Torque', value: '${auction.torque} Nm'),
          if (auction.transmission != null)
            _InfoRow(label: 'Transmission', value: auction.transmission!),
          if (auction.driveType != null)
            _InfoRow(label: 'Drive Type', value: auction.driveType!),
          if (auction.fuelType != null)
            _InfoRow(label: 'Fuel Type', value: auction.fuelType!),
        ],
      ),
    );
  }
}

class _DimensionsSection extends StatelessWidget {
  final AuctionDetailEntity auction;

  const _DimensionsSection({required this.auction});

  @override
  Widget build(BuildContext context) {
    // Only show if we have dimension data
    if (auction.length == null &&
        auction.seatingCapacity == null &&
        auction.fuelTankCapacity == null) {
      return const SizedBox.shrink();
    }

    return _InfoCard(
      title: 'Dimensions & Capacity',
      child: Column(
        children: [
          if (auction.length != null)
            _InfoRow(label: 'Length', value: '${auction.length!.toStringAsFixed(0)} mm'),
          if (auction.width != null)
            _InfoRow(label: 'Width', value: '${auction.width!.toStringAsFixed(0)} mm'),
          if (auction.height != null)
            _InfoRow(label: 'Height', value: '${auction.height!.toStringAsFixed(0)} mm'),
          if (auction.wheelbase != null)
            _InfoRow(label: 'Wheelbase', value: '${auction.wheelbase!.toStringAsFixed(0)} mm'),
          if (auction.groundClearance != null)
            _InfoRow(
              label: 'Ground Clearance',
              value: '${auction.groundClearance!.toStringAsFixed(0)} mm',
            ),
          if (auction.seatingCapacity != null)
            _InfoRow(label: 'Seating', value: '${auction.seatingCapacity} seats'),
          if (auction.doorCount != null)
            _InfoRow(label: 'Doors', value: '${auction.doorCount}'),
          if (auction.fuelTankCapacity != null)
            _InfoRow(label: 'Fuel Tank', value: '${auction.fuelTankCapacity!.toStringAsFixed(0)}L'),
          if (auction.curbWeight != null)
            _InfoRow(label: 'Curb Weight', value: '${auction.curbWeight!.toStringAsFixed(0)} kg'),
          if (auction.grossWeight != null)
            _InfoRow(label: 'Gross Weight', value: '${auction.grossWeight!.toStringAsFixed(0)} kg'),
        ],
      ),
    );
  }
}

class _ExteriorSection extends StatelessWidget {
  final AuctionDetailEntity auction;

  const _ExteriorSection({required this.auction});

  @override
  Widget build(BuildContext context) {
    // Only show if we have exterior data
    if (auction.exteriorColor == null &&
        auction.rimType == null &&
        auction.tireSize == null) {
      return const SizedBox.shrink();
    }

    return _InfoCard(
      title: 'Exterior Details',
      child: Column(
        children: [
          if (auction.exteriorColor != null)
            _InfoRow(label: 'Color', value: auction.exteriorColor!),
          if (auction.paintType != null)
            _InfoRow(label: 'Paint Type', value: auction.paintType!),
          if (auction.rimType != null)
            _InfoRow(label: 'Rim Type', value: auction.rimType!),
          if (auction.rimSize != null)
            _InfoRow(label: 'Rim Size', value: auction.rimSize!),
          if (auction.tireSize != null)
            _InfoRow(label: 'Tire Size', value: auction.tireSize!),
          if (auction.tireBrand != null)
            _InfoRow(label: 'Tire Brand', value: auction.tireBrand!),
        ],
      ),
    );
  }
}

class _ConditionHistorySection extends StatelessWidget {
  final AuctionDetailEntity auction;

  const _ConditionHistorySection({required this.auction});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Condition & History',
      child: Column(
        children: [
          if (auction.condition != null)
            _InfoRow(label: 'Overall Condition', value: auction.condition!),
          if (auction.mileage != null)
            _InfoRow(label: 'Mileage', value: '${auction.mileage!.toStringAsFixed(0)} km'),
          if (auction.previousOwners != null)
            _InfoRow(label: 'Previous Owners', value: '${auction.previousOwners}'),
          if (auction.usageType != null)
            _InfoRow(label: 'Usage Type', value: auction.usageType!),
          if (auction.hasModifications != null)
            _InfoRow(
              label: 'Modifications',
              value: auction.hasModifications!
                ? (auction.modificationsDetails ?? 'Yes')
                : 'None',
            ),
          if (auction.hasWarranty != null)
            _InfoRow(
              label: 'Warranty',
              value: auction.hasWarranty!
                ? (auction.warrantyDetails ?? 'Yes')
                : 'No warranty',
            ),
        ],
      ),
    );
  }
}

class _DocumentationSection extends StatelessWidget {
  final AuctionDetailEntity auction;

  const _DocumentationSection({required this.auction});

  @override
  Widget build(BuildContext context) {
    // Only show if we have documentation data
    if (auction.plateNumber == null &&
        auction.orcrStatus == null &&
        auction.province == null &&
        auction.deedOfSaleUrl == null) {
      return const SizedBox.shrink();
    }

    return _InfoCard(
      title: 'Documentation & Location',
      child: Column(
        children: [
          if (auction.deedOfSaleUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Deed of Sale Verified',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (auction.plateNumber != null)
            _InfoRow(label: 'Plate Number', value: auction.plateNumber!),
          if (auction.orcrStatus != null)
            _InfoRow(label: 'OR/CR Status', value: auction.orcrStatus!),
          if (auction.registrationStatus != null)
            _InfoRow(label: 'Registration', value: auction.registrationStatus!),
          if (auction.registrationExpiry != null)
            _InfoRow(
              label: 'Registration Expiry',
              value: '${auction.registrationExpiry!.month}/${auction.registrationExpiry!.day}/${auction.registrationExpiry!.year}',
            ),
          if (auction.province != null || auction.cityMunicipality != null)
            _InfoRow(
              label: 'Location',
              value: [
                if (auction.cityMunicipality != null) auction.cityMunicipality,
                if (auction.province != null) auction.province,
              ].join(', '),
            ),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  final AuctionDetailEntity auction;

  const _FeaturesSection({required this.auction});

  @override
  Widget build(BuildContext context) {
    if (auction.features == null || auction.features!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _InfoCard(
      title: 'Features & Equipment',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: auction.features!.map((f) => _FeatureChip(label: f)).toList(),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final AuctionDetailEntity auction;

  const _DescriptionSection({required this.auction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _InfoCard(
      title: 'Seller Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (auction.description != null) ...[
            Text(
              'Description',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              auction.description!,
              style: theme.textTheme.bodyMedium,
            ),
            if (auction.knownIssues != null) const SizedBox(height: 16),
          ],
          if (auction.knownIssues != null) ...[
            Text(
              'Known Issues',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auction.knownIssues!,
                      style: theme.textTheme.bodyMedium,
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
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;

  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ColorConstants.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: ColorConstants.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: ColorConstants.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
