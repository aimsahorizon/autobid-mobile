import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/core/config/supabase_config.dart';
import 'app/core/services/stripe_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with environment variables
  await SupabaseConfig.initialize();

  // Initialize Stripe
  await StripeService.init();

  runApp(const App());
}
