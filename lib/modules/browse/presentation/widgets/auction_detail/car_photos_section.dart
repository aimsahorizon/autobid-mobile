import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../domain/entities/auction_detail_entity.dart';

class CarPhotosSection extends StatefulWidget {
  final CarPhotosEntity photos;

  const CarPhotosSection({
    super.key,
    required this.photos,
  });

  @override
  State<CarPhotosSection> createState() => _CarPhotosSectionState();
}

class _CarPhotosSectionState extends State<CarPhotosSection> {
  String _selectedCategory = 'Exterior';

  final List<String> _categories = [
    'Exterior',
    'Interior',
    'Engine',
    'Details',
    'Documents',
  ];

  List<String> get _currentPhotos {
    return widget.photos.getByCategory(_selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photos',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryChips(isDark),
          const SizedBox(height: 16),
          _buildPhotoGrid(),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          final photoCount = widget.photos.getByCategory(category).length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text('$category ($photoCount)'),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: ColorConstants.primary.withValues(alpha: 0.2),
              checkmarkColor: ColorConstants.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? ColorConstants.primary
                    : (isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? ColorConstants.primary
                    : (isDark
                        ? ColorConstants.borderDark
                        : ColorConstants.borderLight),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    if (_currentPhotos.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: Text(
          'No photos available',
          style: TextStyle(color: ColorConstants.textSecondaryLight),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _currentPhotos.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showFullScreenImage(context, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: _currentPhotos[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: ColorConstants.backgroundSecondaryLight,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: ColorConstants.backgroundSecondaryLight,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(
          photos: _currentPhotos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _FullScreenGallery extends StatelessWidget {
  final List<String> photos;
  final int initialIndex;

  const _FullScreenGallery({
    required this.photos,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: photos[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
