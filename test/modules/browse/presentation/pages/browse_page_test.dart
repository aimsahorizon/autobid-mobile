import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/browse/presentation/controllers/browse_controller.dart';
import 'package:autobid_mobile/modules/browse/presentation/pages/browse_page.dart';
import 'package:autobid_mobile/modules/notifications/presentation/controllers/notification_controller.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/auction_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'browse_page_test.mocks.dart';

@GenerateMocks([BrowseController, NotificationController])
void main() {
  late MockBrowseController mockBrowseController;
  late MockNotificationController mockNotificationController;

  setUp(() {
    mockBrowseController = MockBrowseController();
    mockNotificationController = MockNotificationController();

    GetIt.instance.registerSingleton<NotificationController>(
      mockNotificationController,
    );

    // Mock BrowseController behavior
    when(mockBrowseController.auctions).thenReturn([]);
    when(mockBrowseController.isLoading).thenReturn(false);
    when(mockBrowseController.hasError).thenReturn(false);
    when(mockBrowseController.errorMessage).thenReturn(null);
    when(mockBrowseController.hasActiveFilters).thenReturn(false);
    when(mockBrowseController.activeFilterCount).thenReturn(0);
    when(mockBrowseController.currentFilter).thenReturn(const AuctionFilter());
    when(mockBrowseController.loadAuctions()).thenAnswer((_) async {});

    // Mock NotificationController behavior
    when(mockNotificationController.unreadCount).thenReturn(0);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets('BrowsePage uses theme colors in dark mode', (tester) async {
    // Define a custom dark theme
    final darkTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1F1F1F)),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: darkTheme,
        themeMode: ThemeMode.dark, // Force dark mode
        home: BrowsePage(controller: mockBrowseController),
      ),
    );

    // Verify scaffold background color
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, equals(const Color(0xFF121212)));

    // Verify app bar title color (text style)
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final title = appBar.title as Text;
    // The title style uses theme.textTheme.titleLarge?.color
    // In dark theme, titleLarge color is usually white-ish.
    // We expect it NOT to be ColorConstants.textPrimaryLight (0xFF212121)
    expect(title.style?.color, isNot(equals(ColorConstants.textPrimaryLight)));
  });

  testWidgets('BrowsePage uses theme colors in light mode', (tester) async {
    final lightTheme = ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        themeMode: ThemeMode.light,
        home: BrowsePage(controller: mockBrowseController),
      ),
    );

    // Verify scaffold background color
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, equals(const Color(0xFFFAFAFA)));
  });
}
