import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/modules/auth/auth_routes.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Artificial delay to show splash logo (and allow async initialization to settle if needed)
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final session = SupabaseConfig.client.auth.currentSession;
    if (session != null) {
      try {
        final userId = session.user.id;
        final authRepo = GetIt.I<AuthRepository>();
        final result = await authRepo.getKycRegistrationStatus(userId);

        if (!mounted) return;

        await result.fold(
          (failure) async {
            // If failed to verify status (e.g. network), force logout to be safe
            // or redirect to login to retry.
            await SupabaseConfig.client.auth.signOut();
            if (mounted) {
              Navigator.of(context).pushReplacementNamed(AuthRoutes.login);
            }
          },
          (kycData) async {
            // Check if user is approved
            if (kycData != null && kycData.status == 'approved') {
              Navigator.of(context).pushReplacementNamed('/home');
            } else {
              // Unverified, Pending, or Rejected - Force Logout
              await SupabaseConfig.client.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(AuthRoutes.login);
              }
            }
          },
        );
      } catch (e) {
        // Fallback for any unexpected errors
        await SupabaseConfig.client.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AuthRoutes.login);
        }
      }
    } else {
      Navigator.of(context).pushReplacementNamed(AuthRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for Logo
            Icon(Icons.directions_car_filled_rounded, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
