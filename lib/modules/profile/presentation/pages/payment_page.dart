import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/services/paymongo_service.dart';
import 'package:autobid_mobile/core/services/paymongo_mock_service.dart';
import '../../domain/entities/pricing_entity.dart';

/// Payment page for processing token package purchases
class PaymentPage extends StatefulWidget {
  final TokenPackageEntity package;
  final String userId;
  final VoidCallback onSuccess;

  const PaymentPage({
    super.key,
    required this.package,
    required this.userId,
    required this.onSuccess,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethodType _selectedMethod = PaymentMethodType.card;
  bool _isProcessing = false;
  bool _useDemoMode = true; // Toggle between demo and real API

  // Card form fields
  final _cardNumberController = TextEditingController();
  final _expMonthController = TextEditingController();
  final _expYearController = TextEditingController();
  final _cvcController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expMonthController.dispose();
    _expYearController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
      // Use mock service in demo mode, real service otherwise
      final paymongoService = _useDemoMode
          ? PayMongoMockService()
          : PayMongoService();

      if (_selectedMethod == PaymentMethodType.card) {
        await _processCardPayment(paymongoService);
      } else {
        await _processEWalletPayment(paymongoService);
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

  Future<void> _processCardPayment(PayMongoService service) async {
    // Step 1: Create payment intent
    final paymentIntent = await service.createPaymentIntent(
      amount: widget.package.price,
      description: widget.package.description,
      metadata: {
        'user_id': widget.userId,
        'package_id': widget.package.id,
        'tokens': widget.package.tokens,
        'bonus_tokens': widget.package.bonusTokens,
      },
    );

    final paymentIntentId = paymentIntent['data']['id'] as String;
    final clientKey = paymentIntent['data']['attributes']['client_key'] as String;

    // Step 2: Create payment method
    final paymentMethod = await service.createPaymentMethod(
      cardNumber: _cardNumberController.text.replaceAll(' ', ''),
      expMonth: int.parse(_expMonthController.text),
      expYear: int.parse(_expYearController.text),
      cvc: _cvcController.text,
      billingName: _nameController.text,
      billingEmail: _emailController.text,
      billingPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
    );

    final paymentMethodId = paymentMethod['data']['id'] as String;

    // Step 3: Attach payment method to payment intent
    final result = await service.attachPaymentMethod(
      paymentIntentId: paymentIntentId,
      paymentMethodId: paymentMethodId,
      clientKey: clientKey,
    );

    final status = result['data']['attributes']['status'] as String;

    if (status == 'succeeded') {
      // Payment successful
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: ColorConstants.success,
          ),
        );
        widget.onSuccess();
        Navigator.pop(context, true);
      }
    } else if (status == 'awaiting_next_action') {
      // 3D Secure authentication required
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('3D Secure authentication required. Please check your email or SMS.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } else {
      throw Exception('Payment failed with status: $status');
    }
  }

  Future<void> _processEWalletPayment(PayMongoService service) async {
    // Create source for e-wallet payment
    final source = await service.createSource(
      amount: widget.package.price,
      type: _selectedMethod.value,
      redirectSuccessUrl: 'autobid://payment/success',
      redirectFailedUrl: 'autobid://payment/failed',
      metadata: {
        'user_id': widget.userId,
        'package_id': widget.package.id,
        'tokens': widget.package.tokens,
        'bonus_tokens': widget.package.bonusTokens,
      },
    );

    final checkoutUrl = source['data']['attributes']['redirect']['checkout_url'] as String;

    // TODO: Open checkout URL in webview or browser
    // For now, show a dialog with the URL
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Complete Payment in ${_selectedMethod.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You will be redirected to complete your payment.'),
              const SizedBox(height: 16),
              SelectableText(
                checkoutUrl,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // TODO: Launch URL
                Navigator.pop(context);
              },
              child: const Text('Open'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        actions: [
          // Demo mode toggle
          PopupMenuButton<String>(
            icon: Icon(
              _useDemoMode ? Icons.science_outlined : Icons.cloud_outlined,
              color: _useDemoMode ? ColorConstants.warning : ColorConstants.success,
            ),
            tooltip: _useDemoMode ? 'Demo Mode (Simulated)' : 'Live Mode (Real API)',
            onSelected: (value) {
              if (value == 'toggle') {
                setState(() {
                  _useDemoMode = !_useDemoMode;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _useDemoMode
                          ? 'Switched to Demo Mode - Payments will be simulated'
                          : 'Switched to Live Mode - Real payments will be processed',
                    ),
                    backgroundColor: _useDemoMode
                        ? ColorConstants.warning
                        : ColorConstants.success,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      _useDemoMode ? Icons.cloud_outlined : Icons.science_outlined,
                      color: _useDemoMode ? ColorConstants.success : ColorConstants.warning,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _useDemoMode
                          ? 'Switch to Live Mode'
                          : 'Switch to Demo Mode',
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Mode:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _useDemoMode ? 'Demo (Simulated)' : 'Live (Real API)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _useDemoMode
                            ? ColorConstants.warning
                            : ColorConstants.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo mode banner
              if (_useDemoMode) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorConstants.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ColorConstants.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        color: ColorConstants.warning,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demo Mode Active',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: ColorConstants.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Payment will be simulated. No real charges will be made.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Package summary
              _buildPackageSummary(theme, isDark),
              const SizedBox(height: 32),

              // Payment method selection
              Text(
                'Select Payment Method',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentMethodSelector(),
              const SizedBox(height: 32),

              // Payment form
              if (_selectedMethod == PaymentMethodType.card) ...[
                _buildCardForm(theme),
              ] else ...[
                _buildEWalletInfo(theme),
              ],
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
                      'Secured by PayMongo',
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

  Widget _buildPaymentMethodSelector() {
    return Column(
      children: [
        _PaymentMethodTile(
          type: PaymentMethodType.card,
          isSelected: _selectedMethod == PaymentMethodType.card,
          onTap: () => setState(() => _selectedMethod = PaymentMethodType.card),
        ),
        const SizedBox(height: 12),
        _PaymentMethodTile(
          type: PaymentMethodType.gcash,
          isSelected: _selectedMethod == PaymentMethodType.gcash,
          onTap: () => setState(() => _selectedMethod = PaymentMethodType.gcash),
        ),
        const SizedBox(height: 12),
        _PaymentMethodTile(
          type: PaymentMethodType.paymaya,
          isSelected: _selectedMethod == PaymentMethodType.paymaya,
          onTap: () => setState(() => _selectedMethod = PaymentMethodType.paymaya),
        ),
        const SizedBox(height: 12),
        _PaymentMethodTile(
          type: PaymentMethodType.grabPay,
          isSelected: _selectedMethod == PaymentMethodType.grabPay,
          onTap: () => setState(() => _selectedMethod = PaymentMethodType.grabPay),
        ),
      ],
    );
  }

  Widget _buildCardForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Card number
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            prefixIcon: Icon(Icons.credit_card),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            }
            if (value.replaceAll(' ', '').length < 13) {
              return 'Please enter valid card number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Expiry and CVC
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expMonthController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: const InputDecoration(
                  labelText: 'MM',
                  hintText: '12',
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
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _expYearController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  labelText: 'YYYY',
                  hintText: '2025',
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
            const SizedBox(width: 12),
            Expanded(
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
        const SizedBox(height: 24),

        // Billing information
        Text(
          'Billing Information',
          style: theme.textTheme.titleMedium?.copyWith(
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
            labelText: 'Phone Number (Optional)',
            hintText: '+639171234567',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildEWalletInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.info.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: ColorConstants.info,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'You will be redirected to ${_selectedMethod.displayName} to complete your payment.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please make sure you have the ${_selectedMethod.displayName} app installed on your device.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethodType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (type) {
      case PaymentMethodType.card:
        return Icons.credit_card;
      case PaymentMethodType.gcash:
        return Icons.account_balance_wallet;
      case PaymentMethodType.paymaya:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethodType.grabPay:
        return Icons.local_taxi_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ColorConstants.primary
                : (isDark ? ColorConstants.borderDark : ColorConstants.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getIcon(),
              color: isSelected ? ColorConstants.primary : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                type.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? ColorConstants.primary : null,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: ColorConstants.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Card number formatter to add spaces every 4 digits
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }

    final formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
