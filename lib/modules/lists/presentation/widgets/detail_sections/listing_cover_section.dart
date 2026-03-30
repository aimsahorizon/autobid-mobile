import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../domain/entities/listing_detail_entity.dart';

class ListingCoverSection extends StatelessWidget {
  final ListingDetailEntity listing;

  const ListingCoverSection({super.key, required this.listing});

  static bool _isAssetPath(String url) => url.startsWith('assets/');

  static Widget _buildSmartImage(String url, {BoxFit fit = BoxFit.cover}) {
    if (_isAssetPath(url)) {
      return Image.asset(
        url,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.directions_car, size: 64, color: Colors.grey),
          );
        },
      );
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.directions_car, size: 64, color: Colors.grey),
        );
      },
    );
  }

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
              ? _buildSmartImage(listing.coverPhotoUrl!, fit: BoxFit.cover)
              : const Center(
                  child: Icon(
                    Icons.directions_car,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
        ),
        // Gradient overlay
        Container(
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
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
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
