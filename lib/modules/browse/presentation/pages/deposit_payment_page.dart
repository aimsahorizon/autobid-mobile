import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/services/paymongo_service.dart';
import 'package:autobid_mobile/core/services/paymongo_mock_service.dart';
import 'package:autobid_mobile/core/services/ipaymongo_service.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../data/datasources/deposit_supabase_datasource.dart';

/// Deposit payment page for auction participation
class DepositPaymentPage extends StatefulWidget {
  final String auctionId;
  final String userId;
  final double depositAmount;
  final VoidCallback onSuccess;

  // Dependencies for testing
  final IPayMongoService? payMongoService;
  final DepositSupabaseDataSource? depositDataSource;

  const DepositPaymentPage({
    super.key,
    required this.auctionId,
    required this.userId,
    required this.depositAmount,
    required this.onSuccess,
    this.payMongoService,
    this.depositDataSource,
  });

  @override
  State<DepositPaymentPage> createState() => _DepositPaymentPageState();
}

class _DepositPaymentPageState extends State<DepositPaymentPage> {
  late final IPayMongoService _payMongoService;
  late final DepositSupabaseDataSource _depositDataSource;
  bool _isProcessing = false;

  // Billing form fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expMonthController = TextEditingController();
  final _expYearController = TextEditingController();
  final _cvcController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Focus Nodes
  final _monthFocus = FocusNode();
  final _yearFocus = FocusNode();
  final _cvcFocus = FocusNode();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();

    // Logic to determine which service to use
    if (widget.payMongoService != null) {
      _payMongoService = widget.payMongoService!;
    } else {
      // In debug mode, if keys are missing, use Mock
      final hasKeys = (dotenv.env['PAYMONGO_SECRET_KEY']?.isNotEmpty ?? false);
      if (kDebugMode && !hasKeys) {
        _payMongoService = PayMongoMockService();
        debugPrint(
          '[DepositPaymentPage] Using PayMongoMockService (Keys missing in .env)',
        );
      } else {
        _payMongoService = PayMongoService();
      }
    }

    _depositDataSource =
        widget.depositDataSource ??
        DepositSupabaseDataSource(SupabaseConfig.client);

    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final currentUser = SupabaseConfig.client.auth.currentUser;
      final fallbackEmail = currentUser?.email ?? '';
      final fallbackPhone = currentUser?.phone ?? '';

      // Try to get name from metadata if available
      final metadata = currentUser?.userMetadata;
      final metaFirstName = metadata?['first_name'] as String? ?? '';
      final metaLastName = metadata?['last_name'] as String? ?? '';
      final metaName = '$metaFirstName $metaLastName'.trim();

      final response = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          String firstName = '';
          String lastName = '';
          String email = fallbackEmail;
          String phone = fallbackPhone;

          if (response != null) {
            firstName = response['first_name'] as String? ?? metaFirstName;
            lastName = response['last_name'] as String? ?? metaLastName;

            // Use profile email if available, otherwise fallback
            if (response['email'] != null &&
                (response['email'] as String).isNotEmpty) {
              email = response['email'] as String;
            }

            // Check both phone_number (schema) and contact_number (legacy/view)
            final profilePhone =
                response['phone_number'] as String? ??
                response['contact_number'] as String?;
            if (profilePhone != null && profilePhone.isNotEmpty) {
              phone = profilePhone;
            }
          }

          if (_nameController.text.isEmpty) {
            final profileName = '$firstName $lastName'.trim();
            // Fallback chain: first+last → display_name → full_name → auth metadata
            final displayName = (response?['display_name'] as String? ?? '')
                .trim();
            final fullName = (response?['full_name'] as String? ?? '').trim();
            if (profileName.isNotEmpty) {
              _nameController.text = profileName;
            } else if (displayName.isNotEmpty) {
              _nameController.text = displayName;
            } else if (fullName.isNotEmpty) {
              _nameController.text = fullName;
            } else {
              _nameController.text = metaName;
            }
          }
          if (_emailController.text.isEmpty && email.isNotEmpty) {
            _emailController.text = email;
          }
          if (_phoneController.text.isEmpty && phone.isNotEmpty) {
            _phoneController.text = phone;
          }
        });

        // If name is still empty, try the users table as final fallback
        if (_nameController.text.isEmpty) {
          try {
            final userResp = await SupabaseConfig.client
                .from('users')
                .select('display_name, full_name')
                .eq('id', widget.userId)
                .maybeSingle();
            if (mounted && userResp != null && _nameController.text.isEmpty) {
              final dn = (userResp['display_name'] as String? ?? '').trim();
              final fn = (userResp['full_name'] as String? ?? '').trim();
              if (dn.isNotEmpty || fn.isNotEmpty) {
                setState(() {
                  _nameController.text = dn.isNotEmpty ? dn : fn;
                });
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[DepositPaymentPage] Error loading user profile: $e');
      // Fallback to auth data if profile load fails
      if (mounted) {
        final currentUser = SupabaseConfig.client.auth.currentUser;
        if (currentUser != null) {
          setState(() {
            if (_emailController.text.isEmpty && currentUser.email != null) {
              _emailController.text = currentUser.email!;
            }
            if (_phoneController.text.isEmpty && currentUser.phone != null) {
              _phoneController.text = currentUser.phone!;
            }
          });
        }
      }
    }
  }

  void _useMockService() {
    setState(() {
      _payMongoService = PayMongoMockService();
      _autoFillTestCard('4343 4343 4343 4345');
    });
    (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
      const SnackBar(content: Text('Switched to Mock Payment Service (Debug)')),
    );
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
    _monthFocus.dispose();
    _yearFocus.dispose();
    _cvcFocus.dispose();
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
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Step 1: Create payment intent
      final paymentIntent = await _payMongoService.createPaymentIntent(
        amount: widget.depositAmount,
        description: 'Auction Participation Deposit',
        metadata: {
          'auction_id': widget.auctionId,
          'user_id': widget.userId,
          'type': 'auction_deposit',
        },
      );

      final paymentIntentId = paymentIntent['id'] as String;
      final clientKey = paymentIntent['attributes']['client_key'] as String?;

      // Convert 2-digit year to 4-digit
      final twoDigitYear = _expYearController.text;
      final fullYear = int.parse('20$twoDigitYear');

      // Step 2: Create payment method (simplified - card only for now)
      final paymentMethod = await _payMongoService.createPaymentMethod(
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        expMonth: int.parse(_expMonthController.text),
        expYear: fullYear,
        cvc: _cvcController.text,
        billingName: _nameController.text,
        billingEmail: _emailController.text,
        billingPhone: _phoneController.text.isNotEmpty
            ? _phoneController.text
            : null,
      );

      final paymentMethodId = paymentMethod['id'] as String;

      // Step 3: Attach payment method to payment intent
      final result = await _payMongoService.attachPaymentMethod(
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
        clientKey: clientKey,
        returnUrl: 'https://autobid.app/payment/redirect',
      );

      // Check payment status
      final status = result['attributes']['status'] as String;

      if (status == 'awaiting_next_action') {
        // 3DS authentication required - get the redirect URL
        final nextAction =
            result['attributes']['next_action'] as Map<String, dynamic>?;
        final redirectUrl = nextAction?['redirect']?['url'] as String?;
        if (redirectUrl != null && mounted) {
          // For now, inform the user that 3DS is not supported in-app
          // In production, you'd open a WebView for 3DS authentication
          throw PayMongoException(
            'This card requires 3D Secure authentication. '
            'Please use a non-3DS test card (Visa: 4343 4343 4343 4345).',
          );
        }
      }

      if (status != 'succeeded' && status != 'awaiting_payment_method') {
        throw PayMongoException('Payment failed with status: $status');
      }

      // Step 4: Record deposit in database
      final depositId = await _depositDataSource.createDeposit(
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
        (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
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
        (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: ColorConstants.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
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

  void _autoFillTestCard(String cardNumber) {
    setState(() {
      _nameController.text = 'Juan Dela Cruz';
      _emailController.text = 'juan@example.com';
      _phoneController.text = '+639171234567';
      _cardNumberController.text = cardNumber;
      _expMonthController.text = '12';
      _expYearController.text = '30';
      _cvcController.text = '123';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Auction Deposit')),

      body: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
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

                  autofillHints: const [AutofillHints.name],

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

                  autofillHints: const [AutofillHints.email],

                  decoration: const InputDecoration(
                    labelText: 'Email',

                    hintText: 'juan@example.com',

                    prefixIcon: Icon(Icons.email_outlined),
                  ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }

                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,

                  keyboardType: TextInputType.phone,

                  autofillHints: const [AutofillHints.telephoneNumber],

                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',

                    hintText: '+639171234567',

                    prefixIcon: Icon(Icons.phone_outlined),
                  ),

                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digits.length < 10) {
                        return 'Phone number is too short';
                      }
                    }
                    return null;
                  },
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

                  autofillHints: const [AutofillHints.creditCardNumber],

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

                    if (digits.length < 13 || digits.length > 19) {
                      return 'Enter a valid card number (13-19 digits)';
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

                        focusNode: _monthFocus,

                        keyboardType: TextInputType.number,

                        autofillHints: const [
                          AutofillHints.creditCardExpirationMonth,
                        ],

                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,

                          LengthLimitingTextInputFormatter(2),
                        ],

                        decoration: const InputDecoration(
                          labelText: 'Month',

                          hintText: 'MM',
                        ),

                        onChanged: (value) {
                          if (value.length == 2) {
                            _yearFocus.requestFocus();
                          }
                        },

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
                      flex: 2,

                      child: TextFormField(
                        controller: _expYearController,

                        focusNode: _yearFocus,

                        keyboardType: TextInputType.number,

                        autofillHints: const [
                          AutofillHints.creditCardExpirationYear,
                        ],

                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,

                          LengthLimitingTextInputFormatter(2),
                        ],

                        decoration: const InputDecoration(
                          labelText: 'Year',

                          hintText: 'YY',
                        ),

                        onChanged: (value) {
                          if (value.length == 2) {
                            _cvcFocus.requestFocus();
                          }
                        },

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }

                          if (value.length != 2) return 'Invalid';

                          // Simple validation: assumed 20xx

                          // PayMongo handles actual expiration check

                          return null;
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      flex: 3,

                      child: TextFormField(
                        controller: _cvcController,

                        focusNode: _cvcFocus,

                        keyboardType: TextInputType.number,

                        autofillHints: const [
                          AutofillHints.creditCardSecurityCode,
                        ],

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
                        'Secured by PayMongo',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Test Cards Guide
                Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),

                          const SizedBox(width: 8),

                          Text(
                            'Test Credentials',

                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.blue,

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      const Text('Use these cards for testing:'),

                      const SizedBox(height: 8),

                      _buildCopyableRow(
                        'Visa',
                        '4343 4343 4343 4345',
                        onAutoFill: () =>
                            _autoFillTestCard('4343 4343 4343 4345'),
                      ),

                      const SizedBox(height: 4),

                      _buildCopyableRow(
                        'Mastercard',
                        '5555 4444 4444 4457',
                        onAutoFill: () =>
                            _autoFillTestCard('5555 4444 4444 4457'),
                      ),

                      const SizedBox(height: 8),

                      const Text('Any future expiry date (e.g., 12/30)'),

                      const Text('Any 3-digit CVC (e.g., 123)'),

                      if (kDebugMode) ...[
                        const Divider(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _useMockService,
                            icon: const Icon(Icons.science_outlined),
                            label: const Text('Bypass API (Use Mock Service)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.purple,
                              side: const BorderSide(color: Colors.purple),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCopyableRow(
    String label,
    String value, {
    VoidCallback? onAutoFill,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),

      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));

                (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
                  SnackBar(
                    content: Text('$label card copied'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 80,

                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      value,

                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const Icon(Icons.copy, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (onAutoFill != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAutoFill,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
              ),
              child: const Text('Fill', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
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
