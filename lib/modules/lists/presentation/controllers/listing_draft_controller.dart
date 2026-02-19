import 'dart:io';
import 'package:flutter/material.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/listing_draft_entity.dart';
import '../../domain/usecases/draft_management_usecases.dart';
import '../../domain/usecases/submission_usecases.dart';
import '../../domain/usecases/media_management_usecases.dart';
import '../../domain/usecases/get_vehicle_data_usecases.dart';
import '../../domain/entities/vehicle_entities.dart';
import '../../../profile/domain/usecases/get_user_profile_usecase.dart';

/// Controller for managing listing draft creation and editing
/// Handles 9-step form flow with auto-save and validation
class ListingDraftController extends ChangeNotifier {
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
       _getVehicleVariantsUseCase = getVehicleVariantsUseCase;

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
      (failure) => debugPrint('Error loading brands: ${failure.message}'), // Non-blocking
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
    result.fold(
      (failure) => _errorMessage = failure.message,
      (draft) {
        _currentDraft = draft;
        if (draft == null) _errorMessage = 'Draft not found';
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Create new draft (Local only until saved)
  Future<void> createNewDraft(String sellerId) async {
    _isLoading = true;
    _errorMessage = null;
    _isSubmissionSuccess = false;
    notifyListeners();

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
  }

  /// Ensure draft exists in DB (Create if local)
  Future<bool> _ensureDraftExists() async {
    if (_currentDraft == null) return false;
    if (_currentDraft!.id.isNotEmpty) return true;

    // Create real draft in DB
    final result = await _createDraftUseCase.call(_currentDraft!.sellerId);
    
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (newDraft) {
        // Merge local data into new draft (preserve address/inputs)
        _currentDraft = newDraft.copyWith(
          province: _currentDraft!.province,
          cityMunicipality: _currentDraft!.cityMunicipality,
          barangay: _currentDraft!.barangay,
          // Preserve other fields if user typed before save
          brand: _currentDraft!.brand,
          model: _currentDraft!.model,
          year: _currentDraft!.year,
          // ... map other fields if necessary, but usually create happens early
        );
        notifyListeners();
        return true;
      }
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
    
    // Ensure DB record exists before saving
    if (_currentDraft!.id.isEmpty) {
       final success = await _ensureDraftExists();
       if (!success) return;
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
    
    // Ensure DB record exists before saving
    if (_currentDraft!.id.isEmpty) {
       final success = await _ensureDraftExists();
       if (!success) return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _saveDraftUseCase.call(_currentDraft!);
    _isSaving = false;
    notifyListeners();
    return result.isRight();
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

    return result.fold(
      (failure) => false,
      (url) {
        final currentPhotos = Map<String, List<String>>.from(_currentDraft!.photoUrls ?? {});
        currentPhotos[categoryKey] = [...(currentPhotos[categoryKey] ?? []), url];
        
        _currentDraft = _currentDraft!.copyWith(
          lastSaved: DateTime.now(),
          photoUrls: currentPhotos,
        );
        notifyListeners();
        _autoSave();
        return true;
      },
    );
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
    if (_currentDraft == null || _currentDraft!.deedOfSaleUrl == null) return false;

    final result = await _deleteDeedOfSaleUseCase.call(_currentDraft!.deedOfSaleUrl!);
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

    final deposit = _currentDraft!.depositAmount ?? 50000;
    final increment = _currentDraft!.bidIncrement ?? 1000;

    // Deposit rules: 5k-50k, 5k increments
    if (deposit < 5000) {
      _errorMessage = 'Deposit amount must be at least ₱5,000';
      return false;
    }
    if (deposit > 50000) {
      _errorMessage = 'Deposit amount cannot exceed ₱50,000';
      return false;
    }
    if (deposit % 5000 != 0) {
      _errorMessage = 'Deposit amount must be a multiple of ₱5,000';
      return false;
    }

    // Bid Increment rules: Min 1k, 1k increments
    if (increment < 1000) {
      _errorMessage = 'Bid increment must be at least ₱1,000';
      return false;
    }
    if (increment % 1000 != 0) {
      _errorMessage = 'Bid increment must be a multiple of ₱1,000';
      return false;
    }

    return true;
  }

  /// Submit listing
  Future<bool> submitListing(String userId) async {
    if (_currentDraft == null || !canSubmit) return false;

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
      
      final saveSuccess = saveResult.fold(
        (failure) {
          _errorMessage = 'Failed to save draft: ${failure.message}';
          return false;
        },
        (_) => true,
      );

      if (!saveSuccess) {
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      // 2. Mark draft as complete (CRITICAL: Required by submit_listing_from_draft RPC)
      final markCompleteResult = await _markDraftCompleteUseCase.call(_currentDraft!.id);
      
      final completeSuccess = markCompleteResult.fold(
        (failure) {
          _errorMessage = 'Failed to mark draft as complete: ${failure.message}';
          return false;
        },
        (_) => true,
      );

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
          _errorMessage = failure.message;
          notifyListeners();
          return false;
        },
        (_) {
          _isSubmissionSuccess = true;
          _currentDraft = null;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Error submitting listing: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete draft
  Future<bool> deleteDraft(String draftId) async {
    final result = await _deleteDraftUseCase.call(draftId);
    return result.fold(
      (failure) => false,
      (_) {
        _drafts.removeWhere((d) => d.id == draftId);
        if (_currentDraft?.id == draftId) _currentDraft = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}