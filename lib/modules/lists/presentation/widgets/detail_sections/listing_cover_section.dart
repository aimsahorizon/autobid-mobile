import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../../domain/entities/listing_detail_entity.dart';

class ListingCoverSection extends StatelessWidget {
  final ListingDetailEntity listing;

  const ListingCoverSection({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Cover photo
        Container(
          height: 250,
          width: double.infinity,
          color: isDark ? ColorConstants.surfaceDark : Colors.grey[200],
          child: listing.coverPhotoUrl != null
              ? Image.network(
                  listing.coverPhotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.directions_car, size: 64, color: Colors.grey),
                    );
                  },
                )
              : const Center(
                  child: Icon(Icons.directions_car, size: 64, color: Colors.grey),
                ),
        ),
        // Gradient overlay
        Container(
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        // Car name at bottom
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.carName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${listing.year ?? 'N/A'} • ${listing.mileage != null ? '${listing.mileage!.toStringAsFixed(0)} km' : 'N/A'}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
