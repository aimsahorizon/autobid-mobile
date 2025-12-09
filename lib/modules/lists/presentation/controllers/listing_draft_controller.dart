import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/listing_draft_entity.dart';
import '../../data/datasources/listing_draft_mock_datasource.dart';
import '../../data/datasources/listing_supabase_datasource.dart';

/// Controller for managing listing draft creation and editing
/// Handles 9-step form flow with auto-save and validation
class ListingDraftController extends ChangeNotifier {
  final ListingDraftMockDataSource? _mockDataSource;
  final ListingSupabaseDataSource? _supabaseDataSource;
  final bool _useMockData;

  /// Create controller with mock datasource
  ListingDraftController.mock(
    ListingDraftMockDataSource dataSource,
  )   : _mockDataSource = dataSource,
        _supabaseDataSource = null,
        _useMockData = true;

  /// Create controller with Supabase datasource
  /// Note: Token consumption now handled atomically inside RPC function
  ListingDraftController.supabase(
    ListingSupabaseDataSource dataSource,
  )   : _mockDataSource = null,
        _supabaseDataSource = dataSource,
        _useMockData = false;

  /// Legacy constructor for backward compatibility
  ListingDraftController(
    ListingDraftMockDataSource dataSource,
  )   : _mockDataSource = dataSource,
        _supabaseDataSource = null,
        _useMockData = true;

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

    try {
      if (_useMockData) {
        _drafts = await _mockDataSource!.getSellerDrafts(sellerId);
      } else {
        // ListingDraftModel extends ListingDraftEntity, so we can use it directly
        _drafts = await _supabaseDataSource!.getSellerDrafts(sellerId);
      }
    } catch (e) {
      _errorMessage = 'Failed to load drafts';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load specific draft for editing
  Future<void> loadDraft(String draftId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockData) {
        _currentDraft = await _mockDataSource!.getDraft(draftId);
      } else {
        // ListingDraftModel extends ListingDraftEntity, so we can use it directly
        _currentDraft = await _supabaseDataSource!.getDraft(draftId);
      }
      if (_currentDraft == null) {
        _errorMessage = 'Draft not found';
      }
    } catch (e) {
      _errorMessage = 'Failed to load draft';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new draft
  Future<void> createNewDraft(String sellerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockData) {
        _currentDraft = _mockDataSource!.createNewDraft(sellerId);
      } else {
        // ListingDraftModel extends ListingDraftEntity, so we can use it directly
        _currentDraft = await _supabaseDataSource!.createDraft(sellerId);
      }
    } catch (e) {
      _errorMessage = 'Failed to create new listing: $e';
      _currentDraft = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update draft with new data
  void updateDraft(ListingDraftEntity updatedDraft) {
    _currentDraft = updatedDraft;
    notifyListeners();
    // Auto-save after a short delay
    _autoSave();
  }

  /// Go to next step
  void goToNextStep() {
    if (!canGoNext || _currentDraft == null) return;
    _currentDraft = ListingDraftEntity(
      id: _currentDraft!.id,
      sellerId: _currentDraft!.sellerId,
      currentStep: _currentDraft!.currentStep + 1,
      lastSaved: DateTime.now(),
      isComplete: _currentDraft!.isComplete,
      brand: _currentDraft!.brand,
      model: _currentDraft!.model,
      variant: _currentDraft!.variant,
      year: _currentDraft!.year,
      engineType: _currentDraft!.engineType,
      engineDisplacement: _currentDraft!.engineDisplacement,
      cylinderCount: _currentDraft!.cylinderCount,
      horsepower: _currentDraft!.horsepower,
      torque: _currentDraft!.torque,
      transmission: _currentDraft!.transmission,
      fuelType: _currentDraft!.fuelType,
      driveType: _currentDraft!.driveType,
      length: _currentDraft!.length,
      width: _currentDraft!.width,
      height: _currentDraft!.height,
      wheelbase: _currentDraft!.wheelbase,
      groundClearance: _currentDraft!.groundClearance,
      seatingCapacity: _currentDraft!.seatingCapacity,
      doorCount: _currentDraft!.doorCount,
      fuelTankCapacity: _currentDraft!.fuelTankCapacity,
      curbWeight: _currentDraft!.curbWeight,
      grossWeight: _currentDraft!.grossWeight,
      exteriorColor: _currentDraft!.exteriorColor,
      paintType: _currentDraft!.paintType,
      rimType: _currentDraft!.rimType,
      rimSize: _currentDraft!.rimSize,
      tireSize: _currentDraft!.tireSize,
      tireBrand: _currentDraft!.tireBrand,
      condition: _currentDraft!.condition,
      mileage: _currentDraft!.mileage,
      previousOwners: _currentDraft!.previousOwners,
      hasModifications: _currentDraft!.hasModifications,
      modificationsDetails: _currentDraft!.modificationsDetails,
      hasWarranty: _currentDraft!.hasWarranty,
      warrantyDetails: _currentDraft!.warrantyDetails,
      usageType: _currentDraft!.usageType,
      plateNumber: _currentDraft!.plateNumber,
      orcrStatus: _currentDraft!.orcrStatus,
      registrationStatus: _currentDraft!.registrationStatus,
      registrationExpiry: _currentDraft!.registrationExpiry,
      province: _currentDraft!.province,
      cityMunicipality: _currentDraft!.cityMunicipality,
      photoUrls: _currentDraft!.photoUrls,
      description: _currentDraft!.description,
      knownIssues: _currentDraft!.knownIssues,
      features: _currentDraft!.features,
      startingPrice: _currentDraft!.startingPrice,
      reservePrice: _currentDraft!.reservePrice,
      auctionEndDate: _currentDraft!.auctionEndDate,
    );
    notifyListeners();
    _autoSave();
  }

  /// Go to previous step
  void goToPreviousStep() {
    if (!canGoPrevious || _currentDraft == null) return;
    _currentDraft = ListingDraftEntity(
      id: _currentDraft!.id,
      sellerId: _currentDraft!.sellerId,
      currentStep: _currentDraft!.currentStep - 1,
      lastSaved: DateTime.now(),
      isComplete: _currentDraft!.isComplete,
      brand: _currentDraft!.brand,
      model: _currentDraft!.model,
      variant: _currentDraft!.variant,
      year: _currentDraft!.year,
      engineType: _currentDraft!.engineType,
      engineDisplacement: _currentDraft!.engineDisplacement,
      cylinderCount: _currentDraft!.cylinderCount,
      horsepower: _currentDraft!.horsepower,
      torque: _currentDraft!.torque,
      transmission: _currentDraft!.transmission,
      fuelType: _currentDraft!.fuelType,
      driveType: _currentDraft!.driveType,
      length: _currentDraft!.length,
      width: _currentDraft!.width,
      height: _currentDraft!.height,
      wheelbase: _currentDraft!.wheelbase,
      groundClearance: _currentDraft!.groundClearance,
      seatingCapacity: _currentDraft!.seatingCapacity,
      doorCount: _currentDraft!.doorCount,
      fuelTankCapacity: _currentDraft!.fuelTankCapacity,
      curbWeight: _currentDraft!.curbWeight,
      grossWeight: _currentDraft!.grossWeight,
      exteriorColor: _currentDraft!.exteriorColor,
      paintType: _currentDraft!.paintType,
      rimType: _currentDraft!.rimType,
      rimSize: _currentDraft!.rimSize,
      tireSize: _currentDraft!.tireSize,
      tireBrand: _currentDraft!.tireBrand,
      condition: _currentDraft!.condition,
      mileage: _currentDraft!.mileage,
      previousOwners: _currentDraft!.previousOwners,
      hasModifications: _currentDraft!.hasModifications,
      modificationsDetails: _currentDraft!.modificationsDetails,
      hasWarranty: _currentDraft!.hasWarranty,
      warrantyDetails: _currentDraft!.warrantyDetails,
      usageType: _currentDraft!.usageType,
      plateNumber: _currentDraft!.plateNumber,
      orcrStatus: _currentDraft!.orcrStatus,
      registrationStatus: _currentDraft!.registrationStatus,
      registrationExpiry: _currentDraft!.registrationExpiry,
      province: _currentDraft!.province,
      cityMunicipality: _currentDraft!.cityMunicipality,
      photoUrls: _currentDraft!.photoUrls,
      description: _currentDraft!.description,
      knownIssues: _currentDraft!.knownIssues,
      features: _currentDraft!.features,
      startingPrice: _currentDraft!.startingPrice,
      reservePrice: _currentDraft!.reservePrice,
      auctionEndDate: _currentDraft!.auctionEndDate,
    );
    notifyListeners();
  }

  /// Jump to specific step
  void goToStep(int step) {
    if (_currentDraft == null || step < 1 || step > 9) return;
    _currentDraft = ListingDraftEntity(
      id: _currentDraft!.id,
      sellerId: _currentDraft!.sellerId,
      currentStep: step,
      lastSaved: DateTime.now(),
      isComplete: _currentDraft!.isComplete,
      brand: _currentDraft!.brand,
      model: _currentDraft!.model,
      variant: _currentDraft!.variant,
      year: _currentDraft!.year,
      engineType: _currentDraft!.engineType,
      engineDisplacement: _currentDraft!.engineDisplacement,
      cylinderCount: _currentDraft!.cylinderCount,
      horsepower: _currentDraft!.horsepower,
      torque: _currentDraft!.torque,
      transmission: _currentDraft!.transmission,
      fuelType: _currentDraft!.fuelType,
      driveType: _currentDraft!.driveType,
      length: _currentDraft!.length,
      width: _currentDraft!.width,
      height: _currentDraft!.height,
      wheelbase: _currentDraft!.wheelbase,
      groundClearance: _currentDraft!.groundClearance,
      seatingCapacity: _currentDraft!.seatingCapacity,
      doorCount: _currentDraft!.doorCount,
      fuelTankCapacity: _currentDraft!.fuelTankCapacity,
      curbWeight: _currentDraft!.curbWeight,
      grossWeight: _currentDraft!.grossWeight,
      exteriorColor: _currentDraft!.exteriorColor,
      paintType: _currentDraft!.paintType,
      rimType: _currentDraft!.rimType,
      rimSize: _currentDraft!.rimSize,
      tireSize: _currentDraft!.tireSize,
      tireBrand: _currentDraft!.tireBrand,
      condition: _currentDraft!.condition,
      mileage: _currentDraft!.mileage,
      previousOwners: _currentDraft!.previousOwners,
      hasModifications: _currentDraft!.hasModifications,
      modificationsDetails: _currentDraft!.modificationsDetails,
      hasWarranty: _currentDraft!.hasWarranty,
      warrantyDetails: _currentDraft!.warrantyDetails,
      usageType: _currentDraft!.usageType,
      plateNumber: _currentDraft!.plateNumber,
      orcrStatus: _currentDraft!.orcrStatus,
      registrationStatus: _currentDraft!.registrationStatus,
      registrationExpiry: _currentDraft!.registrationExpiry,
      province: _currentDraft!.province,
      cityMunicipality: _currentDraft!.cityMunicipality,
      photoUrls: _currentDraft!.photoUrls,
      description: _currentDraft!.description,
      knownIssues: _currentDraft!.knownIssues,
      features: _currentDraft!.features,
      startingPrice: _currentDraft!.startingPrice,
      reservePrice: _currentDraft!.reservePrice,
      auctionEndDate: _currentDraft!.auctionEndDate,
    );
    notifyListeners();
  }

  /// Auto-save draft
  Future<void> _autoSave() async {
    if (_currentDraft == null || _isSaving) return;

    _isSaving = true;
    notifyListeners();

    try {
      if (_useMockData) {
        await _mockDataSource!.saveDraft(_currentDraft!);
      } else {
        await _supabaseDataSource!.saveDraft(_currentDraft!);
      }
    } catch (e) {
      // Silent fail for auto-save
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Manual save
  Future<bool> saveDraft() async {
    if (_currentDraft == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockData) {
        final success = await _mockDataSource!.saveDraft(_currentDraft!);
        return success;
      } else {
        await _supabaseDataSource!.saveDraft(_currentDraft!);
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to save draft';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Upload photo for a category
  Future<bool> uploadPhoto(String category, String localPath) async {
    if (_currentDraft == null) return false;

    try {
      String? url;
      if (_useMockData) {
        url = await _mockDataSource!.uploadPhoto(
          _currentDraft!.id,
          category,
          localPath,
        );
      } else {
        url = await _supabaseDataSource!.uploadPhoto(
          userId: _currentDraft!.sellerId,
          listingId: _currentDraft!.id,
          category: category,
          imageFile: File(localPath),
        );
      }

      if (url != null) {
        final currentPhotos = Map<String, List<String>>.from(
          _currentDraft!.photoUrls ?? {},
        );
        currentPhotos[category] = [...(currentPhotos[category] ?? []), url];

        _currentDraft = ListingDraftEntity(
          id: _currentDraft!.id,
          sellerId: _currentDraft!.sellerId,
          currentStep: _currentDraft!.currentStep,
          lastSaved: DateTime.now(),
          isComplete: _currentDraft!.isComplete,
          brand: _currentDraft!.brand,
          model: _currentDraft!.model,
          variant: _currentDraft!.variant,
          year: _currentDraft!.year,
          engineType: _currentDraft!.engineType,
          engineDisplacement: _currentDraft!.engineDisplacement,
          cylinderCount: _currentDraft!.cylinderCount,
          horsepower: _currentDraft!.horsepower,
          torque: _currentDraft!.torque,
          transmission: _currentDraft!.transmission,
          fuelType: _currentDraft!.fuelType,
          driveType: _currentDraft!.driveType,
          length: _currentDraft!.length,
          width: _currentDraft!.width,
          height: _currentDraft!.height,
          wheelbase: _currentDraft!.wheelbase,
          groundClearance: _currentDraft!.groundClearance,
          seatingCapacity: _currentDraft!.seatingCapacity,
          doorCount: _currentDraft!.doorCount,
          fuelTankCapacity: _currentDraft!.fuelTankCapacity,
          curbWeight: _currentDraft!.curbWeight,
          grossWeight: _currentDraft!.grossWeight,
          exteriorColor: _currentDraft!.exteriorColor,
          paintType: _currentDraft!.paintType,
          rimType: _currentDraft!.rimType,
          rimSize: _currentDraft!.rimSize,
          tireSize: _currentDraft!.tireSize,
          tireBrand: _currentDraft!.tireBrand,
          condition: _currentDraft!.condition,
          mileage: _currentDraft!.mileage,
          previousOwners: _currentDraft!.previousOwners,
          hasModifications: _currentDraft!.hasModifications,
          modificationsDetails: _currentDraft!.modificationsDetails,
          hasWarranty: _currentDraft!.hasWarranty,
          warrantyDetails: _currentDraft!.warrantyDetails,
          usageType: _currentDraft!.usageType,
          plateNumber: _currentDraft!.plateNumber,
          orcrStatus: _currentDraft!.orcrStatus,
          registrationStatus: _currentDraft!.registrationStatus,
          registrationExpiry: _currentDraft!.registrationExpiry,
          province: _currentDraft!.province,
          cityMunicipality: _currentDraft!.cityMunicipality,
          photoUrls: currentPhotos,
          description: _currentDraft!.description,
          knownIssues: _currentDraft!.knownIssues,
          features: _currentDraft!.features,
          startingPrice: _currentDraft!.startingPrice,
          reservePrice: _currentDraft!.reservePrice,
          auctionEndDate: _currentDraft!.auctionEndDate,
        );
        notifyListeners();
        _autoSave();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Submit listing
  Future<bool> submitListing(String userId) async {
    if (_currentDraft == null || !canSubmit) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Save draft one final time before submission to ensure all data is persisted
      if (!_useMockData && _supabaseDataSource != null) {
        await _supabaseDataSource.saveDraft(_currentDraft!);
      }

      // Mark draft as complete before submission (update database directly)
      if (!_useMockData && _supabaseDataSource != null) {
        await _supabaseDataSource.markDraftComplete(_currentDraft!.id);
      }

      // NOTE: Token consumption happens INSIDE the RPC function atomically
      // This prevents token loss if submission fails after consumption

      // Submit the listing (RPC consumes token atomically)
      if (_useMockData) {
        final success = await _mockDataSource!.submitListing(_currentDraft!.id);
        if (success) {
          _currentDraft = null;
        }
        return success;
      } else {
        await _supabaseDataSource!.submitListing(_currentDraft!.id);
        _currentDraft = null;
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to submit listing: $e';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Delete draft
  Future<bool> deleteDraft(String draftId) async {
    try {
      if (_useMockData) {
        final success = await _mockDataSource!.deleteDraft(draftId);
        if (success) {
          _drafts.removeWhere((d) => d.id == draftId);
          if (_currentDraft?.id == draftId) {
            _currentDraft = null;
          }
          notifyListeners();
        }
        return success;
      } else {
        await _supabaseDataSource!.deleteDraft(draftId);
        _drafts.removeWhere((d) => d.id == draftId);
        if (_currentDraft?.id == draftId) {
          _currentDraft = null;
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
