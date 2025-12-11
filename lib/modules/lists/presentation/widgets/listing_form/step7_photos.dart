import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../../../../app/core/services/car_detection_service.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';
import '../../../data/datasources/demo_listing_data.dart';
import '../../../data/datasources/sample_photo_guide_datasource.dart';
import 'demo_autofill_button.dart';

class Step7Photos extends StatefulWidget {
  final ListingDraftController controller;

  const Step7Photos({super.key, required this.controller});

  @override
  State<Step7Photos> createState() => _Step7PhotosState();
}

class _Step7PhotosState extends State<Step7Photos> {
  final _carDetectionService = CarDetectionService();
  bool _useAIDetection = true; // Toggle for AI vs Mock

  Future<void> _pickImage(BuildContext context, String category) async {
    print('DEBUG [Step7Photos]: ========================================');
    print('DEBUG [Step7Photos]: Attempting to pick image for category: $category');

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
      print('DEBUG [Step7Photos]: User cancelled image selection');
      return;
    }

    print('DEBUG [Step7Photos]: User selected: $action');

    if (!context.mounted) return;

    try {
      final picker = ImagePicker();
      XFile? pickedFile;

      if (action == 'camera') {
        print('DEBUG [Step7Photos]: Opening camera...');
        pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      } else {
        print('DEBUG [Step7Photos]: Opening gallery...');
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      }

      if (pickedFile == null) {
        print('DEBUG [Step7Photos]: No image selected');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected')),
          );
        }
        return;
      }

      print('DEBUG [Step7Photos]: Image picked - Path: ${pickedFile.path}');
      print('DEBUG [Step7Photos]: Image size: ${await pickedFile.length()} bytes');
      print('DEBUG [Step7Photos]: Uploading to controller...');

      final success = await widget.controller.uploadPhoto(category, pickedFile.path);

      print('DEBUG [Step7Photos]: Upload result: $success');

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Photo uploaded for $category'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to upload photo for $category'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('ERROR [Step7Photos]: Failed to pick/upload image: $e');
      print('STACK [Step7Photos]: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      print('DEBUG [Step7Photos]: ========================================');
    }
  }

  Future<void> _autofillDemoPhotos(BuildContext context) async {
    final currentDraft = widget.controller.currentDraft;
    if (currentDraft == null) return;

    final demoData = DemoListingData.getDemoDataForStep(7);
    final demoPhotoUrls = demoData['photoUrls'] as Map<String, List<String>>;

    // Update draft with demo photo URLs directly
    final updatedDraft = ListingDraftEntity(
      id: currentDraft.id,
      sellerId: currentDraft.sellerId,
      currentStep: currentDraft.currentStep,
      lastSaved: DateTime.now(),
      isComplete: currentDraft.isComplete,
      brand: currentDraft.brand,
      model: currentDraft.model,
      variant: currentDraft.variant,
      year: currentDraft.year,
      engineType: currentDraft.engineType,
      engineDisplacement: currentDraft.engineDisplacement,
      cylinderCount: currentDraft.cylinderCount,
      horsepower: currentDraft.horsepower,
      torque: currentDraft.torque,
      transmission: currentDraft.transmission,
      fuelType: currentDraft.fuelType,
      driveType: currentDraft.driveType,
      length: currentDraft.length,
      width: currentDraft.width,
      height: currentDraft.height,
      wheelbase: currentDraft.wheelbase,
      groundClearance: currentDraft.groundClearance,
      seatingCapacity: currentDraft.seatingCapacity,
      doorCount: currentDraft.doorCount,
      fuelTankCapacity: currentDraft.fuelTankCapacity,
      curbWeight: currentDraft.curbWeight,
      grossWeight: currentDraft.grossWeight,
      exteriorColor: currentDraft.exteriorColor,
      paintType: currentDraft.paintType,
      rimType: currentDraft.rimType,
      rimSize: currentDraft.rimSize,
      tireSize: currentDraft.tireSize,
      tireBrand: currentDraft.tireBrand,
      condition: currentDraft.condition,
      mileage: currentDraft.mileage,
      previousOwners: currentDraft.previousOwners,
      hasModifications: currentDraft.hasModifications,
      modificationsDetails: currentDraft.modificationsDetails,
      hasWarranty: currentDraft.hasWarranty,
      warrantyDetails: currentDraft.warrantyDetails,
      usageType: currentDraft.usageType,
      plateNumber: currentDraft.plateNumber,
      orcrStatus: currentDraft.orcrStatus,
      registrationStatus: currentDraft.registrationStatus,
      registrationExpiry: currentDraft.registrationExpiry,
      province: currentDraft.province,
      cityMunicipality: currentDraft.cityMunicipality,
      photoUrls: demoPhotoUrls, // Use demo photos
      description: currentDraft.description,
      knownIssues: currentDraft.knownIssues,
      features: currentDraft.features,
      startingPrice: currentDraft.startingPrice,
      reservePrice: currentDraft.reservePrice,
      auctionEndDate: currentDraft.auctionEndDate,
    );

    widget.controller.updateDraft(updatedDraft);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All demo photos added!')),
      );
    }
  }

  /// AI Detection: Auto-fill car details from uploaded photo
  Future<void> _detectCarAndAutoFill(BuildContext context) async {
    final photoUrls = widget.controller.currentDraft?.photoUrls;
    if (photoUrls == null || photoUrls.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload at least one photo first')),
        );
      }
      return;
    }

    // Get first uploaded photo for detection
    final firstPhoto = photoUrls.values.first.first;

    // Show confirmation dialog
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _useAIDetection ? Icons.psychology : Icons.auto_awesome,
              color: ColorConstants.primary,
            ),
            const SizedBox(width: 12),
            Text(_useAIDetection ? 'AI Detection' : 'Mock AI Detection'),
          ],
        ),
        content: Text(
          _useAIDetection
              ? 'Use AI to analyze your car photo and auto-fill basic details?\n\nNote: Real AI is not yet implemented. Using Mock AI for demo.'
              : 'Use Mock AI to generate randomized car details for demo purposes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Detect & Auto-Fill'),
          ),
        ],
      ),
    );

    if (shouldProceed != true || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Detecting car details...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Call AI detection service (Mock for now)
      final detectedData = await _carDetectionService.detectCarFromImage(firstPhoto);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      // Update draft with detected data
      final currentDraft = widget.controller.currentDraft!;
      final updatedDraft = ListingDraftEntity(
        id: currentDraft.id,
        sellerId: currentDraft.sellerId,
        currentStep: currentDraft.currentStep,
        lastSaved: DateTime.now(),
        isComplete: currentDraft.isComplete,
        // AI-detected fields
        brand: detectedData['brand'] as String?,
        model: detectedData['model'] as String?,
        variant: '${detectedData['bodyType']} ${detectedData['transmission']}',
        year: detectedData['year'] as int?,
        transmission: detectedData['transmission'] as String?,
        exteriorColor: detectedData['color'] as String?,
        tags: (detectedData['tags'] as List<dynamic>?)?.cast<String>(),
        // Preserve existing data
        engineType: currentDraft.engineType,
        engineDisplacement: currentDraft.engineDisplacement,
        cylinderCount: currentDraft.cylinderCount,
        horsepower: currentDraft.horsepower,
        torque: currentDraft.torque,
        fuelType: currentDraft.fuelType,
        driveType: currentDraft.driveType,
        length: currentDraft.length,
        width: currentDraft.width,
        height: currentDraft.height,
        wheelbase: currentDraft.wheelbase,
        groundClearance: currentDraft.groundClearance,
        seatingCapacity: currentDraft.seatingCapacity,
        doorCount: currentDraft.doorCount,
        fuelTankCapacity: currentDraft.fuelTankCapacity,
        curbWeight: currentDraft.curbWeight,
        grossWeight: currentDraft.grossWeight,
        paintType: currentDraft.paintType,
        rimType: currentDraft.rimType,
        rimSize: currentDraft.rimSize,
        tireSize: currentDraft.tireSize,
        tireBrand: currentDraft.tireBrand,
        condition: currentDraft.condition,
        mileage: currentDraft.mileage,
        previousOwners: currentDraft.previousOwners,
        hasModifications: currentDraft.hasModifications,
        modificationsDetails: currentDraft.modificationsDetails,
        hasWarranty: currentDraft.hasWarranty,
        warrantyDetails: currentDraft.warrantyDetails,
        usageType: currentDraft.usageType,
        plateNumber: currentDraft.plateNumber,
        orcrStatus: currentDraft.orcrStatus,
        registrationStatus: currentDraft.registrationStatus,
        registrationExpiry: currentDraft.registrationExpiry,
        province: currentDraft.province,
        cityMunicipality: currentDraft.cityMunicipality,
        photoUrls: currentDraft.photoUrls,
        description: currentDraft.description,
        knownIssues: currentDraft.knownIssues,
        features: currentDraft.features,
        startingPrice: currentDraft.startingPrice,
        reservePrice: currentDraft.reservePrice,
        auctionEndDate: currentDraft.auctionEndDate,
        biddingType: currentDraft.biddingType,
        bidIncrement: currentDraft.bidIncrement,
        minBidIncrement: currentDraft.minBidIncrement,
        depositAmount: currentDraft.depositAmount,
        enableIncrementalBidding: currentDraft.enableIncrementalBidding,
      );

      widget.controller.updateDraft(updatedDraft);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ AI detected: ${detectedData['brand']} ${detectedData['model']} (${detectedData['year']})',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to detect car: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAIToggleSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceLight.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _useAIDetection ? Icons.psychology : Icons.auto_awesome,
                color: ColorConstants.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Car Detection',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Switch(
                value: _useAIDetection,
                onChanged: (value) {
                  setState(() {
                    _useAIDetection = value;
                  });
                },
                activeTrackColor: ColorConstants.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _useAIDetection
                ? 'Real AI (Not yet implemented - uses Mock AI)'
                : 'Mock AI (Generates random demo data)',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _detectCarAndAutoFill(context),
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Detect Car & Auto-Fill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
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
              Image.network(
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
                child: const Center(
                  child: Text('No sample available'),
                ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final photoUrls = widget.controller.currentDraft?.photoUrls ?? {};
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
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 12),
                  DemoAutofillButton(onPressed: () => _autofillDemoPhotos(context)),
                  const SizedBox(height: 12),
                  _buildAIToggleSection(isDark),
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info_outline, size: 20),
                                  tooltip: 'View sample',
                                  onPressed: () => _showSamplePhoto(context, category),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.camera_alt),
                                  onPressed: () => _pickImage(context, category),
                                ),
                              ],
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
