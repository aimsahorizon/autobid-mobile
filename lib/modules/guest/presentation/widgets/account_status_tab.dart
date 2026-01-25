import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../controllers/guest_controller.dart';
import '../widgets/account_status_card.dart';

class AccountStatusTab extends StatefulWidget {
  final GuestController controller;

  const AccountStatusTab({
    super.key,
    required this.controller,
  });

  @override
  State<AccountStatusTab> createState() => _AccountStatusTabState();
}

class _AccountStatusTabState extends State<AccountStatusTab> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleCheckStatus() {
    if (_formKey.currentState!.validate()) {
      widget.controller.checkAccountStatus(_emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme, isDark),
              const SizedBox(height: 24),
              _buildSearchForm(theme, isDark),
              const SizedBox(height: 24),
              _buildStatusResult(theme, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check Account Status',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email to check your KYC verification status',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchForm(ThemeData theme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your registered email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.controller.isLoadingStatus
                  ? null
                  : _handleCheckStatus,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.controller.isLoadingStatus
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Check Status'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusResult(ThemeData theme, bool isDark) {
    if (widget.controller.isLoadingStatus) {
      return const SizedBox.shrink();
    }

    if (widget.controller.accountStatus == null) {
      return _buildNoStatusMessage(theme, isDark);
    }

    return AccountStatusCard(status: widget.controller.accountStatus!);
  }

  Widget _buildNoStatusMessage(ThemeData theme, bool isDark) {
    if (_emailController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: ColorConstants.info,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No account found with this email. Please register first.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ColorConstants.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
