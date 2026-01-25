import 'dart:io';
import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';

class ImagePickerCard extends StatelessWidget {
  final String label;
  final File? imageFile;
  final VoidCallback onTap;
  final String? hint;
  final IconData icon;

  const ImagePickerCard({
    super.key,
    required this.label,
    required this.imageFile,
    required this.onTap,
    this.hint,
    this.icon = Icons.camera_alt_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
        ],
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: isDark
                  ? ColorConstants.backgroundSecondaryDark
                  : ColorConstants.backgroundSecondaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? ColorConstants.borderDark
                    : ColorConstants.borderLight,
              ),
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.file(
                          imageFile!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: ColorConstants.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: ColorConstants.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: ColorConstants.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to upload',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ColorConstants.primary,
                          fontWeight: FontWeight.w500,
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
