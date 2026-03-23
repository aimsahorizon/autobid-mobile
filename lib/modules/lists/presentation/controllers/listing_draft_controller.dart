import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/listing_draft_entity.dart';
import '../../data/models/listing_draft_model.dart';
import '../../domain/usecases/draft_management_usecases.dart';
import '../../domain/usecases/submission_usecases.dart';
import '../../domain/usecases/media_management_usecases.dart';
import '../../domain/usecases/get_vehicle_data_usecases.dart';
import '../../domain/entities/vehicle_entities.dart';
import '../../../profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:autobid_mobile/core/services/car_api_service.dart';

/// Controller for managing listing draft creation and editing
/// Handles 9-step form flow with auto-save and validation
class ListingDraftController extends ChangeNotifier {
  static const String _localDraftStoragePrefix = 'local_listing_draft_';

  final GetSellerDraftsUseCase _getSellerDraftsUseCase;
  final GetDraftUseCase _getDraftUseCase;
  final CreateDraftUseCase _createDraftUseCase;
  final SaveDraftUseCase _saveDraftUseCase;
  final MarkDraftCompleteUseCase _markDraftCompleteUseCase;
  final DeleteDraftUseCase _deleteDraftUseCase;
  final SubmitListingUseCase _submitListingUseCase;
  final UploadListingPhotoUseCase _uploadListingPhotoUseCase;
  final UploadDeedOfSaleUseCase _uploadDeedOfSaleUseCase;
  final DeleteDeedOfSaleUseCase _deleteDeedOfSaleUseCase;
  final GetUserProfileUseCase _getUserProfileUseCase;

  // Vehicle Data Use Cases
  final GetVehicleBrandsUseCase _getVehicleBrandsUseCase;
  final GetVehicleModelsUseCase _getVehicleModelsUseCase;
  final GetVehicleVariantsUseCase _getVehicleVariantsUseCase;

  // Car Search Service
  final CarApiService _carApiService;

  ListingDraftController({
    required GetSellerDraftsUseCase getSellerDraftsUseCase,
    required GetDraftUseCase getDraftUseCase,
    required CreateDraftUseCase createDraftUseCase,
    required SaveDraftUseCase saveDraftUseCase,
    required MarkDraftCompleteUseCase markDraftCompleteUseCase,
    required DeleteDraftUseCase deleteDraftUseCase,
    required SubmitListingUseCase submitListingUseCase,
    required UploadListingPhotoUseCase uploadListingPhotoUseCase,
    required UploadDeedOfSaleUseCase uploadDeedOfSaleUseCase,
    required DeleteDeedOfSaleUseCase deleteDeedOfSaleUseCase,
    required GetUserProfileUseCase getUserProfileUseCase,
    required GetVehicleBrandsUseCase getVehicleBrandsUseCase,
    required GetVehicleModelsUseCase getVehicleModelsUseCase,
    required GetVehicleVariantsUseCase getVehicleVariantsUseCase,
    required CarApiService carApiService,
  }) : _getSellerDraftsUseCase = getSellerDraftsUseCase,
       _getDraftUseCase = getDraftUseCase,
       _createDraftUseCase = createDraftUseCase,
       _saveDraftUseCase = saveDraftUseCase,
       _markDraftCompleteUseCase = markDraftCompleteUseCase,
       _deleteDraftUseCase = deleteDraftUseCase,
       _submitListingUseCase = submitListingUseCase,
       _uploadListingPhotoUseCase = uploadListingPhotoUseCase,
       _uploadDeedOfSaleUseCase = uploadDeedOfSaleUseCase,
       _deleteDeedOfSaleUseCase = deleteDeedOfSaleUseCase,
       _getUserProfileUseCase = getUserProfileUseCase,
       _getVehicleBrandsUseCase = getVehicleBrandsUseCase,
       _getVehicleModelsUseCase = getVehicleModelsUseCase,
       _getVehicleVariantsUseCase = getVehicleVariantsUseCase,
       _carApiService = carApiService;

  // State
  ListingDraftEntity? _currentDraft;
  List<ListingDraftEntity> _drafts = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSubmitting = false;
  bool _isSubmissionSuccess = false;
  String? _errorMessage;

  // Vehicle Data State
  List<VehicleBrand> _brands = [];
  List<VehicleModel> _models = [];
  List<VehicleVariant> _variants = [];
  bool _isLoadingVehicleData = false;

  // Car Search State
  List<CarSearchResult> _carSearchResults = [];
  bool _isSearchingCars = false;

  // Getters
  ListingDraftEntity? get currentDraft => _currentDraft;
  List<ListingDraftEntity> get drafts => _drafts;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSubmitting => _isSubmitting;
  bool get isSubmissionSuccess => _isSubmissionSuccess;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  List<VehicleBrand> get brands => _brands;
  List<VehicleModel> get models => _models;
  List<VehicleVariant> get variants => _variants;
  bool get isLoadingVehicleData => _isLoadingVehicleData;

  List<CarSearchResult> get carSearchResults => _carSearchResults;
  bool get isSearchingCars => _isSearchingCars;

  int get currentStep => _currentDraft?.currentStep ?? 1;
  bool get canGoNext => _currentDraft != null && currentStep < 9;
  bool get canGoPrevious => _currentDraft != null && currentStep > 1;
  bool get canSubmit => (_currentDraft?.completionPercentage ?? 0) >= 100;

  // ... (rest of methods) ...

  /// Load vehicle brands
  Future<void> loadBrands() async {
    if (_brands.isNotEmpty) return; // Cache check

    _isLoadingVehicleData = true;
    notifyListeners();

    final result = await _getVehicleBrandsUseCase.call();
    result.fold(
      (failure) => debugPrint(
        'Error loading brands: ${failure.message}',
      ), // Non-blocking
      (brands) => _brands = brands,
    );

    _isLoadingVehicleData = false;
    notifyListeners();
  }

  /// Load models for a brand
  Future<void> loadModels(String brandName) async {
    _models = [];
    _variants = []; // Reset variants too

    if (brandName.isEmpty) {
      notifyListeners();
      return;
    }

    // Find brand ID from name (since UI stores name)
    // If brand list is empty, try to load it first? No, assume loaded.
    // If name not found, maybe custom entry?

    final brand = _brands.where((b) => b.name == brandName).firstOrNull;
    if (brand == null) return;

    _isLoadingVehicleData = true;
    notifyListeners();

    final result = await _getVehicleModelsUseCase.call(brand.id);
    result.fold(
      (failure) => debugPrint('Error loading models: ${failure.message}'),
      (models) => _models = models,
    );

    _isLoadingVehicleData = false;
    notifyListeners();
  }

  /// Load variants for a model
  Future<void> loadVariants(String modelName) async {
    _variants = [];

    if (modelName.isEmpty) {
      notifyListeners();
      return;
    }

    final model = _models.where((m) => m.name == modelName).firstOrNull;
    if (model == null) return;

    _isLoadingVehicleData = true;
    notifyListeners();

    final result = await _getVehicleVariantsUseCase.call(model.id);
    result.fold(
      (failure) => debugPrint('Error loading variants: ${failure.message}'),
      (variants) => _variants = variants,
    );

    _isLoadingVehicleData = false;
    notifyListeners();
  }

  /// Search cars by query string for autofill
  Future<void> searchCars(String query) async {
    if (query.trim().length < 2) {
      _carSearchResults = [];
      notifyListeners();
      return;
    }

    _isSearchingCars = true;
    notifyListeners();

    _carSearchResults = await _carApiService.searchCars(query);

    _isSearchingCars = false;
    notifyListeners();
  }

  /// Clear search results
  void clearCarSearch() {
    _carSearchResults = [];
    notifyListeners();
  }

  /// Apply a car search result to the current draft (autofill)
  Future<void> applyCarSearchResult(CarSearchResult result) async {
    if (_currentDraft == null) return;

    // Update draft with autofill data
    _currentDraft = _currentDraft!.copyWith(
      brand: result.brandName,
      model: result.modelName,
      variant: result.variantName,
      bodyType: result.bodyType,
      transmission: result.transmission,
      fuelType: result.fuelType,
    );

    // Load the cascading dropdowns so they reflect the selection
    await loadBrands();
    await loadModels(result.brandName);
    await loadVariants(result.modelName);

    _carSearchResults = [];
    notifyListeners();
  }

  /// Load all drafts for seller
  Future<void> loadDrafts(String sellerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _getSellerDraftsUseCase.call(sellerId);
    result.fold(
      (failure) => _errorMessage = failure.message,
      (drafts) => _drafts = drafts,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Load specific draft for editing
  Future<void> loadDraft(String draftId) async {
    _isLoading = true;
    _errorMessage = null;
    _isSubmissionSuccess = false;
    notifyListeners();

    final result = await _getDraftUseCase.call(draftId);
    result.fold((failure) => _errorMessage = failure.message, (draft) {
      _currentDraft = draft;
      if (draft == null) _errorMessage = 'Draft not found';
    });

    _isLoading = false;
    notifyListeners();
  }

  /// Create new draft (Local only until saved)
  Future<void> createNewDraft(String sellerId) async {
    _isLoading = true;
    _errorMessage = null;
    _isSubmissionSuccess = false;
    notifyListeners();

    // Restore offline draft only if it hasn't been synced to DB yet (empty ID).
    // If it has an ID, it's already accessible via loadDraft() from the drafts list.
    final localDraft = await _loadDraftLocally(sellerId);
    if (localDraft != null && localDraft.id.isEmpty) {
      _currentDraft = localDraft;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Clear stale local draft (synced drafts should be loaded via loadDraft)
    if (localDraft != null) {
      await _clearLocalDraft(sellerId);
    }

    // Create local draft with empty ID to defer DB creation
    _currentDraft = ListingDraftEntity(
      id: '',
      sellerId: sellerId,
      currentStep: 1,
      lastSaved: DateTime.now(),
      isComplete: false,
    );

    // Fetch profile to auto-fill address
    final profileResult = await _getUserProfileUseCase.call();
    profileResult.fold(
      (failure) => null, // Ignore profile fetch error
      (profile) {
        if (_currentDraft != null) {
          _currentDraft = _currentDraft!.copyWith(
            province: profile.province,
            cityMunicipality: profile.city,
            barangay: profile.barangay,
            lastSaved: DateTime.now(),
          );
          // Note: We do NOT auto-save here.
          // The draft remains local until user action triggers save/upload.
        }
      },
    );

    _isLoading = false;
    notifyListeners();

    await _saveDraftLocally(_currentDraft!);
  }

  /// Ensure draft exists in DB (Create if local)
  Future<bool> _ensureDraftExists() async {
    if (_currentDraft == null) return false;
    if (_currentDraft!.id.isNotEmpty) return true;

    // Capture all local data before DB creation overwrites _currentDraft
    final localDraft = _currentDraft!;

    // Create real draft in DB
    final result = await _createDraftUseCase.call(localDraft.sellerId);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (newDraft) {
        // Merge ALL local data into the new DB draft (only override the ID)
        _currentDraft = localDraft.copyWith(
          id: newDraft.id,
          lastSaved: DateTime.now(),
        );
        notifyListeners();
        return true;
      },
    );
  }

  /// Update draft with new data
  void updateDraft(ListingDraftEntity updatedDraft) {
    _currentDraft = updatedDraft;
    notifyListeners();
    _autoSave();
  }

  /// Navigation methods (Step increment/decrement)
  void goToNextStep() {
    if (!canGoNext || _currentDraft == null) return;
    _updateStep(_currentDraft!.currentStep + 1);
    _autoSave();
  }

  void goToPreviousStep() {
    if (!canGoPrevious || _currentDraft == null) return;
    _updateStep(_currentDraft!.currentStep - 1);
  }

  void goToStep(int step) {
    if (_currentDraft == null || step < 1 || step > 9) return;
    _updateStep(step);
  }

  void _updateStep(int step) {
    if (_currentDraft == null) return;
    _currentDraft = _currentDraft!.copyWith(
      currentStep: step,
      lastSaved: DateTime.now(),
    );
    notifyListeners();
  }

  /// Auto-save draft
  Future<void> _autoSave() async {
    if (_currentDraft == null || _isSaving) return;

    await _saveDraftLocally(_currentDraft!);

    // Ensure DB record exists before saving
    if (_currentDraft!.id.isEmpty) {
      final success = await _ensureDraftExists();
      if (!success) {
        return;
      }
    }

    _isSaving = true;
    notifyListeners();
    await _saveDraftUseCase.call(_currentDraft!);
    _isSaving = false;
    notifyListeners();
  }

  /// Manual save
  Future<bool> saveDraft() async {
    if (_currentDraft == null) return false;
    if (_isSaving) return false; // Prevent duplicate saves from rapid clicks

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    await _saveDraftLocally(_currentDraft!);

    // Ensure DB record exists before saving
    if (_currentDraft!.id.isEmpty) {
      final success = await _ensureDraftExists();
      if (!success) {
        _isSaving = false;
        _errorMessage =
            'Saved locally. Connect to internet to sync this draft.';
        notifyListeners();
        return true;
      }
    }

    final result = await _saveDraftUseCase.call(_currentDraft!);
    _isSaving = false;
    notifyListeners();
    return result.fold((failure) {
      _errorMessage = 'Saved locally. Connect to internet to sync this draft.';
      notifyListeners();
      return true;
    }, (_) => true);
  }

  /// Upload photo for a category
  Future<bool> uploadPhoto(String categoryDisplayName, String localPath) async {
    if (_currentDraft == null) return false;

    // Ensure DB record exists (need ID for storage path)
    if (_currentDraft!.id.isEmpty) {
      final success = await _ensureDraftExists();
      if (!success) return false;
    }

    final categoryKey = PhotoCategories.toKey(categoryDisplayName);

    final result = await _uploadListingPhotoUseCase.call(
      userId: _currentDraft!.sellerId,
      listingId: _currentDraft!.id,
      category: categoryKey,
      imageFile: File(localPath),
    );

    return result.fold((failure) => false, (url) {
      final currentPhotos = Map<String, List<String>>.from(
        _currentDraft!.photoUrls ?? {},
      );
      currentPhotos[categoryKey] = [...(currentPhotos[categoryKey] ?? []), url];

      // Check if existing cover photo is still valid (exists in any category)
      final existingCover = _currentDraft!.coverPhotoUrl;
      final allUrls = currentPhotos.values.expand((urls) => urls).toSet();
      final isCoverValid =
          existingCover != null &&
          existingCover.isNotEmpty &&
          allUrls.contains(existingCover);
      final nextCover = isCoverValid ? existingCover : url;

      _currentDraft = _currentDraft!.copyWith(
        lastSaved: DateTime.now(),
        photoUrls: currentPhotos,
        coverPhotoUrl: nextCover,
      );
      notifyListeners();
      _autoSave();
      return true;
    });
  }

  /// Set selected featured photo for the draft.
  Future<void> setCoverPhoto(String coverPhotoUrl) async {
    if (_currentDraft == null) return;
    _currentDraft = _currentDraft!.copyWith(
      coverPhotoUrl: coverPhotoUrl,
      lastSaved: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// Upload deed of sale document
  Future<String?> uploadDeedOfSale(String localPath) async {
    if (_currentDraft == null) return null;

    // Ensure DB record exists
    if (_currentDraft!.id.isEmpty) {
      final success = await _ensureDraftExists();
      if (!success) return null;
    }

    final result = await _uploadDeedOfSaleUseCase.call(
      userId: _currentDraft!.sellerId,
      listingId: _currentDraft!.id,
      documentFile: File(localPath),
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return null;
      },
      (url) {
        _currentDraft = _currentDraft!.copyWith(
          lastSaved: DateTime.now(),
          deedOfSaleUrl: url,
        );
        notifyListeners();
        _autoSave();
        return url;
      },
    );
  }

  /// Remove deed of sale document
  Future<bool> removeDeedOfSale() async {
    if (_currentDraft == null || _currentDraft!.deedOfSaleUrl == null)
      return false;

    final result = await _deleteDeedOfSaleUseCase.call(
      _currentDraft!.deedOfSaleUrl!,
    );
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _currentDraft = _currentDraft!.copyWith(
          lastSaved: DateTime.now(),
          deedOfSaleUrl: null,
        );
        notifyListeners();
        _autoSave();
        return true;
      },
    );
  }

  /// Validate bidding configuration rules
  bool _validateBiddingConfig() {
    if (_currentDraft == null) return false;

    final increment = _currentDraft!.bidIncrement ?? 100;

    // Deposit is auto-calculated — no manual validation needed

    // Bid Increment rules: Min 100, 100 increments
    if (increment < 100) {
      _errorMessage = 'Bid increment must be at least ₱100';
      return false;
    }
    if (increment % 100 != 0) {
      _errorMessage = 'Bid increment must be a multiple of ₱100';
      return false;
    }

    return true;
  }

  /// Submit listing
  Future<bool> submitListing(String userId) async {
    if (_currentDraft == null || !canSubmit) return false;

    // Unsynced drafts cannot be submitted while offline.
    if (_currentDraft!.id.isEmpty) {
      _errorMessage =
          'Draft is saved locally. Connect to internet first to submit listing.';
      notifyListeners();
      return false;
    }

    // Compute end date from duration if user chose duration mode
    if (_currentDraft!.auctionEndDate == null &&
        _currentDraft!.auctionDurationHours != null) {
      _currentDraft = _currentDraft!.copyWith(
        auctionEndDate: DateTime.now().toUtc().add(
          Duration(hours: _currentDraft!.auctionDurationHours!),
        ),
        lastSaved: DateTime.now(),
      );
      await _saveDraftLocally(_currentDraft!);
    }

    // Fallback: apply safe default if still null
    if (_currentDraft!.auctionEndDate == null) {
      _currentDraft = _currentDraft!.copyWith(
        auctionEndDate: DateTime.now().toUtc().add(const Duration(days: 7)),
        lastSaved: DateTime.now(),
      );
      await _saveDraftLocally(_currentDraft!);
    }

    // Validate bidding config before submission
    if (!_validateBiddingConfig()) {
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Save one last time
      final saveResult = await _saveDraftUseCase.call(_currentDraft!);

      final saveSuccess = saveResult.fold((failure) {
        debugPrint('[submitListing] Save failed: ${failure.message}');
        _errorMessage = 'Unable to save your listing: ${failure.message}';
        return false;
      }, (_) => true);

      if (!saveSuccess) {
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      // 2. Mark draft as complete (CRITICAL: Required by submit_listing_from_draft RPC)
      final markCompleteResult = await _markDraftCompleteUseCase.call(
        _currentDraft!.id,
      );

      final completeSuccess = markCompleteResult.fold((failure) {
        _errorMessage = 'Unable to finalize your listing. Please try again.';
        return false;
      }, (_) => true);

      if (!completeSuccess) {
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      // 3. Submit (RPC handles token consumption and auction creation)
      final result = await _submitListingUseCase.call(_currentDraft!.id);

      _isSubmitting = false;
      return result.fold(
        (failure) {
          _errorMessage = _sanitizeErrorMessage(failure.message);
          notifyListeners();
          return false;
        },
        (_) {
          _isSubmissionSuccess = true;
          _clearLocalDraft(_currentDraft!.sellerId);
          _currentDraft = null;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Something went wrong. Please try again later.';
      notifyListeners();
      return false;
    }
  }

  /// Discard current draft: clears local storage and deletes DB draft if synced
  Future<void> discardDraft() async {
    if (_currentDraft == null) return;

    final sellerId = _currentDraft!.sellerId;
    final draftId = _currentDraft!.id;

    // Delete from DB if it was synced (has real ID)
    if (draftId.isNotEmpty) {
      await _deleteDraftUseCase.call(draftId);
      _drafts.removeWhere((d) => d.id == draftId);
    }

    // Always clear local storage
    await _clearLocalDraft(sellerId);
    _currentDraft = null;
    notifyListeners();
  }

  /// Delete draft
  Future<bool> deleteDraft(String draftId) async {
    final result = await _deleteDraftUseCase.call(draftId);
    return result.fold((failure) => false, (_) {
      _drafts.removeWhere((d) => d.id == draftId);
      if (_currentDraft?.id == draftId) _currentDraft = null;
      notifyListeners();
      return true;
    });
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Sanitize technical error messages into user-friendly ones
  String _sanitizeErrorMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('token') || lower.contains('insufficient')) {
      return 'You don\'t have enough listing tokens. Please purchase more to submit.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (lower.contains('permission') ||
        lower.contains('unauthorized') ||
        lower.contains('forbidden')) {
      return 'You don\'t have permission to perform this action.';
    }
    if (lower.contains('duplicate')) {
      return 'This listing appears to be a duplicate. Please check your existing listings.';
    }
    if (lower.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    // If message looks like a user-friendly message already (no stack traces or exceptions), return it
    if (!lower.contains('exception') &&
        !lower.contains('error:') &&
        message.length < 200) {
      return message;
    }
    return 'Something went wrong while submitting your listing. Please try again.';
  }

  String _localDraftKey(String sellerId) =>
      '$_localDraftStoragePrefix$sellerId';

  Future<void> _saveDraftLocally(ListingDraftEntity draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final model = ListingDraftModel(
        id: draft.id,
        sellerId: draft.sellerId,
        currentStep: draft.currentStep,
        lastSaved: draft.lastSaved,
        isComplete: draft.isComplete,
        brand: draft.brand,
        model: draft.model,
        variant: draft.variant,
        bodyType: draft.bodyType,
        year: draft.year,
        engineType: draft.engineType,
        engineDisplacement: draft.engineDisplacement,
        cylinderCount: draft.cylinderCount,
        horsepower: draft.horsepower,
        torque: draft.torque,
        transmission: draft.transmission,
        fuelType: draft.fuelType,
        driveType: draft.driveType,
        length: draft.length,
        width: draft.width,
        height: draft.height,
        wheelbase: draft.wheelbase,
        groundClearance: draft.groundClearance,
        seatingCapacity: draft.seatingCapacity,
        doorCount: draft.doorCount,
        fuelTankCapacity: draft.fuelTankCapacity,
        curbWeight: draft.curbWeight,
        grossWeight: draft.grossWeight,
        exteriorColor: draft.exteriorColor,
        paintType: draft.paintType,
        rimType: draft.rimType,
        rimSize: draft.rimSize,
        tireSize: draft.tireSize,
        tireBrand: draft.tireBrand,
        condition: draft.condition,
        mileage: draft.mileage,
        previousOwners: draft.previousOwners,
        hasModifications: draft.hasModifications,
        modificationsDetails: draft.modificationsDetails,
        hasWarranty: draft.hasWarranty,
        warrantyDetails: draft.warrantyDetails,
        usageType: draft.usageType,
        plateNumber: draft.plateNumber,
        orcrStatus: draft.orcrStatus,
        registrationStatus: draft.registrationStatus,
        registrationExpiry: draft.registrationExpiry,
        province: draft.province,
        cityMunicipality: draft.cityMunicipality,
        barangay: draft.barangay,
        photoUrls: draft.photoUrls,
        coverPhotoUrl: draft.coverPhotoUrl,
        tags: draft.tags,
        deedOfSaleUrl: draft.deedOfSaleUrl,
        description: draft.description,
        knownIssues: draft.knownIssues,
        features: draft.features,
        startingPrice: draft.startingPrice,
        reservePrice: draft.reservePrice,
        auctionEndDate: draft.auctionEndDate,
        biddingType: draft.biddingType,
        bidIncrement: draft.bidIncrement,
        minBidIncrement: draft.minBidIncrement,
        depositAmount: draft.depositAmount,
        enableIncrementalBidding: draft.enableIncrementalBidding,
        autoLiveAfterApproval: draft.autoLiveAfterApproval,
        scheduleLiveMode: draft.scheduleLiveMode,
        auctionStartDate: draft.auctionStartDate,
        auctionDurationHours: draft.auctionDurationHours,
        snipeGuardEnabled: draft.snipeGuardEnabled,
        snipeGuardThresholdSeconds: draft.snipeGuardThresholdSeconds,
        snipeGuardExtendSeconds: draft.snipeGuardExtendSeconds,
        allowsInstallment: draft.allowsInstallment,
        isPlateValid: draft.isPlateValid,
      );

      await prefs.setString(
        _localDraftKey(draft.sellerId),
        jsonEncode(model.toJson()),
      );
    } catch (_) {
      // Best-effort local persistence.
    }
  }

  Future<ListingDraftEntity?> _loadDraftLocally(String sellerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localDraftKey(sellerId));
      if (raw == null || raw.isEmpty) return null;

      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;

      return ListingDraftModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearLocalDraft(String sellerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localDraftKey(sellerId));
    } catch (_) {
      // Ignore local cleanup failures.
    }
  }
}
