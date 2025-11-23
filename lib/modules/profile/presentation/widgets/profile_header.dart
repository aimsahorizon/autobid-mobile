import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../app/core/constants/color_constants.dart';

class ProfileHeader extends StatelessWidget {
  final String coverPhotoUrl;
  final String profilePhotoUrl;
  final VoidCallback? onCoverPhotoTap;
  final VoidCallback? onProfilePhotoTap;
  final bool isEditable;

  const ProfileHeader({
    super.key,
    required this.coverPhotoUrl,
    required this.profilePhotoUrl,
    this.onCoverPhotoTap,
    this.onProfilePhotoTap,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildCoverPhoto(),
        Positioned(
          bottom: -50,
          left: 24,
          child: _buildProfilePhoto(),
        ),
      ],
    );
  }

  Widget _buildCoverPhoto() {
    return GestureDetector(
      onTap: isEditable ? onCoverPhotoTap : null,
      child: Stack(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: ColorConstants.backgroundSecondaryLight,
            ),
            child: CachedNetworkImage(
              imageUrl: coverPhotoUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: ColorConstants.backgroundSecondaryLight,
              ),
              errorWidget: (context, url, error) => Container(
                color: ColorConstants.backgroundSecondaryLight,
                child: const Icon(
                  Icons.landscape_rounded,
                  size: 64,
                  color: ColorConstants.textSecondaryLight,
                ),
              ),
            ),
          ),
          if (isEditable)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return GestureDetector(
      onTap: isEditable ? onProfilePhotoTap : null,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: profilePhotoUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 100,
                  height: 100,
                  color: ColorConstants.backgroundSecondaryLight,
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 100,
                  height: 100,
                  color: ColorConstants.backgroundSecondaryLight,
                  child: const Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: ColorConstants.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ),
          if (isEditable)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: ColorConstants.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
