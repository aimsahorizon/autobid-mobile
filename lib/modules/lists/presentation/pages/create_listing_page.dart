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

    final carOptions = {
      'car1': 'Toyota Vios',
      'car2': 'Mitsubishi Xpander',
      'car3': 'Honda CR-V',
    };

    showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Demo Car'),
        children: carOptions.entries
            .map(
              (e) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, e.key),
                child: Text('${e.key} — ${e.value}'),
              ),
            )
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

  Map<String, dynamic> _getCarDetails(String carFolder) {
    switch (carFolder) {
      case 'car1':
        return {
          'brand': 'Toyota',
          'model': 'Vios',
          'year': 2022,
          'variant': '1.5 G CVT',
          'bodyType': 'Sedan',
          'transmission': 'CVT',
          'mileage': 28000,
          'engineType': 'In-line 4-cylinder DOHC',
          'engineDisplacement': 1.5,
          'cylinderCount': 4,
          'horsepower': 106,
          'torque': 140,
          'fuelType': 'Gasoline',
          'driveType': 'FWD',
          'length': 4425.0,
          'width': 1730.0,
          'height': 1475.0,
          'wheelbase': 2550.0,
          'groundClearance': 133.0,
          'seatingCapacity': 5,
          'doorCount': 4,
          'fuelTankCapacity': 42.0,
          'curbWeight': 1080.0,
          'grossWeight': 1530.0,
          'exteriorColor': 'Freedom White',
          'paintType': 'Solid',
          'rimType': 'Alloy',
          'rimSize': '15',
          'tireSize': '185/60R15',
          'tireBrand': 'Bridgestone Ecopia',
          'condition': 'Used',
          'previousOwners': 1,
          'hasModifications': false,
          'modificationsDetails': '',
          'hasWarranty': true,
          'warrantyDetails': 'Toyota extended warranty until Dec 2026',
          'usageType': 'Personal',
          'knownIssues': 'Minor scratch on rear bumper.',
          'plateNumber': 'ABC 1234',
          'orcrStatus': 'Available',
          'registrationStatus': 'Current',
          'registrationExpiry': DateTime.now().add(const Duration(days: 240)),
          'province': 'Metro Manila',
          'cityMunicipality': 'Makati',
          'barangay': 'Poblacion',
          'description':
              'Well-maintained 2022 Toyota Vios 1.5 G CVT with low mileage. Single owner, always serviced at Toyota dealership. Casa-maintained with complete service records. Perfect daily driver with excellent fuel efficiency. Features include push-start, 7-inch touchscreen, and reverse camera.',
          'features': [
            'Push Start',
            'Reverse Camera',
            '7-inch Touchscreen',
            'LED Headlamps',
            'Cruise Control',
            'Keyless Entry',
            'Dual Airbags',
            'ABS with EBD',
          ],
          'startingPrice': 680000.0,
          'reservePrice': 750000.0,
          'bidIncrement': 5000.0,
          'minBidIncrement': 2000.0,
          'depositAmount': 20000.0,
          'biddingType': 'public',
          'enableIncrementalBidding': true,
          'autoLiveAfterApproval': true,
          'snipeGuardEnabled': true,
          'snipeGuardThresholdSeconds': 300,
          'snipeGuardExtendSeconds': 180,
          'allowsInstallment': true,
          'auctionEndDate': DateTime.now().add(const Duration(days: 7)),
          'tags': ['Sedan', 'Fuel Efficient', 'Low Mileage', 'Casa Maintained'],
        };
      case 'car2':
        return {
          'brand': 'Mitsubishi',
          'model': 'Xpander',
          'year': 2023,
          'variant': '1.5 GLS Sport AT',
          'bodyType': 'MPV',
          'transmission': 'Automatic',
          'mileage': 12000,
          'engineType': 'In-line 4-cylinder DOHC MIVEC',
          'engineDisplacement': 1.5,
          'cylinderCount': 4,
          'horsepower': 103,
          'torque': 141,
          'fuelType': 'Gasoline',
          'driveType': 'FWD',
          'length': 4595.0,
          'width': 1750.0,
          'height': 1700.0,
          'wheelbase': 2775.0,
          'groundClearance': 205.0,
          'seatingCapacity': 7,
          'doorCount': 4,
          'fuelTankCapacity': 45.0,
          'curbWeight': 1190.0,
          'grossWeight': 1750.0,
          'exteriorColor': 'Jet Black Mica',
          'paintType': 'Mica',
          'rimType': 'Alloy',
          'rimSize': '17',
          'tireSize': '205/55R17',
          'tireBrand': 'Yokohama BluEarth',
          'condition': 'Used',
          'previousOwners': 0,
          'hasModifications': true,
          'modificationsDetails':
              'Tinted windows (3M Crystalline) and dashcam installed',
          'hasWarranty': true,
          'warrantyDetails': 'Mitsubishi 5-year/100,000km warranty until 2028',
          'usageType': 'Personal',
          'knownIssues': 'None. Vehicle is in excellent condition.',
          'plateNumber': 'DEF 5678',
          'orcrStatus': 'Available',
          'registrationStatus': 'Current',
          'registrationExpiry': DateTime.now().add(const Duration(days: 365)),
          'province': 'Cebu',
          'cityMunicipality': 'Cebu City',
          'barangay': 'Lahug',
          'description':
              'Almost brand new 2023 Mitsubishi Xpander GLS Sport AT with only 12,000 km. First owner, always dealer-serviced at Mitsubishi Motors Cebu. This MPV offers spacious 7-seater comfort with SUV-like ground clearance. Features the Dynamic Shield front design, 8-inch display audio, and comprehensive safety suite.',
          'features': [
            'Dynamic Shield Design',
            '8-inch Display Audio',
            'Apple CarPlay',
            'Android Auto',
            'Rear AC Vents',
            'Hill Start Assist',
            'Stability Control',
            'ISOFIX Child Seat Anchors',
            '360° Camera',
          ],
          'startingPrice': 990000.0,
          'reservePrice': 1100000.0,
          'bidIncrement': 10000.0,
          'minBidIncrement': 5000.0,
          'depositAmount': 30000.0,
          'biddingType': 'private',
          'enableIncrementalBidding': false,
          'autoLiveAfterApproval': false,
          'snipeGuardEnabled': true,
          'snipeGuardThresholdSeconds': 600,
          'snipeGuardExtendSeconds': 300,
          'allowsInstallment': true,
          'auctionEndDate': DateTime.now().add(const Duration(days: 10)),
          'tags': ['MPV', '7-Seater', 'Family Car', 'Low Mileage'],
        };
      case 'car3':
      default:
        return {
          'brand': 'Honda',
          'model': 'CR-V',
          'year': 2021,
          'variant': '2.0 S CVT',
          'bodyType': 'SUV',
          'transmission': 'CVT',
          'mileage': 42000,
          'engineType': 'In-line 4-cylinder i-VTEC',
          'engineDisplacement': 2.0,
          'cylinderCount': 4,
          'horsepower': 152,
          'torque': 189,
          'fuelType': 'Gasoline',
          'driveType': 'FWD',
          'length': 4623.0,
          'width': 1855.0,
          'height': 1689.0,
          'wheelbase': 2660.0,
          'groundClearance': 198.0,
          'seatingCapacity': 5,
          'doorCount': 4,
          'fuelTankCapacity': 57.0,
          'curbWeight': 1467.0,
          'grossWeight': 2010.0,
          'exteriorColor': 'Modern Steel Metallic',
          'paintType': 'Metallic',
          'rimType': 'Alloy',
          'rimSize': '18',
          'tireSize': '235/60R18',
          'tireBrand': 'Continental ContiCross',
          'condition': 'Used',
          'previousOwners': 2,
          'hasModifications': true,
          'modificationsDetails':
              'Aftermarket roof rack and all-weather floor mats installed',
          'hasWarranty': false,
          'warrantyDetails': '',
          'usageType': 'Personal',
          'knownIssues': 'Stone chips on hood. AC re-gas done Jan 2026.',
          'plateNumber': 'GHI 9012',
          'orcrStatus': 'Available',
          'registrationStatus': 'Current',
          'registrationExpiry': DateTime.now().add(const Duration(days: 90)),
          'province': 'Davao del Sur',
          'cityMunicipality': 'Davao City',
          'barangay': 'Buhangin',
          'description':
              '2021 Honda CR-V 2.0 S CVT in excellent running condition. Two previous owners, complete service history at Honda Cars Davao. Spacious cabin, reliable Honda engineering, and outstanding ride comfort. Power tailgate, Honda Sensing suite, and premium interior. AC recently serviced. Ready for long drives.',
          'features': [
            'Honda Sensing',
            'Lane Keep Assist',
            'Collision Mitigation',
            'Adaptive Cruise Control',
            'Power Tailgate',
            'Dual Zone Auto AC',
            'Electric Parking Brake',
            'Walk-Away Auto Lock',
          ],
          'startingPrice': 1150000.0,
          'reservePrice': 1300000.0,
          'bidIncrement': 10000.0,
          'minBidIncrement': 5000.0,
          'depositAmount': 50000.0,
          'biddingType': 'public',
          'enableIncrementalBidding': true,
          'autoLiveAfterApproval': true,
          'snipeGuardEnabled': false,
          'snipeGuardThresholdSeconds': 300,
          'snipeGuardExtendSeconds': 300,
          'allowsInstallment': false,
          'auctionEndDate': DateTime.now().add(const Duration(days: 5)),
          'tags': ['SUV', 'Honda Sensing', 'Spacious', 'Reliable'],
        };
    }
  }

  Future<void> _applyDemoFill(String carFolder) async {
    if (widget.controller.currentDraft == null) return;

    final currentDraft = widget.controller.currentDraft!;
    final basePath = 'assets/autofill_cars/$carFolder';
    final car = _getCarDetails(carFolder);

    // Build photo URLs by probing assets
    final photoUrls = <String, List<String>>{};

    for (final category in PhotoCategories.all) {
      final key = PhotoCategories.toKey(category);
      final assetPath = await _probeAsset(basePath, key);
      photoUrls[key] = [assetPath ?? category];
    }

    // Cover photo: use front_view asset if available
    final frontAsset = await _probeAsset(basePath, 'front_view');
    final coverPhotoUrl = frontAsset ?? 'Front View';

    // Deed of sale
    final deedAsset = await _probeAsset(basePath, 'deed_of_sale');

    if (!mounted) return;

    final demoDraft = ListingDraftEntity(
      id: currentDraft.id,
      sellerId: currentDraft.sellerId,
      currentStep: 9,
      lastSaved: DateTime.now(),
      isComplete: false,

      // Step 2: Basic Info
      brand: car['brand'] as String,
      model: car['model'] as String,
      year: car['year'] as int,
      variant: car['variant'] as String,
      bodyType: car['bodyType'] as String,
      transmission: car['transmission'] as String,
      mileage: car['mileage'] as int,

      // Step 3: Mechanical
      engineType: car['engineType'] as String,
      engineDisplacement: car['engineDisplacement'] as double,
      cylinderCount: car['cylinderCount'] as int,
      horsepower: car['horsepower'] as int,
      torque: car['torque'] as int,
      fuelType: car['fuelType'] as String,
      driveType: car['driveType'] as String,

      // Step 4: Dimensions
      length: car['length'] as double,
      width: car['width'] as double,
      height: car['height'] as double,
      wheelbase: car['wheelbase'] as double,
      groundClearance: car['groundClearance'] as double,
      seatingCapacity: car['seatingCapacity'] as int,
      doorCount: car['doorCount'] as int,
      fuelTankCapacity: car['fuelTankCapacity'] as double,
      curbWeight: car['curbWeight'] as double,
      grossWeight: car['grossWeight'] as double,

      // Step 5: Exterior
      exteriorColor: car['exteriorColor'] as String,
      paintType: car['paintType'] as String,
      rimType: car['rimType'] as String,
      rimSize: car['rimSize'] as String,
      tireSize: car['tireSize'] as String,
      tireBrand: car['tireBrand'] as String,

      // Step 6: Condition
      condition: car['condition'] as String,
      previousOwners: car['previousOwners'] as int,
      hasModifications: car['hasModifications'] as bool,
      modificationsDetails: car['modificationsDetails'] as String,
      hasWarranty: car['hasWarranty'] as bool,
      warrantyDetails: car['warrantyDetails'] as String,
      usageType: car['usageType'] as String,
      knownIssues: car['knownIssues'] as String,

      // Step 7: Documentation
      plateNumber: car['plateNumber'] as String,
      isPlateValid: true,
      orcrStatus: car['orcrStatus'] as String,
      registrationStatus: car['registrationStatus'] as String,
      registrationExpiry: car['registrationExpiry'] as DateTime,
      province: car['province'] as String,
      cityMunicipality: car['cityMunicipality'] as String,
      barangay: car['barangay'] as String,
      deedOfSaleUrl: deedAsset,

      // Step 1: Photos
      photoUrls: photoUrls,
      coverPhotoUrl: coverPhotoUrl,

      // Step 8: Final Details & Bidding
      description: car['description'] as String,
      features: List<String>.from(car['features'] as List),
      startingPrice: car['startingPrice'] as double,
      reservePrice: car['reservePrice'] as double,
      auctionEndDate: car['auctionEndDate'] as DateTime,
      biddingType: car['biddingType'] as String,
      bidIncrement: car['bidIncrement'] as double,
      minBidIncrement: car['minBidIncrement'] as double,
      depositAmount: car['depositAmount'] as double,
      enableIncrementalBidding: car['enableIncrementalBidding'] as bool,
      autoLiveAfterApproval: car['autoLiveAfterApproval'] as bool,
      snipeGuardEnabled: car['snipeGuardEnabled'] as bool,
      snipeGuardThresholdSeconds: car['snipeGuardThresholdSeconds'] as int,
      snipeGuardExtendSeconds: car['snipeGuardExtendSeconds'] as int,
      allowsInstallment: car['allowsInstallment'] as bool,

      tags: List<String>.from(car['tags'] as List),
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
