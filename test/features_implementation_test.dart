import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_async/fake_async.dart';
import 'package:autobid_mobile/modules/lists/presentation/controllers/lists_controller.dart';
import 'package:autobid_mobile/modules/auth/presentation/controllers/kyc_registration_controller.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/get_seller_listings_usecase.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/stream_seller_listings_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/delete_listing_usecase.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/submission_usecases.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/send_email_otp_usecase.dart';

// Generate mocks
@GenerateMocks([
  GetSellerListingsUseCase,
  StreamSellerListingsUseCase,
  AuthRepository,
  DeleteDraftUseCase,
  DeleteListingUseCase,
  CancelListingUseCase,
  SharedPreferences,
  SendEmailOtpUseCase,
])
import 'features_implementation_test.mocks.dart';

void main() {
  group('ListsController Feature Test', () {
    late ListsController controller;
    late MockGetSellerListingsUseCase mockGetListings;
    late MockStreamSellerListingsUseCase mockStreamListings;
    late MockAuthRepository mockAuthRepo;
    late MockDeleteDraftUseCase mockDeleteDraft;
    late MockDeleteListingUseCase mockDeleteListing;
    late MockCancelListingUseCase mockCancelListing;

    setUp(() {
      mockGetListings = MockGetSellerListingsUseCase();
      mockStreamListings = MockStreamSellerListingsUseCase();
      mockAuthRepo = MockAuthRepository();
      mockDeleteDraft = MockDeleteDraftUseCase();
      mockDeleteListing = MockDeleteListingUseCase();
      mockCancelListing = MockCancelListingUseCase();

      controller = ListsController(
        mockGetListings,
        mockStreamListings,
        mockAuthRepo,
        mockDeleteDraft,
        mockDeleteListing,
        mockCancelListing,
      );
    });

    test('Initial showAll state should be false', () {
      expect(controller.showAll, false);
    });

    test('toggleShowAll should toggle the state', () {
      controller.toggleShowAll();
      expect(controller.showAll, true);

      controller.toggleShowAll();
      expect(controller.showAll, false);
    });
  });

  group('KYCRegistrationController Auto-Save Test', () {
    late KYCRegistrationController controller;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      
      // Mock SharedPreferences behavior
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
      when(mockPrefs.containsKey(any)).thenReturn(true);
      when(mockPrefs.getString(any)).thenReturn('{}'); // Empty json for mock load

      controller = KYCRegistrationController(
        sharedPreferences: mockPrefs,
      );
    });

    test('Setting firstName should trigger saveDraft after debounce', () {
      fakeAsync((async) {
        // Set value
        controller.setFirstName('John');
        
        // Immediately, setString should NOT have been called due to debounce
        verifyNever(mockPrefs.setString('kyc_registration_draft', any));

        // Advance time by 500ms (halfway)
        async.elapse(const Duration(milliseconds: 500));
        verifyNever(mockPrefs.setString('kyc_registration_draft', any));

        // Advance time to completion (1 second total)
        async.elapse(const Duration(milliseconds: 600));

        // Now it should have been called
        verify(mockPrefs.setString('kyc_registration_draft', any)).called(1);
      });
    });

    test('Rapid updates should debounce to single save', () {
      fakeAsync((async) {
        controller.setFirstName('J');
        async.elapse(const Duration(milliseconds: 100));
        
        controller.setFirstName('Jo');
        async.elapse(const Duration(milliseconds: 100));
        
        controller.setFirstName('Joh');
        async.elapse(const Duration(milliseconds: 100));
        
        controller.setFirstName('John');
        
        // Should not have saved yet
        verifyNever(mockPrefs.setString('kyc_registration_draft', any));

        // Advance time by 1s
        async.elapse(const Duration(seconds: 1));

        // Should have saved ONCE
        verify(mockPrefs.setString('kyc_registration_draft', any)).called(1);
      });
    });
  });
}
