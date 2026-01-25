import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';

class CardPaymentForm extends StatefulWidget {
  final double amount;
  final VoidCallback onCancel;
  final Function(String cardNumber, String expiry, String cvv, String name) onSubmit;
  final bool isProcessing;

  const CardPaymentForm({
    super.key,
    required this.amount,
    required this.onCancel,
    required this.onSubmit,
    this.isProcessing = false,
  });

  @override
  State<CardPaymentForm> createState() => _CardPaymentFormState();
}

class _CardPaymentFormState extends State<CardPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _cardController.text.replaceAll(' ', ''),
        _expiryController.text,
        _cvvController.text,
        _nameController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, isDark),
              const SizedBox(height: 24),
              _buildAmountDisplay(theme, isDark),
              const SizedBox(height: 24),
              _buildCardNumberField(theme, isDark),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildExpiryField(theme, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCvvField(theme, isDark)),
                ],
              ),
              const SizedBox(height: 16),
              _buildNameField(theme, isDark),
              const SizedBox(height: 24),
              _buildButtons(theme),
              const SizedBox(height: 16),
              _buildSecurityNote(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ColorConstants.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.credit_card, color: ColorConstants.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pay with Card',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Visa, Mastercard accepted',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        IconButton(onPressed: widget.onCancel, icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildAmountDisplay(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.backgroundSecondaryDark
            : ColorConstants.backgroundSecondaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Amount to Pay',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₱${widget.amount.toStringAsFixed(2)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: ColorConstants.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardNumberField(ThemeData theme, bool isDark) {
    return TextFormField(
      controller: _cardController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(16),
        _CardNumberFormatter(),
      ],
      decoration: InputDecoration(
        labelText: 'Card Number',
        hintText: '4242 4242 4242 4242',
        prefixIcon: const Icon(Icons.credit_card),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark
            ? ColorConstants.backgroundSecondaryDark
            : ColorConstants.backgroundSecondaryLight,
      ),
      validator: (value) {
        final cleaned = value?.replaceAll(' ', '') ?? '';
        if (cleaned.isEmpty) return 'Please enter card number';
        if (cleaned.length < 15) return 'Invalid card number';
        return null;
      },
    );
  }

  Widget _buildExpiryField(ThemeData theme, bool isDark) {
    return TextFormField(
      controller: _expiryController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
        _ExpiryFormatter(),
      ],
      decoration: InputDecoration(
        labelText: 'Expiry',
        hintText: 'MM/YY',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark
            ? ColorConstants.backgroundSecondaryDark
            : ColorConstants.backgroundSecondaryLight,
      ),
      validator: (value) {
        if (value == null || value.length < 5) return 'Invalid';
        return null;
      },
    );
  }

  Widget _buildCvvField(ThemeData theme, bool isDark) {
    return TextFormField(
      controller: _cvvController,
      keyboardType: TextInputType.number,
      obscureText: true,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(
        labelText: 'CVV',
        hintText: '123',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark
            ? ColorConstants.backgroundSecondaryDark
            : ColorConstants.backgroundSecondaryLight,
      ),
      validator: (value) {
        if (value == null || value.length < 3) return 'Invalid';
        return null;
      },
    );
  }

  Widget _buildNameField(ThemeData theme, bool isDark) {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Cardholder Name',
        hintText: 'JUAN DELA CRUZ',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark
            ? ColorConstants.backgroundSecondaryDark
            : ColorConstants.backgroundSecondaryLight,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter name';
        return null;
      },
    );
  }

  Widget _buildButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.isProcessing ? null : widget.onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: widget.isProcessing ? null : _handleSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: widget.isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Pay Now'),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNote(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 14, color: ColorConstants.textSecondaryLight),
        const SizedBox(width: 6),
        Text(
          'Your card info is encrypted and secure',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

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
      if ((i + 1) % 4 == 0 && i != text.length - 1) buffer.write(' ');
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    if (text.length >= 2) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    }
    return newValue;
  }
}
