import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';

class CarInfoTab extends StatelessWidget {
  const CarInfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _OverviewSection(),
          SizedBox(height: 24),
          _SpecificationsSection(),
          SizedBox(height: 24),
          _FeaturesSection(),
          SizedBox(height: 24),
          _ConditionSection(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Overview',
      child: Column(
        children: const [
          _InfoRow(label: 'Make', value: 'Toyota'),
          _InfoRow(label: 'Model', value: 'Supra GR'),
          _InfoRow(label: 'Year', value: '2023'),
          _InfoRow(label: 'Mileage', value: '12,500 km'),
          _InfoRow(label: 'Transmission', value: 'Automatic'),
          _InfoRow(label: 'Fuel Type', value: 'Gasoline'),
          _InfoRow(label: 'Color', value: 'Renaissance Red 2.0'),
        ],
      ),
    );
  }
}

class _SpecificationsSection extends StatelessWidget {
  const _SpecificationsSection();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Specifications',
      child: Column(
        children: const [
          _InfoRow(label: 'Engine', value: '3.0L Inline-6 Turbo'),
          _InfoRow(label: 'Horsepower', value: '382 hp @ 5,800 rpm'),
          _InfoRow(label: 'Torque', value: '368 lb-ft @ 1,800 rpm'),
          _InfoRow(label: '0-100 km/h', value: '4.1 seconds'),
          _InfoRow(label: 'Top Speed', value: '250 km/h (limited)'),
          _InfoRow(label: 'Drive Type', value: 'Rear-Wheel Drive'),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final features = [
      'Premium JBL Sound System',
      'Wireless Apple CarPlay',
      'Adaptive Sport Suspension',
      'Launch Control',
      'Sport Differential',
      'Brembo Brakes',
      'HUD Display',
      'Navigation System',
      'Heated Seats',
      'Keyless Entry',
    ];

    return _InfoCard(
      title: 'Features & Equipment',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: features.map((f) => _FeatureChip(label: f)).toList(),
      ),
    );
  }
}

class _ConditionSection extends StatelessWidget {
  const _ConditionSection();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Condition Report',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ConditionBar(label: 'Exterior', rating: 4.5),
          const SizedBox(height: 12),
          const _ConditionBar(label: 'Interior', rating: 4.8),
          const SizedBox(height: 12),
          const _ConditionBar(label: 'Mechanical', rating: 5.0),
          const SizedBox(height: 16),
          Text(
            'Seller Notes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Garage kept, never tracked. Minor rock chips on front bumper. All scheduled maintenance completed at Toyota dealership. Comes with both keys, all original documents, and window sticker.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
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

class _ConditionBar extends StatelessWidget {
  final String label;
  final double rating;

  const _ConditionBar({
    required this.label,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              '${rating.toStringAsFixed(1)}/5.0',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rating / 5.0,
            minHeight: 8,
            backgroundColor: isDark
                ? ColorConstants.borderDark
                : ColorConstants.backgroundSecondaryLight,
            valueColor: AlwaysStoppedAnimation(
              rating >= 4.5 ? ColorConstants.success : ColorConstants.primary,
            ),
          ),
        ),
      ],
    );
  }
}
