import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';

class AuctionCoverPhoto extends StatelessWidget {
  final String imageUrl;
  final String carName;
  final String status;

  const AuctionCoverPhoto({
    super.key,
    required this.imageUrl,
    required this.carName,
    required this.status,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'active':
        return ColorConstants.success;
      case 'ended':
        return ColorConstants.error;
      case 'sold':
        return ColorConstants.primary;
      default:
        return ColorConstants.textSecondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: ColorConstants.backgroundSecondaryLight,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: ColorConstants.backgroundSecondaryLight,
              child: const Icon(Icons.directions_car, size: 64),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    carName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
