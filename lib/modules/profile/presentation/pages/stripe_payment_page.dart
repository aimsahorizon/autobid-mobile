import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide TokenType;
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/services/stripe_service.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../domain/entities/pricing_entity.dart';
import '../../data/datasources/pricing_supabase_datasource.dart';

/// Stripe payment page for processing token package purchases
class StripePaymentPage extends StatefulWidget {
  final TokenPackageEntity package;
  final String userId;
  final VoidCallback onSuccess;

  const StripePaymentPage({
    super.key,
    required this.package,
    required this.userId,
    required this.onSuccess,
  });

  @override
  State<StripePaymentPage> createState() => _StripePaymentPageState();
}

class _StripePaymentPageState extends State<StripePaymentPage> {
  final _stripeService = StripeService();
  bool _isProcessing = false;

  // Billing form fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Step 1: Create payment intent
      final paymentIntent = await _stripeService.createPaymentIntent(
        amount: widget.package.price,
        currency: 'PHP',
        description: widget.package.description,
        metadata: {
          'user_id': widget.userId,
          'package_id': widget.package.id,
          'tokens': widget.package.tokens.toString(),
          'bonus_tokens': widget.package.bonusTokens.toString(),
        },
      );

      final clientSecret = paymentIntent['client_secret'] as String;

      // Step 2: Present payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'AutoBid',
          billingDetails: BillingDetails(
            name: _nameController.text,
            email: _emailController.text,
          ),
          style: Theme.of(context).brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
        ),
      );

      // Step 3: Display payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Step 4: Credit tokens to user account
      final datasource = PricingSupabaseDatasource(
        supabase: SupabaseConfig.client,
      );

      // Determine token type
      final tokenType = widget.package.type == TokenType.bidding ? 'bidding' : 'listing';

      // Calculate total tokens (base + bonus)
      final totalTokens = widget.package.tokens + widget.package.bonusTokens;

      // Add tokens to user account
      final success = await datasource.addTokens(
        userId: widget.userId,
        tokenType: tokenType,
        amount: totalTokens,
        price: widget.package.price,
        transactionType: 'purchase',
      );

      if (!success) {
        throw Exception('Failed to credit tokens to account');
      }

      // Payment and token credit successful
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! $totalTokens $tokenType tokens added to your account.'),
            backgroundColor: ColorConstants.success,
            duration: const Duration(seconds: 4),
          ),
        );
        widget.onSuccess();
        Navigator.pop(context, true);
      }
    } on StripeException catch (e) {
      if (mounted) {
        String errorMessage = 'Payment failed';
        if (e.error.code == FailureCode.Canceled) {
          errorMessage = 'Payment canceled';
        } else if (e.error.message != null) {
          errorMessage = e.error.message!;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: ColorConstants.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: ColorConstants.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package summary
              _buildPackageSummary(theme, isDark),
              const SizedBox(height: 32),

              // Billing information
              Text(
                'Billing Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Juan Dela Cruz',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'juan@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Test cards info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorConstants.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorConstants.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.credit_card,
                          color: ColorConstants.info,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Test Cards',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTestCardRow('✅ Success:', '4242 4242 4242 4242', theme),
                    const SizedBox(height: 4),
                    _buildTestCardRow('🔐 3D Secure:', '4000 0025 0000 3155', theme),
                    const SizedBox(height: 4),
                    _buildTestCardRow('❌ Declined:', '4000 0000 0000 0002', theme),
                    const SizedBox(height: 8),
                    Text(
                      'Any future expiry (12/34), any CVC (123)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Pay button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Pay ₱${_formatPrice(widget.package.price)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Security notice
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Secured by Stripe',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestCardRow(String label, String number, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            number,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageSummary(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.package.type == TokenType.bidding
                      ? Icons.gavel
                      : Icons.format_list_bulleted,
                  color: ColorConstants.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.package.description,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.package.bonusTokens > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${widget.package.bonusTokens} bonus tokens',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ColorConstants.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '₱${_formatPrice(widget.package.price)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: ColorConstants.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
