import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/listing_draft_entity.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/draft_management_usecases.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/get_vehicle_data_usecases.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/media_management_usecases.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/submission_usecases.dart';
import 'package:autobid_mobile/modules/lists/presentation/controllers/listing_draft_controller.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/user_profile_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'listing_draft_controller_test.mocks.dart';

@GenerateMocks([
  GetSellerDraftsUseCase,
  GetDraftUseCase,
  CreateDraftUseCase,
  SaveDraftUseCase,
  MarkDraftCompleteUseCase,
  DeleteDraftUseCase,
  SubmitListingUseCase,
  UploadListingPhotoUseCase,
  UploadDeedOfSaleUseCase,
  DeleteDeedOfSaleUseCase,
  GetUserProfileUseCase,
  GetVehicleBrandsUseCase,
  GetVehicleModelsUseCase,
  GetVehicleVariantsUseCase,
])
void main() {
  late ListingDraftController controller;
  late MockCreateDraftUseCase mockCreateDraftUseCase;
  late MockGetUserProfileUseCase mockGetUserProfileUseCase;
  late MockSaveDraftUseCase mockSaveDraftUseCase;
  // Other mocks needed for constructor but not primary test focus
  late MockGetSellerDraftsUseCase mockGetSellerDraftsUseCase;
  late MockGetDraftUseCase mockGetDraftUseCase;
  late MockMarkDraftCompleteUseCase mockMarkDraftCompleteUseCase;
  late MockDeleteDraftUseCase mockDeleteDraftUseCase;
  late MockSubmitListingUseCase mockSubmitListingUseCase;
  late MockUploadListingPhotoUseCase mockUploadListingPhotoUseCase;
  late MockUploadDeedOfSaleUseCase mockUploadDeedOfSaleUseCase;
  late MockDeleteDeedOfSaleUseCase mockDeleteDeedOfSaleUseCase;
  late MockGetVehicleBrandsUseCase mockGetVehicleBrandsUseCase;
  late MockGetVehicleModelsUseCase mockGetVehicleModelsUseCase;
  late MockGetVehicleVariantsUseCase mockGetVehicleVariantsUseCase;

  setUp(() {
    mockCreateDraftUseCase = MockCreateDraftUseCase();
    mockGetUserProfileUseCase = MockGetUserProfileUseCase();
    mockSaveDraftUseCase = MockSaveDraftUseCase();
    mockGetSellerDraftsUseCase = MockGetSellerDraftsUseCase();
    mockGetDraftUseCase = MockGetDraftUseCase();
    mockMarkDraftCompleteUseCase = MockMarkDraftCompleteUseCase();
    mockDeleteDraftUseCase = MockDeleteDraftUseCase();
    mockSubmitListingUseCase = MockSubmitListingUseCase();
    mockUploadListingPhotoUseCase = MockUploadListingPhotoUseCase();
    mockUploadDeedOfSaleUseCase = MockUploadDeedOfSaleUseCase();
    mockDeleteDeedOfSaleUseCase = MockDeleteDeedOfSaleUseCase();
    mockGetVehicleBrandsUseCase = MockGetVehicleBrandsUseCase();
    mockGetVehicleModelsUseCase = MockGetVehicleModelsUseCase();
    mockGetVehicleVariantsUseCase = MockGetVehicleVariantsUseCase();

    provideDummy<Either<Failure, UserProfileEntity>>(
      const Left(ServerFailure('dummy')),
    );
    provideDummy<Either<Failure, ListingDraftEntity>>(
      const Left(ServerFailure('dummy')),
    );
    provideDummy<Either<Failure, void>>(
      const Left(ServerFailure('dummy')),
    );

    controller = ListingDraftController(
      createDraftUseCase: mockCreateDraftUseCase,
      getUserProfileUseCase: mockGetUserProfileUseCase,
      saveDraftUseCase: mockSaveDraftUseCase,
      getSellerDraftsUseCase: mockGetSellerDraftsUseCase,
      getDraftUseCase: mockGetDraftUseCase,
      markDraftCompleteUseCase: mockMarkDraftCompleteUseCase,
      deleteDraftUseCase: mockDeleteDraftUseCase,
      submitListingUseCase: mockSubmitListingUseCase,
      uploadListingPhotoUseCase: mockUploadListingPhotoUseCase,
      uploadDeedOfSaleUseCase: mockUploadDeedOfSaleUseCase,
      deleteDeedOfSaleUseCase: mockDeleteDeedOfSaleUseCase,
      getVehicleBrandsUseCase: mockGetVehicleBrandsUseCase,
      getVehicleModelsUseCase: mockGetVehicleModelsUseCase,
      getVehicleVariantsUseCase: mockGetVehicleVariantsUseCase,
    );
  });

  test('createNewDraft creates a local draft and DOES NOT call createDraftUseCase immediately', () async {
    // Arrange
    const sellerId = 'user123';
    final mockProfile = UserProfileEntity(
      id: sellerId,
      username: 'testuser',
      email: 'test@example.com',
      fullName: 'Test User',
      profilePhotoUrl: '',
      coverPhotoUrl: '',
      province: 'Metro Manila',
      city: 'Quezon City',
      barangay: 'Diliman',
    );

    // Mock profile fetch success
    when(mockGetUserProfileUseCase.call())
        .thenAnswer((_) async => Right(mockProfile));

    // Act
    await controller.createNewDraft(sellerId);

    // Assert
    expect(controller.currentDraft, isNotNull);
    expect(controller.currentDraft!.id, isEmpty, reason: 'Draft ID should be empty for local drafts');
    expect(controller.currentDraft!.sellerId, sellerId);
    
    // Check if address was pre-filled
    expect(controller.currentDraft!.province, 'Metro Manila');
    expect(controller.currentDraft!.cityMunicipality, 'Quezon City');
    expect(controller.currentDraft!.barangay, 'Diliman');

    // VERIFY: The database creation usecase was NEVER called
    verifyNever(mockCreateDraftUseCase.call(any));
    
    // VERIFY: Auto-save was NOT called (because it's local)
    verifyNever(mockSaveDraftUseCase.call(any));
  });

  test('saveDraft calls createDraftUseCase first if draft is local', () async {
    // Arrange
    const sellerId = 'user123';
    const newDbId = 'draft_db_123';
    
    // Setup local draft state
    when(mockGetUserProfileUseCase.call())
        .thenAnswer((_) async => Left(ServerFailure('Profile error'))); // Ignore profile for this test
    
    await controller.createNewDraft(sellerId);
    
    // Setup mocks for creation
    final dbDraft = ListingDraftEntity(
      id: newDbId,
      sellerId: sellerId,
      currentStep: 1,
      lastSaved: DateTime.now(),
    );
    
    when(mockCreateDraftUseCase.call(sellerId))
        .thenAnswer((_) async => Right(dbDraft));
        
    when(mockSaveDraftUseCase.call(any))
        .thenAnswer((_) async => const Right(null));

    // Act
    final success = await controller.saveDraft();

    // Assert
    expect(success, true);
    // Verify creation was called
    verify(mockCreateDraftUseCase.call(sellerId)).called(1);
    // Verify save was called with the NEW ID
    verify(mockSaveDraftUseCase.call(argThat(
      predicate<ListingDraftEntity>((draft) => draft.id == newDbId)
    ))).called(1);
    
    // Verify controller state is updated
    expect(controller.currentDraft!.id, newDbId);
  });
}
