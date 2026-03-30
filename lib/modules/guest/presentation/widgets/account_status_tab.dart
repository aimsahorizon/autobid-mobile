import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../controllers/guest_controller.dart';
import '../widgets/account_status_card.dart';

class AccountStatusTab extends StatefulWidget {
  final GuestController controller;

  const AccountStatusTab({super.key, required this.controller});

  @override
  State<AccountStatusTab> createState() => _AccountStatusTabState();
}

class _AccountStatusTabState extends State<AccountStatusTab> {
  final _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _handleCheckStatus() {
    if (_formKey.currentState!.validate()) {
      widget.controller.checkAccountStatus(_identifierController.text.trim());
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
          'Enter your email or username to check your KYC status',
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
            controller: _identifierController,
            decoration: InputDecoration(
              labelText: 'Email or Username',
              hintText: 'Enter registered email or username',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email or username';
              }
              if (value.length < 3) {
                return 'Identifier too short';
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

    // Show error message if there was a failure
    if (widget.controller.errorMessage != null &&
        widget.controller.statusEmail != null) {
      return _buildErrorMessage(theme, isDark, widget.controller.errorMessage!);
    }

    if (widget.controller.accountStatus == null) {
      return _buildNoStatusMessage(theme, isDark);
    }

    return AccountStatusCard(
      status: widget.controller.accountStatus!,
      onAppeal: () => _showAppealDialog(context),
    );
  }

  void _showAppealDialog(BuildContext context) {
    final appealController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: ColorConstants.warning),
            SizedBox(width: 12),
            Expanded(
              child: Text('Submit Appeal', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explain why your KYC rejection should be reconsidered. Your existing documents will be re-reviewed.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: appealController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Describe your reason for appeal...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason for your appeal';
                  }
                  if (value.trim().length < 20) {
                    return 'Please provide more detail (at least 20 characters)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              return FilledButton(
                onPressed: widget.controller.isSubmittingAppeal
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        await widget.controller.submitAppeal(
                          appealController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          if (widget.controller.appealSubmitted) {
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Appeal submitted successfully',
                                  ),
                                  backgroundColor: ColorConstants.success,
                                ),
                              );
                          }
                        }
                      },
                child: widget.controller.isSubmittingAppeal
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Appeal'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme, bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: ColorConstants.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Something went wrong. Please try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ColorConstants.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoStatusMessage(ThemeData theme, bool isDark) {
    if (_identifierController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: ColorConstants.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No account found with this identifier. Please register first.',
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
