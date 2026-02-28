import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:autobid_mobile/core/controllers/network_status_controller.dart';
import 'package:autobid_mobile/core/widgets/offline_banner.dart';
import 'package:autobid_mobile/core/controllers/theme_controller.dart';
import 'package:autobid_mobile/core/theme/app_theme.dart';
import 'package:autobid_mobile/core/utils/navigator_key.dart';
import 'package:autobid_mobile/core/widgets/session_timeout_manager.dart';
import 'router/app_router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final ThemeController _themeController = ThemeController();
  late final NetworkStatusController _networkController;

  @override
  void initState() {
    super.initState();
    _networkController = NetworkStatusController(GetIt.I<Connectivity>());
  }

  @override
  void dispose() {
    _themeController.dispose();
    _networkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        return SessionTimeoutManager(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'AutoBid',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            // DEPRECATED: Dark mode disabled - darkTheme still defined for future use
            darkTheme: AppTheme.darkTheme,
            // DEPRECATED: ThemeController now always returns ThemeMode.light
            themeMode: _themeController.themeMode, // Always light mode
            onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
              settings,
              themeController: _themeController,
            ),
            initialRoute: '/',
            builder: (context, child) {
              return Column(
                children: [
                  OfflineBanner(controller: _networkController),
                  Expanded(child: child ?? const SizedBox()),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
