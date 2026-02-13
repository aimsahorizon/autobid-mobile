import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:autobid_mobile/modules/auth/presentation/controllers/kyc_registration_controller.dart';
import 'package:autobid_mobile/core/services/ai_id_extraction_service.dart';

// Generate Mock
@GenerateMocks([IAiIdExtractionService, File])
import 'kyc_controller_test.mocks.dart';

void main() {
  late KYCRegistrationController controller;
  late MockIAiIdExtractionService mockAiService;
  late MockFile mockFile;

  setUp(() {
    mockAiService = MockIAiIdExtractionService();
    mockFile = MockFile();
    
    // Inject mock service
    controller = KYCRegistrationController(
      aiService: mockAiService,
    );
  });

  group('KYCRegistrationController ID Extraction', () {
    test('extractDataFromIds handles error gracefully', () async {
      // Arrange
      controller.setNationalIdFront(mockFile);
      controller.setSecondaryIdFront(mockFile);
      
      when(mockAiService.extractFromSecondaryId(
        secondaryIdFront: anyNamed('secondaryIdFront'),
        secondaryIdBack: anyNamed('secondaryIdBack'),
        nationalIdFront: anyNamed('nationalIdFront'),
        nationalIdBack: anyNamed('nationalIdBack'),
      )).thenThrow(Exception('OCR Failed'));

      // Act
      final result = await controller.extractDataFromIds();

      // Assert
      expect(result.hasData, false); // Should return empty data
      expect(controller.errorMessage, contains('OCR Failed')); // Should set error message
      expect(controller.isLoading, false); // Should reset loading state
    });

    test('extractDataFromIds populates fields on success', () async {
       // Arrange
      controller.setNationalIdFront(mockFile);
      controller.setSecondaryIdFront(mockFile);
      
      final mockData = ExtractedIdData(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        idNumber: '123-456',
      );

      when(mockAiService.extractFromSecondaryId(
        secondaryIdFront: anyNamed('secondaryIdFront'),
        secondaryIdBack: anyNamed('secondaryIdBack'),
        nationalIdFront: anyNamed('nationalIdFront'),
        nationalIdBack: anyNamed('nationalIdBack'),
      )).thenAnswer((_) async => mockData);

      // Act
      await controller.extractDataFromIds();

      // Assert
      expect(controller.firstName, 'Juan');
      expect(controller.lastName, 'Dela Cruz');
      expect(controller.errorMessage, null);
    });
  });
}
