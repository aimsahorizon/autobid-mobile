import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide TokenType;
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/services/stripe_service.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../data/datasources/deposit_supabase_datasource.dart';

/// Deposit payment page for auction participation
class DepositPaymentPage extends StatefulWidget {
  final String auctionId;
  final String userId;
  final double depositAmount;
  final VoidCallback onSuccess;

  const DepositPaymentPage({
    super.key,
    required this.auctionId,
    required this.userId,
    required this.depositAmount,
    required this.onSuccess,
  });

  @override
  State<DepositPaymentPage> createState() => _DepositPaymentPageState();
}

class _DepositPaymentPageState extends State<DepositPaymentPage> {
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
        amount: widget.depositAmount,
        currency: 'PHP',
        description: 'Auction Participation Deposit',
        metadata: {
          'auction_id': widget.auctionId,
          'user_id': widget.userId,
          'type': 'auction_deposit',
        },
      );

      final clientSecret = paymentIntent['client_secret'] as String;
      final paymentIntentId = paymentIntent['id'] as String;

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

      // Step 4: Record deposit in database
      final datasource = DepositSupabaseDatasource(
        supabase: SupabaseConfig.client,
      );

      final depositId = await datasource.createDeposit(
        auctionId: widget.auctionId,
        userId: widget.userId,
        amount: widget.depositAmount,
        paymentIntentId: paymentIntentId,
      );

      if (depositId == null) {
        throw Exception('Failed to record deposit in database');
      }

      // Payment and deposit record successful
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deposit payment successful! You can now participate in this auction.'),
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
        title: const Text('Auction Deposit'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Deposit info card
              Container(
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ColorConstants.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.gavel,
                            color: ColorConstants.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auction Deposit',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Required to participate in bidding',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₱${_formatPrice(widget.depositAmount)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: ColorConstants.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight),
                    const SizedBox(height: 16),
                    Text(
                      'Deposit Terms',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.check_circle_outline, 'Fully refundable if you don\'t win'),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.check_circle_outline, 'Applied to purchase if you win'),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.warning_amber_rounded, 'Forfeited if winner doesn\'t complete purchase'),
                  ],
                ),
              ),
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
                          'Pay Deposit ₱${_formatPrice(widget.depositAmount)}',
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ColorConstants.success),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
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
}
