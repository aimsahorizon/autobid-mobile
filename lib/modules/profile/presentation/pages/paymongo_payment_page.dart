import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/services/paymongo_service.dart';
import 'package:autobid_mobile/core/services/paymongo_mock_service.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/core/services/ipaymongo_service.dart';
import '../../domain/entities/pricing_entity.dart';
import '../../data/datasources/pricing_supabase_datasource.dart';

/// PayMongo payment page for processing token package purchases
class PayMongoPaymentPage extends StatefulWidget {
  final TokenPackageEntity package;
  final String userId;
  final VoidCallback onSuccess;

  const PayMongoPaymentPage({
    super.key,
    required this.package,
    required this.userId,
    required this.onSuccess,
  });

  @override
  State<PayMongoPaymentPage> createState() => _PayMongoPaymentPageState();
}

class _PayMongoPaymentPageState extends State<PayMongoPaymentPage> {
  final PayMongoService _payMongoService = PayMongoService();
  bool _isProcessing = false;
  bool _useDemoMode = true;

  // Form fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expMonthController = TextEditingController();
  final _expYearController = TextEditingController();
  final _cvcController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.card;

  @override
  void initState() {
    super.initState();
    // Default billing info from profile if available
    _nameController.text = 'Juan Dela Cruz';
    _emailController.text = 'juan@example.com';
  }

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
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    // Use Mock service if in demo mode
    final IPayMongoService service = _useDemoMode ? PayMongoMockService() : _payMongoService;

    try {
      if (_selectedPaymentMethod == PaymentMethodType.card) {
        await _processCardPayment(service);
      } else if (_selectedPaymentMethod == PaymentMethodType.gcash) {
        await _processGCashPayment(service);
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

  Future<void> _processCardPayment(IPayMongoService service) async {
    // Step 1: Create payment intent
    final paymentIntent = await service.createPaymentIntent(
      amount: widget.package.price,
      description: widget.package.description,
      metadata: {
        'user_id': widget.userId,
        'package_id': widget.package.id,
        'tokens': widget.package.tokens.toString(),
        'bonus_tokens': widget.package.bonusTokens.toString(),
      },
    );

    final paymentIntentId = paymentIntent['id'] as String;

    // Step 2: Create payment method
    final paymentMethod = await service.createPaymentMethod(
      cardNumber: _cardNumberController.text,
      expMonth: int.parse(_expMonthController.text),
      expYear: int.parse(_expYearController.text),
      cvc: _cvcController.text,
      billingName: _nameController.text,
      billingEmail: _emailController.text,
      billingPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
    );

    final paymentMethodId = paymentMethod['id'] as String;

    // Step 3: Attach payment method to payment intent
    final result = await service.attachPaymentMethod(
      paymentIntentId: paymentIntentId,
      paymentMethodId: paymentMethodId,
    );

    // Check payment status
    final status = result['attributes']['status'] as String;

    if (status == 'succeeded' || status == 'awaiting_payment_method' || status == 'awaiting_next_action') {
      // Step 4: Credit tokens to user account
      await _creditTokens();
    } else {
      throw PayMongoException('Payment failed with status: $status');
    }
  }

  Future<void> _processGCashPayment(IPayMongoService service) async {
    // ...
    // Step 1: Create payment intent
    final paymentIntent = await service.createPaymentIntent(
      amount: widget.package.price,
      description: widget.package.description,
      metadata: {
        'user_id': widget.userId,
        'package_id': widget.package.id,
        'tokens': widget.package.tokens.toString(),
        'bonus_tokens': widget.package.bonusTokens.toString(),
      },
    );

    final paymentIntentId = paymentIntent['id'] as String;

    // Step 2: Create GCash source
    final source = await service.createSource(
      type: 'gcash',
      amount: widget.package.price,
      redirectSuccessUrl: 'https://autobid.app/payment/success',
      redirectFailedUrl: 'https://autobid.app/payment/failed',
      metadata: {
        'user_id': widget.userId,
        'package_id': widget.package.id,
        'tokens': widget.package.tokens.toString(),
        'bonus_tokens': widget.package.bonusTokens.toString(),
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      },
    );

    final sourceId = source['id'] as String;
    final checkoutUrl =
        source['attributes']['redirect']['checkout_url'] as String;

    // Step 3: Open GCash checkout in browser (for now, show message)
    // TODO: Implement webview or external browser launch
    throw PayMongoException(
      'GCash payment requires browser redirect. Feature coming soon. Checkout URL: $checkoutUrl',
    );
  }

  Future<void> _creditTokens() async {
    final datasource = PricingSupabaseDatasource(
      supabase: SupabaseConfig.client,
    );

    // Determine token type
    final tokenType = widget.package.type == TokenType.bidding
        ? 'bidding'
        : 'listing';

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
          content: Text(
            'Payment successful! $totalTokens $tokenType tokens added to your account.',
          ),
          backgroundColor: ColorConstants.success,
          duration: const Duration(seconds: 4),
        ),
      );
      widget.onSuccess();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
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
                  color: _useDemoMode ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _useDemoMode ? Colors.orange : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bug_report_outlined, color: _useDemoMode ? Colors.orange : Colors.grey),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Use Demo Mode (No real API calls)',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch(
                      value: _useDemoMode,
                      onChanged: (value) => setState(() => _useDemoMode = value),
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ),

              // Package summary
              _buildPackageSummary(theme, isDark),
              const SizedBox(height: 32),

              // Payment method selection
              Text(
                'Payment Method',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentMethodSelector(isDark),
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
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: _selectedPaymentMethod == PaymentMethodType.gcash
                      ? 'Phone'
                      : 'Phone (Optional)',
                  hintText: '+639123456789',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (_selectedPaymentMethod == PaymentMethodType.gcash) {
                    if (value == null || value.isEmpty) {
                      return 'Phone is required for GCash';
                    }
                    if (!value.startsWith('+63') && !value.startsWith('09')) {
                      return 'Enter valid PH number (+63 or 09)';
                    }
                  }
                  return null;
                },
              ),

              // Card details (only for card payment)
              if (_selectedPaymentMethod == PaymentMethodType.card) ...[
                const SizedBox(height: 32),
                Text(
                  'Card Details',
                  style: theme.textTheme.titleLarge?.copyWith(
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
                    LengthLimitingTextInputFormatter(
                      19,
                    ), // 16 digits + 3 spaces
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
                    final digitsOnly = value.replaceAll(' ', '');
                    if (digitsOnly.length < 13 || digitsOnly.length > 19) {
                      return 'Please enter a valid card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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
                    const SizedBox(width: 16),
                    Expanded(
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
                    const SizedBox(width: 16),
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
              ],

              // Test cards info
              if (_selectedPaymentMethod == PaymentMethodType.card) ...[
                const SizedBox(height: 24),
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
                            'PayMongo Test Cards',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTestCardRow('✅ Visa:', '4111 1111 1111 1111', theme),
                      const SizedBox(height: 4),
                      _buildTestCardRow('✅ Mastercard:', '5555 5555 5555 4444', theme),
                      const SizedBox(height: 8),
                      Text(
                        'Any future expiry, any 3-digit CVC',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Pay button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Secured by PayMongo',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.package.tokens} ${widget.package.type == TokenType.bidding ? 'Bidding' : 'Listing'} Tokens',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ColorConstants.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.package.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Base Tokens',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '${widget.package.tokens}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (widget.package.bonusTokens > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonus',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorConstants.success,
                      ),
                    ),
                    Text(
                      '+${widget.package.bonusTokens}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.success,
                      ),
                    ),
                  ],
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '₱${_formatPrice(widget.package.price)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector(bool isDark) {
    return Column(
      children: [
        _buildPaymentMethodOption(
          PaymentMethodType.card,
          Icons.credit_card,
          isDark,
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodOption(
          PaymentMethodType.gcash,
          Icons.account_balance_wallet,
          isDark,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(
    PaymentMethodType type,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedPaymentMethod == type;

    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentMethod = type);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? ColorConstants.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ColorConstants.primary
                : (isDark ? ColorConstants.surfaceLight : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? ColorConstants.primary : Colors.grey,
            ),
            const SizedBox(width: 16),
            Text(
              type.displayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? ColorConstants.primary : null,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: ColorConstants.primary),
          ],
        ),
      ),
    );
  }
}

/// Custom formatter for card numbers (adds space every 4 digits)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
