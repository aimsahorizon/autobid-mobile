import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../domain/entities/bid_detail_entity.dart';

class CarInfoSection extends StatelessWidget {
  final BidDetailEntity bidDetail;

  const CarInfoSection({
    super.key,
    required this.bidDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, size: 20, color: ColorConstants.primary),
              const SizedBox(width: 8),
              Text(
                'Car Specifications',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (bidDetail.engineType != null || bidDetail.horsepower != null) ...[
            _SpecRow(
              label: 'Engine',
              value: '${bidDetail.engineType ?? 'N/A'} • ${bidDetail.horsepower ?? 'N/A'} HP',
            ),
            const SizedBox(height: 12),
          ],
          if (bidDetail.transmission != null) ...[
            _SpecRow(label: 'Transmission', value: bidDetail.transmission!),
            const SizedBox(height: 12),
          ],
          if (bidDetail.fuelType != null) ...[
            _SpecRow(label: 'Fuel Type', value: bidDetail.fuelType!),
            const SizedBox(height: 12),
          ],
          if (bidDetail.exteriorColor != null) ...[
            _SpecRow(label: 'Color', value: bidDetail.exteriorColor!),
            const SizedBox(height: 12),
          ],
          if (bidDetail.mileage != null) ...[
            _SpecRow(
              label: 'Mileage',
              value: '${bidDetail.mileage!.toStringAsFixed(0)} km',
            ),
          ],
          if (bidDetail.description != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bidDetail.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
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
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
