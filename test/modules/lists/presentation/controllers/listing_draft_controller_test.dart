import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/lists/presentation/controllers/listing_draft_controller.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/listing_draft_entity.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/draft_management_usecases.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/submission_usecases.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/media_management_usecases.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/get_vehicle_data_usecases.dart';

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
  GetVehicleBrandsUseCase,
  GetVehicleModelsUseCase,
  GetVehicleVariantsUseCase,
])
import 'listing_draft_controller_test.mocks.dart';

void main() {
  late ListingDraftController controller;
  late MockGetSellerDraftsUseCase mockGetSellerDrafts;
  late MockGetDraftUseCase mockGetDraft;
  late MockCreateDraftUseCase mockCreateDraft;
  late MockSaveDraftUseCase mockSaveDraft;
  late MockMarkDraftCompleteUseCase mockMarkComplete;
  late MockDeleteDraftUseCase mockDeleteDraft;
  late MockSubmitListingUseCase mockSubmitListing;
  late MockUploadListingPhotoUseCase mockUploadPhoto;
  late MockUploadDeedOfSaleUseCase mockUploadDeed;
  late MockDeleteDeedOfSaleUseCase mockDeleteDeed;
  late MockGetVehicleBrandsUseCase mockGetBrands;
  late MockGetVehicleModelsUseCase mockGetModels;
  late MockGetVehicleVariantsUseCase mockGetVariants;

  setUp(() {
    provideDummy<Either<Failure, ListingDraftEntity>>(
      Right(ListingDraftEntity(
        id: 'dummy',
        sellerId: 'dummy',
        currentStep: 1,
        lastSaved: DateTime.now(),
      ))
    );
    provideDummy<Either<Failure, String>>(const Right('dummy_url'));
    provideDummy<Either<Failure, void>>(const Right(null));

    mockGetSellerDrafts = MockGetSellerDraftsUseCase();
    mockGetDraft = MockGetDraftUseCase();
    mockCreateDraft = MockCreateDraftUseCase();
    mockSaveDraft = MockSaveDraftUseCase();
    mockMarkComplete = MockMarkDraftCompleteUseCase();
    mockDeleteDraft = MockDeleteDraftUseCase();
    mockSubmitListing = MockSubmitListingUseCase();
    mockUploadPhoto = MockUploadListingPhotoUseCase();
    mockUploadDeed = MockUploadDeedOfSaleUseCase();
    mockDeleteDeed = MockDeleteDeedOfSaleUseCase();
    mockGetBrands = MockGetVehicleBrandsUseCase();
    mockGetModels = MockGetVehicleModelsUseCase();
    mockGetVariants = MockGetVehicleVariantsUseCase();

    controller = ListingDraftController(
      getSellerDraftsUseCase: mockGetSellerDrafts,
      getDraftUseCase: mockGetDraft,
      createDraftUseCase: mockCreateDraft,
      saveDraftUseCase: mockSaveDraft,
      markDraftCompleteUseCase: mockMarkComplete,
      deleteDraftUseCase: mockDeleteDraft,
      submitListingUseCase: mockSubmitListing,
      uploadListingPhotoUseCase: mockUploadPhoto,
      uploadDeedOfSaleUseCase: mockUploadDeed,
      deleteDeedOfSaleUseCase: mockDeleteDeed,
      getVehicleBrandsUseCase: mockGetBrands,
      getVehicleModelsUseCase: mockGetModels,
      getVehicleVariantsUseCase: mockGetVariants,
    );
  });

  group('ListingDraftController Photo Logic', () {
    final tDraft = ListingDraftEntity(
      id: 'draft_1',
      sellerId: 'user_1',
      currentStep: 1,
      lastSaved: DateTime.now(),
    );

    test('uploadPhoto should append URL to list (simulating controller logic)', () async {
      // Setup initial state
      when(mockCreateDraft.call(any)).thenAnswer((_) async => Right(tDraft));
      await controller.createNewDraft('user_1');

      // 1. Upload first photo
      when(mockUploadPhoto.call(
        userId: anyNamed('userId'),
        listingId: anyNamed('listingId'),
        category: anyNamed('category'),
        imageFile: anyNamed('imageFile'),
      )).thenAnswer((_) async => const Right('http://url1.jpg'));

      when(mockSaveDraft.call(any)).thenAnswer((_) async => const Right(null));

      final success1 = await controller.uploadPhoto('Front View', 'path/to/img1.jpg');
      
      expect(success1, true);
      expect(controller.currentDraft!.photoUrls!['front_view']!.length, 1);
      expect(controller.currentDraft!.photoUrls!['front_view']!.first, 'http://url1.jpg');

      // 2. Upload second photo to SAME category
      when(mockUploadPhoto.call(
        userId: anyNamed('userId'),
        listingId: anyNamed('listingId'),
        category: anyNamed('category'),
        imageFile: anyNamed('imageFile'),
      )).thenAnswer((_) async => const Right('http://url2.jpg'));

      final success2 = await controller.uploadPhoto('Front View', 'path/to/img2.jpg');
      
      expect(success2, true);
      expect(controller.currentDraft!.photoUrls!['front_view']!.length, 2);
    });
  });
}