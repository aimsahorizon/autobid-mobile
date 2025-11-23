import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';

class Step7Photos extends StatelessWidget {
  final ListingDraftController controller;

  const Step7Photos({super.key, required this.controller});

  Future<void> _pickImage(BuildContext context, String category) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (action != null && context.mounted) {
      final success = await controller.uploadPhoto(category, 'mock_$action');
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo uploaded for $category')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final photoUrls = controller.currentDraft?.photoUrls ?? {};
        final uploadedCount = photoUrls.values.fold<int>(
          0,
          (sum, urls) => sum + urls.length,
        );

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark
                  ? ColorConstants.surfaceDark
                  : ColorConstants.backgroundSecondaryLight,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Step 7: Photos',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload photos for all 56 required categories',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? ColorConstants.textSecondaryDark
                                : ColorConstants.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: uploadedCount >= 56
                          ? Colors.green
                          : ColorConstants.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$uploadedCount/56',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: uploadedCount >= 56
                            ? Colors.white
                            : ColorConstants.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: PhotoCategories.categoryGroups.length,
                itemBuilder: (context, groupIndex) {
                  final groupName = PhotoCategories.categoryGroups.keys.elementAt(groupIndex);
                  final categoryCount = PhotoCategories.categoryGroups[groupName]!;

                  final groupCategories = _getCategoriesForGroup(groupName, categoryCount);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          groupName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...groupCategories.map((category) {
                        final hasPhoto = photoUrls[category]?.isNotEmpty ?? false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? ColorConstants.surfaceLight
                                  : ColorConstants.backgroundSecondaryLight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              hasPhoto ? Icons.check_circle : Icons.add_a_photo,
                              color: hasPhoto ? Colors.green : ColorConstants.primary,
                            ),
                            title: Text(category),
                            subtitle: hasPhoto
                                ? Text(
                                    '${photoUrls[category]!.length} photo(s)',
                                    style: const TextStyle(color: Colors.green),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: () => _pickImage(context, category),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> _getCategoriesForGroup(String groupName, int count) {
    final allCategories = PhotoCategories.all;
    int startIndex = 0;

    for (final group in PhotoCategories.categoryGroups.keys) {
      if (group == groupName) break;
      startIndex += PhotoCategories.categoryGroups[group]!;
    }

    return allCategories.sublist(startIndex, startIndex + count);
  }
}
