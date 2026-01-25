import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/controllers/theme_controller.dart';
import 'package:autobid_mobile/core/theme/app_theme.dart';
import 'router/app_router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final ThemeController _themeController = ThemeController();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'AutoBid',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeController.themeMode,
          onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
            settings,
            themeController: _themeController,
          ),
          initialRoute: '/',
        );
      },
    );
  }
}
