import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/utils/image_helper.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';
import '../../../data/datasources/sample_photo_guide_datasource.dart';

class Step7Photos extends StatefulWidget {
  final ListingDraftController controller;

  const Step7Photos({super.key, required this.controller});

  @override
  State<Step7Photos> createState() => _Step7PhotosState();
}

class _Step7PhotosState extends State<Step7Photos>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: PhotoCategories.categoryGroups.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _setFeaturedPhoto(BuildContext context, String photoUrl) async {
    await widget.controller.setCoverPhoto(photoUrl);
    if (!context.mounted) return;
    (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
      const SnackBar(
        content: Text('Featured photo updated'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, String category) async {
    debugPrint('DEBUG [Step7Photos]: ========================================');
    debugPrint(
      'DEBUG [Step7Photos]: Attempting to pick image for category: $category',
    );

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

    if (action == null) {
      debugPrint('DEBUG [Step7Photos]: User cancelled image selection');
      return;
    }

    debugPrint('DEBUG [Step7Photos]: User selected: $action');

    if (!context.mounted) return;

    try {
      final picker = ImagePicker();
      XFile? pickedFile;

      if (action == 'camera') {
        debugPrint('DEBUG [Step7Photos]: Opening camera...');
        pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      } else {
        debugPrint('DEBUG [Step7Photos]: Opening gallery...');
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      }

      if (pickedFile == null) {
        debugPrint('DEBUG [Step7Photos]: No image selected');
        if (context.mounted) {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            const SnackBar(content: Text('No image selected')),
          );
        }
        return;
      }

      // Validate format (only images accepted here)
      final ext = pickedFile.path.split('.').last.toLowerCase();
      const allowedExts = ['jpg', 'jpeg', 'png', 'heic', 'heif', 'webp'];
      if (!allowedExts.contains(ext)) {
        debugPrint('DEBUG [Step7Photos]: Unsupported format: $ext');
        if (context.mounted) {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            SnackBar(
              content: Text(
                'Unsupported format (.$ext). Please use JPG, PNG, or HEIC.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Crop the image (fallback to uncropped if cropper fails)
      File imageFile = File(pickedFile.path);
      try {
        final croppedFile = await ImageHelper.cropImage(
          file: imageFile,
          title: 'Crop $category',
        );

        if (croppedFile == null) {
          debugPrint('DEBUG [Step7Photos]: Image cropping cancelled');
          return;
        }
        imageFile = croppedFile;
      } catch (cropError) {
        debugPrint(
          'DEBUG [Step7Photos]: Cropper failed ($cropError), using original image',
        );
        // Continue with uncropped image
      }

      if (!context.mounted) return;

      debugPrint('DEBUG [Step7Photos]: Image ready - Path: ${imageFile.path}');
      debugPrint(
        'DEBUG [Step7Photos]: Image size: ${await imageFile.length()} bytes',
      );
      debugPrint('DEBUG [Step7Photos]: Uploading to controller...');

      final categoryKey = PhotoCategories.toKey(category);

      // Clear existing photo for this category if any (Enforce 1 photo per view)
      final currentPhotos = widget.controller.currentDraft?.photoUrls ?? {};
      if (currentPhotos.containsKey(categoryKey) &&
          currentPhotos[categoryKey]!.isNotEmpty) {
        final updatedPhotoUrls = Map<String, List<String>>.from(currentPhotos);
        final removedUrls = updatedPhotoUrls[categoryKey] ?? [];
        updatedPhotoUrls.remove(categoryKey);

        // Reset cover photo if it was in the removed category
        var updatedCover = widget.controller.currentDraft!.coverPhotoUrl;
        if (updatedCover != null && removedUrls.contains(updatedCover)) {
          // Find another cover from remaining photos
          updatedCover = null;
          for (final urls in updatedPhotoUrls.values) {
            if (urls.isNotEmpty) {
              updatedCover = urls.first;
              break;
            }
          }
        }

        widget.controller.updateDraft(
          widget.controller.currentDraft!.copyWith(
            photoUrls: updatedPhotoUrls,
            coverPhotoUrl: updatedCover,
            lastSaved: DateTime.now(),
          ),
        );
      }

      final success = await widget.controller.uploadPhoto(
        category, // Pass display name, controller converts it
        imageFile.path,
      );

      debugPrint('DEBUG [Step7Photos]: Upload result: $success');

      if (context.mounted) {
        if (success) {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            SnackBar(
              content: Text('✅ Photo uploaded for $category'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to upload photo for $category'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR [Step7Photos]: Failed to pick/upload image: $e');
      debugPrint('STACK [Step7Photos]: $stackTrace');

      if (context.mounted) {
        (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      debugPrint(
        'DEBUG [Step7Photos]: ========================================',
      );
    }
  }

  Future<void> _showSamplePhoto(BuildContext context, String category) async {
    final datasource = SamplePhotoGuideDataSource();
    final sampleUrl = await datasource.getSamplePhoto(category);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: ColorConstants.primary,
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sample Guide: $category',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (sampleUrl != null)
              sampleUrl.startsWith('assets/')
                  ? Image.asset(
                      sampleUrl,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 64),
                          ),
                        );
                      },
                    )
                  : Image.network(
                      sampleUrl,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 64),
                          ),
                        );
                      },
                    )
            else
              Container(
                height: 300,
                color: Colors.grey[300],
                child: const Center(child: Text('No sample available')),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'This is a reference photo showing the ideal angle and framing for "$category".',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show full screen image
  void _showFullImage(BuildContext context, String imageUrl) {
    if (!context.mounted) return;

    final isUrl = imageUrl.startsWith('http');
    final isAsset = imageUrl.startsWith('assets/');
    final isFile = !isUrl && !isAsset && imageUrl.contains('/');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Full screen image with zoom
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: isUrl
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                    )
                  : isAsset
                  ? Image.asset(imageUrl, fit: BoxFit.contain)
                  : isFile
                  ? Image.file(File(imageUrl), fit: BoxFit.contain)
                  : Center(
                      child: Text(
                        imageUrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build photo preview with delete button
  Widget _buildPhotoPreview(
    BuildContext context,
    String photoUrl,
    String category,
    int index,
    bool isDark,
    bool isFeatured,
  ) {
    // Check if the URL is valid (has http/https scheme)
    final isValidUrl =
        photoUrl.startsWith('http://') || photoUrl.startsWith('https://');
    final isAsset = photoUrl.startsWith('assets/');
    final isFilePath = !isValidUrl && !isAsset && photoUrl.contains('/');

    return GestureDetector(
      onTap: () => _showFullImage(context, photoUrl),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? ColorConstants.surfaceLight.withValues(alpha: 0.3)
                : Colors.grey.shade300,
          ),
        ),
        child: Stack(
          children: [
            // Photo image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isValidUrl
                  ? Image.network(
                      photoUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 100,
                          height: 100,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : isAsset
                  ? Image.asset(
                      photoUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : isFilePath
                  ? Image.file(
                      File(photoUrl),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            photoUrl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            // Delete button overlay
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _deletePhoto(context, category, index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                onTap: () => _setFeaturedPhoto(context, photoUrl),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isFeatured
                        ? Colors.amber.withValues(alpha: 0.95)
                        : Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFeatured ? Icons.star : Icons.star_border,
                    color: isFeatured ? Colors.white : Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            // Photo number badge
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Delete a photo from a category
  Future<void> _deletePhoto(
    BuildContext context,
    String categoryDisplayName,
    int index,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: Text(
          'Are you sure you want to delete this photo from "$categoryDisplayName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final currentDraft = widget.controller.currentDraft;
    if (currentDraft == null) return;

    final categoryKey = PhotoCategories.toKey(categoryDisplayName);

    final updatedPhotoUrls = Map<String, List<String>>.from(
      currentDraft.photoUrls ?? {},
    );

    final removingPhotoUrl = updatedPhotoUrls[categoryKey]?[index];
    var updatedCoverPhotoUrl = currentDraft.coverPhotoUrl;

    if (updatedPhotoUrls[categoryKey] != null) {
      updatedPhotoUrls[categoryKey] = List<String>.from(
        updatedPhotoUrls[categoryKey]!,
      )..removeAt(index);

      // Remove category key if empty
      if (updatedPhotoUrls[categoryKey]!.isEmpty) {
        updatedPhotoUrls.remove(categoryKey);
      }

      final isRemovingFeatured =
          removingPhotoUrl != null &&
          removingPhotoUrl == currentDraft.coverPhotoUrl;
      if (isRemovingFeatured) {
        String? replacement;
        for (final urls in updatedPhotoUrls.values) {
          if (urls.isNotEmpty) {
            replacement = urls.first;
            break;
          }
        }
        updatedCoverPhotoUrl = replacement;
      }

      // Update draft with new photo URLs
      final updatedDraft = currentDraft.copyWith(
        lastSaved: DateTime.now(),
        photoUrls: updatedPhotoUrls,
        coverPhotoUrl: updatedCoverPhotoUrl,
      );

      widget.controller.updateDraft(updatedDraft);

      if (context.mounted) {
        (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final photoUrls = widget.controller.currentDraft?.photoUrls ?? {};
        final selectedCoverPhotoUrl =
            widget.controller.currentDraft?.coverPhotoUrl;
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Step 1: Upload Photos',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload car photos - AI will auto-detect details',
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                color: isDark
                    ? ColorConstants.backgroundDark
                    : ColorConstants.backgroundSecondaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.all(4),
                indicator: BoxDecoration(
                  color: isDark ? ColorConstants.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: ColorConstants.primary,
                unselectedLabelColor: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: PhotoCategories.categoryGroups.keys
                    .map((g) => Tab(text: g))
                    .toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: PhotoCategories.categoryGroups.keys.map((groupName) {
                  final categoryCount =
                      PhotoCategories.categoryGroups[groupName]!;
                  final groupCategories = _getCategoriesForGroup(
                    groupName,
                    categoryCount,
                  );
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: groupCategories.map((categoryDisplayName) {
                      final categoryKey = PhotoCategories.toKey(
                        categoryDisplayName,
                      );
                      final categoryPhotos = photoUrls[categoryKey] ?? [];
                      final hasPhoto = categoryPhotos.isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? ColorConstants.surfaceLight.withValues(
                                  alpha: 0.1,
                                )
                              : Colors.white,
                          border: Border.all(
                            color: hasPhoto
                                ? Colors.green.withValues(alpha: 0.3)
                                : (isDark
                                      ? ColorConstants.surfaceLight
                                      : ColorConstants
                                            .backgroundSecondaryLight),
                            width: hasPhoto ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              children: [
                                Icon(
                                  hasPhoto
                                      ? Icons.check_circle
                                      : Icons.add_a_photo,
                                  color: hasPhoto
                                      ? Colors.green
                                      : ColorConstants.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        categoryDisplayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (hasPhoto)
                                        Text(
                                          '${categoryPhotos.length} photo${categoryPhotos.length > 1 ? 's' : ''}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.info_outline,
                                    size: 20,
                                  ),
                                  tooltip: 'View sample',
                                  onPressed: () => _showSamplePhoto(
                                    context,
                                    categoryDisplayName,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _pickImage(context, categoryDisplayName),
                                  icon: Icon(
                                    hasPhoto
                                        ? Icons.swap_horiz
                                        : Icons.add_photo_alternate,
                                    size: 18,
                                  ),
                                  label: Text(hasPhoto ? 'Replace' : 'Upload'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasPhoto
                                        ? Colors.orange
                                        : ColorConstants.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Photo previews
                            if (hasPhoto) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: categoryPhotos.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final photoUrl = entry.value;
                                  return _buildPhotoPreview(
                                    context,
                                    photoUrl,
                                    categoryDisplayName,
                                    index,
                                    isDark,
                                    photoUrl == selectedCoverPhotoUrl,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                photoUrlHintText(
                                  categoryPhotos,
                                  selectedCoverPhotoUrl,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? ColorConstants.textSecondaryDark
                                      : ColorConstants.textSecondaryLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
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

  String photoUrlHintText(
    List<String> categoryPhotos,
    String? selectedCoverPhotoUrl,
  ) {
    if (categoryPhotos.isEmpty) {
      return 'Upload a photo to continue.';
    }
    if (selectedCoverPhotoUrl != null &&
        categoryPhotos.contains(selectedCoverPhotoUrl)) {
      return 'Starred photo is used as listing cover.';
    }
    return 'Tap a star to choose the listing cover photo.';
  }
}
