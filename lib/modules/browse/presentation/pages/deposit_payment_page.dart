import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/services/paymongo_service.dart';
import 'package:autobid_mobile/core/services/paymongo_mock_service.dart';
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
  final _payMongoService = PayMongoService();
  bool _isProcessing = false;
  bool _useDemoMode = true; // Default to test environment

  // Billing form fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expMonthController = TextEditingController();
  final _expYearController = TextEditingController();
  final _cvcController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expMonthController.dispose();
    _expYearController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    // Use Mock service if in demo mode
    final service = _useDemoMode ? PayMongoMockService() : _payMongoService;

    try {
      // Step 1: Create payment intent
      final paymentIntent = await service.createPaymentIntent(
        amount: widget.depositAmount,
        description: 'Auction Participation Deposit',
        metadata: {
          'auction_id': widget.auctionId,
          'user_id': widget.userId,
          'type': 'auction_deposit',
        },
      );

      final paymentIntentId = paymentIntent['id'] as String;

      // Step 2: Create payment method (simplified - card only for now)
      final paymentMethod = await service.createPaymentMethod(
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        expMonth: int.parse(_expMonthController.text),
        expYear: int.parse(_expYearController.text),
        cvc: _cvcController.text,
        billingName: _nameController.text,
        billingEmail: _emailController.text,
        billingPhone: _phoneController.text.isNotEmpty
            ? _phoneController.text
            : null,
      );

      final paymentMethodId = paymentMethod['id'] as String;

      // Step 3: Attach payment method to payment intent
      final result = await service.attachPaymentMethod(
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
      );

      // Check payment status
      final status = result['attributes']['status'] as String;

      if (status != 'succeeded' && status != 'awaiting_payment_method') {
        throw PayMongoException('Payment failed with status: $status');
      }

      // Step 4: Record deposit in database
      final datasource = DepositSupabaseDataSource(SupabaseConfig.client);

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
            content: Text(
              'Deposit payment successful! You can now participate in this auction.',
            ),
            backgroundColor: ColorConstants.success,
            duration: const Duration(seconds: 4),
          ),
        );
        widget.onSuccess();
        Navigator.pop(context, true);
      }
    } on PayMongoException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
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
      appBar: AppBar(title: const Text('Auction Deposit')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo mode toggle
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _useDemoMode
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _useDemoMode ? Colors.orange : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bug_report_outlined,
                      color: _useDemoMode ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Use Demo Mode (No real API calls)',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch(
                      value: _useDemoMode,
                      onChanged: (value) =>
                          setState(() => _useDemoMode = value),
                      activeThumbColor: Colors.orange,
                    ),
                  ],
                ),
              ),

              // Deposit info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? ColorConstants.surfaceDark
                      : ColorConstants.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? ColorConstants.borderDark
                        : ColorConstants.borderLight,
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
                            color: ColorConstants.primary.withValues(
                              alpha: 0.1,
                            ),
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
                    Divider(
                      color: isDark
                          ? ColorConstants.borderDark
                          : ColorConstants.borderLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Deposit Terms',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.check_circle_outline,
                      'Fully refundable if you don\'t win',
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.check_circle_outline,
                      'Applied to purchase if you win',
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.warning_amber_rounded,
                      'Forfeited if winner doesn\'t complete purchase',
                    ),
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
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  hintText: '+639171234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Card Details Section
              Text(
                'Card Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                  LengthLimitingTextInputFormatter(19),
                ],
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '4343 4343 4343 4345',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card number';
                  }
                  final digits = value.replaceAll(' ', '');
                  if (digits.length < 13) {
                    return 'Card number too short';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _expMonthController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        hintText: 'MM',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final month = int.tryParse(value);
                        if (month == null || month < 1 || month > 12) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _expYearController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        hintText: 'YYYY',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final year = int.tryParse(value);
                        if (year == null || year < DateTime.now().year) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cvcController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'CVC',
                        hintText: '123',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 3) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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
                    _buildTestCardRow(
                      '✅ Success:',
                      '4343 4343 4343 4345',
                      theme,
                    ),
                    const SizedBox(height: 4),
                    _buildTestCardRow(
                      '🔐 3D Secure:',
                      '4571 7360 0000 0008',
                      theme,
                    ),
                    const SizedBox(height: 4),
                    _buildTestCardRow(
                      '❌ Generic Fail:',
                      '4571 7360 0000 0016',
                      theme,
                    ),
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
                    Text('Secured by PayMongo', style: theme.textTheme.bodySmall),
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
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
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
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}

// Card number formatter to add spaces every 4 digits
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
