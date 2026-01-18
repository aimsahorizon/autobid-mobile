import 'package:flutter/material.dart';
import 'app/app.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/core/services/stripe_service.dart';
import 'app/di/app_module.dart';
import 'modules/transactions/transactions_module.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DI
  await initDependencies();

  // Initialize Supabase with environment variables
  await SupabaseConfig.initialize();

  // Initialize Stripe
  await StripeService.init();

  // Initialize Transactions module
  TransactionsModule.instance.initialize();

  runApp(const App());
}
