import 'package:flutter/foundation.dart'; // Add for kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/services/car_detection_service.dart';
import '../controllers/listing_draft_controller.dart';
import '../../domain/entities/listing_draft_entity.dart';
import '../widgets/listing_form/step1_basic_info.dart';
import '../widgets/listing_form/step2_mechanical_spec.dart';
import '../widgets/listing_form/step3_dimensions.dart';
import '../widgets/listing_form/step4_exterior.dart';
import '../widgets/listing_form/step5_condition.dart';
import '../widgets/listing_form/step6_documentation.dart';
import '../widgets/listing_form/step7_photos.dart';
import '../widgets/listing_form/step8_final_details.dart';
import '../widgets/listing_form/step9_summary.dart';
import '../widgets/listing_form/listing_success_modal.dart';

class CreateListingPage extends StatefulWidget {
  final ListingDraftController controller;
  final String sellerId;
  final String? draftId;

  const CreateListingPage({
    super.key,
    required this.controller,
    required this.sellerId,
    this.draftId,
  });

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _carDetectionService = CarDetectionService();

  @override
  void initState() {
    super.initState();
    _initializeDraft();
  }

  Future<void> _initializeDraft() async {
    if (widget.draftId != null) {
      // Load existing draft for editing
      await widget.controller.loadDraft(widget.draftId!);
    } else {
      // Create new draft for new listing
      await widget.controller.createNewDraft(widget.sellerId);
    }
  }

  Future<bool> _onWillPop() async {
    if (widget.controller.currentDraft == null) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Draft?'),
        content: const Text(
          'Do you want to save your progress before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await widget.controller.saveDraft();
              if (mounted) navigator.pop(true);
            },
            child: const Text('Save & Exit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  void _showSuccessModal() {
    // Use addPostFrameCallback to ensure navigation happens after current frame
    // This prevents errors from controller state changes during navigation
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Use push instead of pushReplacement so we can handle the result
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ListingSuccessScreen(
            onCreateAnother: () {
              // Pop the success screen
              Navigator.pop(context, {'action': 'create_another'});
            },
            onViewListing: () {
              // Pop with navigation data
              Navigator.pop(context, {
                'success': true,
                'navigateTo': 'pending',
              });
            },
            onGoBack: () {
              // Simply pop back
              Navigator.pop(context, {'action': 'go_back'});
            },
          ),
        ),
      );

      if (!mounted) return;

      if (result != null && result is Map) {
        if (result['navigateTo'] == 'pending') {
          // Pass the result back to ListsPage
          Navigator.pop(context, result);
        } else if (result['action'] == 'create_another') {
          // Reset for new draft
          widget.controller.createNewDraft(widget.sellerId);
        } else if (result['action'] == 'go_back') {
          // Simply go back to listings
          Navigator.pop(context);
        }
      }
    });
  }

  /// AI Detection: Auto-fill car details from uploaded photo
  Future<void> _detectCarAndAutoFill(BuildContext context) async {
    final photoUrls = widget.controller.currentDraft?.photoUrls;
    if (photoUrls == null || photoUrls.isEmpty) return;

    // Get first uploaded photo for detection
    // Try to find a photo in any category
    String? firstPhoto;
    for (var urls in photoUrls.values) {
      if (urls.isNotEmpty) {
        firstPhoto = urls.first;
        break;
      }
    }

    if (firstPhoto == null) return;

    // Capture navigator before async gap
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Show loading
    if (mounted) {
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
    }

    try {
      // Call AI detection service
      final detectedData = await _carDetectionService.detectCarFromImageReal(
        firstPhoto,
      );

      if (!mounted) return;
      navigator.pop(); // Close loading

      // Update draft with detected data
      final specs = detectedData['specs'] as Map<String, dynamic>? ?? {};
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
        bodyType: detectedData['bodyType'] as String?, // Added bodyType
        year: detectedData['year'] as int?,
        transmission: specs['transmission'] as String?,
        exteriorColor: detectedData['color'] as String?,
        fuelType: specs['fuelType'] as String?,
        seatingCapacity: specs['seatingCapacity'] as int?,
        engineDisplacement: (specs['engineDisplacement'] as num?)?.toDouble(),
        doorCount: specs['doorCount'] as int?,
        driveType: specs['driveType'] as String?,
        features: (specs['features'] as List<dynamic>?)
            ?.cast<String>(), // Auto-fill features
        tags:
            (detectedData['tags'] as List<dynamic>?)?.cast<String>() ??
            currentDraft.tags,
        // Preserve existing data
        engineType: currentDraft.engineType,
        cylinderCount: currentDraft.cylinderCount,
        horsepower: currentDraft.horsepower,
        torque: currentDraft.torque,
        length: currentDraft.length,
        width: currentDraft.width,
        height: currentDraft.height,
        wheelbase: currentDraft.wheelbase,
        groundClearance: currentDraft.groundClearance,
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
        plateNumber:
            detectedData['plateNumber'] as String? ?? currentDraft.plateNumber,
        orcrStatus: currentDraft.orcrStatus,
        registrationStatus: currentDraft.registrationStatus,
        registrationExpiry: currentDraft.registrationExpiry,
        province: currentDraft.province,
        cityMunicipality: currentDraft.cityMunicipality,
        photoUrls: currentDraft.photoUrls,
        description: currentDraft.description,
        knownIssues: currentDraft.knownIssues,
        startingPrice: currentDraft.startingPrice,
        reservePrice: currentDraft.reservePrice,
        auctionEndDate: currentDraft.auctionEndDate,
        biddingType: currentDraft.biddingType,
        bidIncrement: currentDraft.bidIncrement,
        minBidIncrement: currentDraft.minBidIncrement,
        depositAmount: currentDraft.depositAmount,
        enableIncrementalBidding: currentDraft.enableIncrementalBidding,
        // tags: (detectedData['tags'] as List<dynamic>?)?.cast<String>() ?? currentDraft.tags, // Duplicate
        deedOfSaleUrl: currentDraft.deedOfSaleUrl,
      );

      widget.controller.updateDraft(updatedDraft);

      if (mounted) {
        final isRealAi = detectedData['is_real_ai'] == true;
        (messenger..clearSnackBars()).showSnackBar(
          SnackBar(
            content: Text(
              isRealAi
                  ? '✅ AI detected: ${detectedData['brand']} ${detectedData['model']} (${detectedData['year']})'
                  : '⚠️ AI Model missing. Using DEMO data for: ${detectedData['brand']} ${detectedData['model']}',
            ),
            backgroundColor: isRealAi ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (navigator.canPop()) {
          navigator.pop(); // Close loading if still open
        }
        (messenger..clearSnackBars()).showSnackBar(
          SnackBar(
            content: Text('Failed to detect car: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// DEMO MODE: Auto-fill fields for testing
  void _demoFillListing() {
    if (widget.controller.currentDraft == null) return;

    final carFolders = ['car1', 'car2', 'car3'];

    showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Demo Car'),
        children: carFolders
            .map((folder) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, folder),
                  child: Text(folder),
                ))
            .toList(),
      ),
    ).then((selected) {
      if (selected != null && mounted) {
        _applyDemoFill(selected);
      }
    });
  }

  Future<String?> _probeAsset(String basePath, String key) async {
    for (final ext in ['png', 'jpeg', 'jpg']) {
      try {
        await rootBundle.load('$basePath/$key.$ext');
        return '$basePath/$key.$ext';
      } catch (_) {}
    }
    return null;
  }

  Future<void> _applyDemoFill(String carFolder) async {
    if (widget.controller.currentDraft == null) return;

    final currentDraft = widget.controller.currentDraft!;
    final basePath = 'assets/autofill_cars/$carFolder';

    // Build photo URLs by probing assets
    final photoUrls = <String, List<String>>{};
    String? coverPhotoUrl;

    for (final category in PhotoCategories.all) {
      final key = PhotoCategories.toKey(category);
      final assetPath = await _probeAsset(basePath, key);
      photoUrls[key] = [assetPath ?? category]; // category display name as placeholder
    }

    // Cover photo: use front_view asset if available
    final frontAsset = await _probeAsset(basePath, 'front_view');
    coverPhotoUrl = frontAsset ?? 'Front View';

    // Deed of sale
    final deedAsset = await _probeAsset(basePath, 'deed_of_sale');

    if (!mounted) return;

    // Sample data for a 2020 Toyota GR Yaris
    final demoDraft = ListingDraftEntity(
      id: currentDraft.id,
      sellerId: currentDraft.sellerId,
      currentStep: 9,
      lastSaved: DateTime.now(),
      isComplete: false,

      // Step 2: Basic Info
      brand: 'Toyota',
      model: 'GR Yaris',
      year: 2020,
      variant: '1.6 Circuit Pack',
      transmission: 'Manual',
      mileage: 15000,

      // Step 3: Mechanical
      engineType: 'In-line 3-cylinder Turbo',
      engineDisplacement: 1.6,
      cylinderCount: 3,
      horsepower: 261,
      torque: 360,
      fuelType: 'Gasoline',
      driveType: 'AWD',

      // Step 4: Dimensions
      length: 3995,
      width: 1805,
      height: 1455,
      wheelbase: 2560,
      groundClearance: 124,
      seatingCapacity: 4,
      doorCount: 3,
      fuelTankCapacity: 50,
      curbWeight: 1280,
      grossWeight: 1600,

      // Step 5: Exterior
      exteriorColor: 'Platinum White Pearl',
      paintType: 'Pearl',
      rimType: 'Forged Alloy',
      rimSize: '18',
      tireSize: '225/40R18',
      tireBrand: 'Michelin Pilot Sport 4S',

      // Step 6: Condition
      condition: 'Used',
      previousOwners: 1,
      hasModifications: false,
      modificationsDetails: '',
      hasWarranty: true,
      warrantyDetails: 'Factory warranty until 2025',
      usageType: 'Personal',
      knownIssues: 'None. Pristine condition.',

      // Step 7: Documentation
      plateNumber: 'NGA 1234',
      orcrStatus: 'Available',
      registrationStatus: 'Current',
      registrationExpiry: DateTime.now().add(const Duration(days: 180)),
      province: 'Metro Manila',
      cityMunicipality: 'Quezon City',
      deedOfSaleUrl: deedAsset,

      // Step 1: Photos
      photoUrls: photoUrls,
      coverPhotoUrl: coverPhotoUrl,

      // Step 8: Final Details
      description:
          'The Toyota GR Yaris is a pure performance car, born from WRC. This unit is the Circuit Pack version with Torsen LSDs and tuned suspension. Mint condition, low mileage, always garage kept. Full service history available at Toyota dealer.',
      features: [
        'Apple CarPlay',
        'Android Auto',
        'Adaptive Cruise Control',
        'Lane Keep Assist',
        'JBL Sound System',
        'Carbon Fiber Roof',
      ],
      startingPrice: 3500000,
      reservePrice: 3800000,
      auctionEndDate: DateTime.now().add(const Duration(days: 7)),
      biddingType: 'public',
      bidIncrement: 10000,
      minBidIncrement: 5000,
      depositAmount: 50000,
      enableIncrementalBidding: true,

      tags: ['Sports Car', 'JDM', 'Low Mileage', 'Turbo'],
    );

    widget.controller.updateDraft(demoDraft);
    widget.controller.goToStep(9);

    (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
      const SnackBar(
        content: Text('⚡ Demo Mode: All fields auto-filled!'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  Future<void> _handleNextStep() async {
    // If Step 1 (Photos) and moving to Step 2
    if (widget.controller.currentStep == 1 && widget.controller.canGoNext) {
      final photoUrls = widget.controller.currentDraft?.photoUrls;
      // Check if there are ANY photos
      bool hasPhotos =
          photoUrls != null && photoUrls.values.any((list) => list.isNotEmpty);

      if (hasPhotos) {
        final shouldAutoFill = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.auto_awesome, color: ColorConstants.primary),
                const SizedBox(width: 12),
                const Text('Auto-fill with AI?'),
              ],
            ),
            content: const Text(
              'We can analyze your photos to auto-fill vehicle details like Brand, Model, and Year.\n\nWould you like to try this?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No, Manual Entry'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.psychology),
                label: const Text('Yes, Auto-fill'),
                style: FilledButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                ),
              ),
            ],
          ),
        );

        if (shouldAutoFill == true && mounted) {
          await _detectCarAndAutoFill(context);
        }
      }
    }

    // Proceed to next step
    widget.controller.goToNextStep();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create New Listing'),
          actions: [
            if (kDebugMode)
              IconButton(
                onPressed: _demoFillListing,
                icon: const Icon(Icons.bolt),
                tooltip: 'Demo Fill',
                color: Colors.purple,
              ),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                if (widget.controller.isSaving) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return IconButton(
                  onPressed: widget.controller.saveDraft,
                  icon: const Icon(Icons.save_outlined),
                  tooltip: 'Save Draft',
                );
              },
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            if (widget.controller.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing listing...'),
                  ],
                ),
              );
            }

            final draft = widget.controller.currentDraft;

            // If submission was successful, show loading while waiting for navigation/modal
            if (widget.controller.isSubmissionSuccess) {
              return const Center(child: CircularProgressIndicator());
            }

            if (draft == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Unable to start listing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.controller.errorMessage ??
                            'Please check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _initializeDraft();
                        },
                        icon: Icon(Icons.refresh),
                        label: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                _buildStepIndicator(isDark),
                Expanded(child: _buildStepContent()),
                _buildNavigationBar(isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? ColorConstants.surfaceLight
                : ColorConstants.backgroundSecondaryLight,
          ),
        ),
      ),
      child: Row(
        children: List.generate(9, (index) {
          final step = index + 1;
          // Step 9 should not show as complete unless all previous steps are done
          final isCompleted = step == 9
              ? widget.controller.currentDraft!.completionPercentage >= 100
              : widget.controller.currentDraft!.isStepComplete(step);
          final isCurrent = step == widget.controller.currentStep;

          return Expanded(
            child: GestureDetector(
              onTap: () => widget.controller.goToStep(step),
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.green
                          : (isCurrent
                                ? ColorConstants.primary
                                : (isDark
                                      ? ColorConstants.surfaceLight
                                      : ColorConstants
                                            .backgroundSecondaryLight)),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : Text(
                              '$step',
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white
                                    : (isDark
                                          ? ColorConstants.textSecondaryDark
                                          : ColorConstants.textSecondaryLight),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isCurrent)
                    Container(
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        color: ColorConstants.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (widget.controller.currentStep) {
      case 1:
        // NEW ORDER: Photos first with AI detection
        return Step7Photos(controller: widget.controller);
      case 2:
        // AI-prefilled from photos
        return Step1BasicInfo(controller: widget.controller);
      case 3:
        return Step2MechanicalSpec(controller: widget.controller);
      case 4:
        return Step3Dimensions(controller: widget.controller);
      case 5:
        return Step4Exterior(controller: widget.controller);
      case 6:
        return Step5Condition(controller: widget.controller);
      case 7:
        return Step6Documentation(controller: widget.controller);
      case 8:
        return Step8FinalDetails(controller: widget.controller);
      case 9:
        return Step9Summary(
          controller: widget.controller,
          onSubmitSuccess: _showSuccessModal,
        );
      default:
        return const Center(child: Text('Invalid step'));
    }
  }

  Widget _buildNavigationBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? ColorConstants.surfaceLight
                : ColorConstants.backgroundSecondaryLight,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.controller.canGoPrevious)
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.controller.goToPreviousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Previous'),
                ),
              ),
            if (widget.controller.canGoPrevious && widget.controller.canGoNext)
              const SizedBox(width: 12),
            if (widget.controller.canGoNext)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  // Use _handleNextStep here
                  onPressed: _handleNextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
