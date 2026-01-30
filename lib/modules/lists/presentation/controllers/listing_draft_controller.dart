import 'dart:io';
import 'package:flutter/material.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/listing_draft_entity.dart';
import '../../domain/usecases/draft_management_usecases.dart';
import '../../domain/usecases/submission_usecases.dart';
import '../../domain/usecases/media_management_usecases.dart';

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
  }) : _getSellerDraftsUseCase = getSellerDraftsUseCase,
       _getDraftUseCase = getDraftUseCase,
       _createDraftUseCase = createDraftUseCase,
       _saveDraftUseCase = saveDraftUseCase,
       _markDraftCompleteUseCase = markDraftCompleteUseCase,
       _deleteDraftUseCase = deleteDraftUseCase,
       _submitListingUseCase = submitListingUseCase,
       _uploadListingPhotoUseCase = uploadListingPhotoUseCase,
       _uploadDeedOfSaleUseCase = uploadDeedOfSaleUseCase,
       _deleteDeedOfSaleUseCase = deleteDeedOfSaleUseCase;

  // State
  ListingDraftEntity? _currentDraft;
  List<ListingDraftEntity> _drafts = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Getters
  ListingDraftEntity? get currentDraft => _currentDraft;
  List<ListingDraftEntity> get drafts => _drafts;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  int get currentStep => _currentDraft?.currentStep ?? 1;
  bool get canGoNext => _currentDraft != null && currentStep < 9;
  bool get canGoPrevious => _currentDraft != null && currentStep > 1;
  bool get canSubmit => (_currentDraft?.completionPercentage ?? 0) >= 100;

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

  /// Create new draft
  Future<void> createNewDraft(String sellerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _createDraftUseCase.call(sellerId);
    result.fold(
      (failure) => _errorMessage = failure.message,
      (draft) => _currentDraft = draft,
    );

    _isLoading = false;
    notifyListeners();
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
    _isSaving = true;
    notifyListeners();
    await _saveDraftUseCase.call(_currentDraft!);
    _isSaving = false;
    notifyListeners();
  }

  /// Manual save
  Future<bool> saveDraft() async {
    if (_currentDraft == null) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _saveDraftUseCase.call(_currentDraft!);
    _isSaving = false;
    notifyListeners();
    return result.isRight();
  }

  /// Upload photo for a category
  Future<bool> uploadPhoto(String category, String localPath) async {
    if (_currentDraft == null) return false;

    final result = await _uploadListingPhotoUseCase.call(
      userId: _currentDraft!.sellerId,
      listingId: _currentDraft!.id,
      category: category,
      imageFile: File(localPath),
    );

    return result.fold(
      (failure) => false,
      (url) {
        final currentPhotos = Map<String, List<String>>.from(_currentDraft!.photoUrls ?? {});
        currentPhotos[category] = [...(currentPhotos[category] ?? []), url];
        
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
      await _saveDraftUseCase.call(_currentDraft!);

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