import 'package:autobid_mobile/modules/lists/presentation/widgets/listing_form/step8_final_details.dart';
import 'package:autobid_mobile/modules/lists/presentation/controllers/listing_draft_controller.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/listing_draft_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'step8_final_details_test.mocks.dart';

@GenerateMocks([ListingDraftController])
void main() {
  late MockListingDraftController mockController;

  setUp(() {
    mockController = MockListingDraftController();
    
    // Default stubs
    when(mockController.currentDraft).thenReturn(
      ListingDraftEntity(
        id: 'draft1',
        sellerId: 'user1',
        currentStep: 8,
        lastSaved: DateTime.now(),
      ),
    );
  });

  Widget createWidget() {
    return MaterialApp(
      home: Scaffold(
        body: Step8FinalDetails(controller: mockController),
      ),
    );
  }

  testWidgets('Validation fails if starting price >= reserve price', (tester) async {
    // Set screen size large enough to avoid scrolling issues
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidget());
    await tester.pump(); // Allow init

    // Verify we are on the page
    expect(find.text('Step 8: Final Details & Bidding Configuration'), findsOneWidget);

    // Debug: Print all text to see what matches
    // debugDumpApp();

    // Use a more robust finder that looks for the text field by checking ancestor/descendants if standard finder fails
    // Or just find by input type and index if text matching is tricky
    // Index 0: Description
    // Index 1: Known Issues
    // Index 2: Features
    // Index 3: Starting Price (if AI predictor doesn't add fields)
    // Index 4: Reserve Price
    
    // Let's try to find by specific label text logic
    // Assuming FormFieldWidget puts label in InputDecorator or similar
    // We will search for the TextField that has the specific label in its decoration
    
    Finder findFieldByLabel(String label) {
      return find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          final decoration = widget.decoration;
          return decoration?.labelText == label;
        }
        return false;
      });
    }

    final startingPriceField = findFieldByLabel('Starting Price (₱) *');
    final reservePriceField = findFieldByLabel('Reserve Price (₱)');
    
    // Ensure visible
    await tester.ensureVisible(startingPriceField);
    await tester.ensureVisible(reservePriceField);

    // Enter invalid values (Start > Reserve)
    await tester.enterText(startingPriceField, '500000');
    await tester.enterText(reservePriceField, '400000');
    await tester.pump();

    // Validate
    // Find the FormFieldState (TextFormFieldState) that wraps the TextField
    final startFormFieldFinder = find.ancestor(of: startingPriceField, matching: find.byType(TextFormField));
    final startState = tester.state<FormFieldState>(startFormFieldFinder);
    startState.validate();
    await tester.pump();
    
    expect(find.text('Must be lower than reserve price'), findsOneWidget);
    
    final reserveFormFieldFinder = find.ancestor(of: reservePriceField, matching: find.byType(TextFormField));
    final reserveState = tester.state<FormFieldState>(reserveFormFieldFinder);
    reserveState.validate();
    await tester.pump();
    
    expect(find.text('Must be higher than starting price'), findsOneWidget);
  });

  testWidgets('Validation passes if starting price < reserve price', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidget());
    await tester.pump();

    Finder findFieldByLabel(String label) {
      return find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          final decoration = widget.decoration;
          return decoration?.labelText == label;
        }
        return false;
      });
    }

    final startingPriceField = findFieldByLabel('Starting Price (₱) *');
    final reservePriceField = findFieldByLabel('Reserve Price (₱)');
    
    await tester.ensureVisible(startingPriceField);
    await tester.ensureVisible(reservePriceField);

    await tester.enterText(startingPriceField, '400000');
    await tester.enterText(reservePriceField, '500000');
    await tester.pump();

    final startFormFieldFinder = find.ancestor(of: startingPriceField, matching: find.byType(TextFormField));
    final startState = tester.state<FormFieldState>(startFormFieldFinder);
    final isValidStart = startState.validate();
    
    final reserveFormFieldFinder = find.ancestor(of: reservePriceField, matching: find.byType(TextFormField));
    final reserveState = tester.state<FormFieldState>(reserveFormFieldFinder);
    final isValidReserve = reserveState.validate();
    
    await tester.pump();

    expect(isValidStart, true);
    expect(isValidReserve, true);
    expect(find.text('Must be lower than reserve price'), findsNothing);
    expect(find.text('Must be higher than starting price'), findsNothing);
  });
}
